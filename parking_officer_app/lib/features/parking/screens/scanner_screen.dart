import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:parking_officer_app/features/violations/providers/enforcement_provider.dart';
import 'package:parking_officer_app/features/violations/screens/violation_form_screen.dart';
import 'package:parking_officer_app/features/parking/services/qr_verification_service.dart';
import 'package:parking_officer_app/features/anpr/services/anpr_service.dart';
import 'package:parking_officer_app/core/app_theme.dart';

enum ScanMode { qr, anpr }

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  ScanMode _scanMode = ScanMode.qr;
  bool _isScanned = false; // Prevents duplicate processing

  // ANPR Controllers
  CameraController? _cameraController;
  final AnprService _anprService = AnprService();
  bool _isProcessingAnpr = false;

  // QR Controller
  final MobileScannerController _qrController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _qrController.dispose();
    _cameraController?.dispose();
    _anprService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reinitialize cameras on resume if needed
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_scanMode == ScanMode.anpr) {
        _initializeAnprCamera();
      }
    }
  }

  Future<void> _initializeAnprCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // Use back camera
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _cameraController!.initialize();
      await _cameraController!.startImageStream(_processAnprImage);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error initializing ANPR camera: $e');
    }
  }

  Future<void> _stopAnprCamera() async {
    if (_cameraController != null &&
        _cameraController!.value.isStreamingImages) {
      await _cameraController!.stopImageStream();
    }
    await _cameraController?.dispose();
    _cameraController = null;
  }

  void _toggleMode(ScanMode mode) async {
    if (_scanMode == mode) return;

    if (mode == ScanMode.anpr) {
      await _qrController.stop();
      await _initializeAnprCamera();
    } else {
      await _stopAnprCamera();
      await _qrController.start();
    }

    setState(() {
      _scanMode = mode;
      _isScanned = false;
    });
  }

  // --- QR Logic ---
  void _onQrDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        _isScanned = true;
        _showResult(code, isAnpr: false);
      }
    }
  }

  // --- ANPR Logic ---
  void _processAnprImage(CameraImage image) async {
    if (_isScanned || _isProcessingAnpr) return;
    _isProcessingAnpr = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final p = await _anprService.processImage(inputImage);
      if (p != null && mounted) {
        _isScanned = true;
        _showResult(p, isAnpr: true);
      }
    } catch (e) {
      debugPrint('ANPR Processing error: $e');
    } finally {
      _isProcessingAnpr = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;

    // Adjust logic based on platform/rotation if needed
    // Simplified for now based on common params
    // Simplified rotation logic
    final rotation =
        InputImageRotationValue.fromRawValue(sensorOrientation) ??
        InputImageRotation.rotation0deg;

    final format =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;

    // Concat planes
    return InputImage.fromBytes(
      bytes: _concatenatePlanes(image.planes),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow, // Approximate for NV21
      ),
    );
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  // --- UI & Result Handlers ---

  void _showResult(String data, {required bool isAnpr}) {
    // Log the scan action
    context.read<EnforcementProvider>().logAction(
      isAnpr ? 'scan_anpr' : 'scan_qr',
      details: {'raw_data': data},
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isAnpr ? 'License Plate Detected' : 'QR Scan Result',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isAnpr
                      ? AppTheme.accentColor.withValues(alpha: 0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: isAnpr
                      ? Border.all(color: AppTheme.accentColor)
                      : null,
                ),
                child: Text(
                  data,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isAnpr ? AppTheme.primaryColor : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('RESCAN'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (isAnpr) {
                          _navigateToViolationForm(plate: data);
                        } else {
                          _processQrData(data);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                      ),
                      child: Text(isAnpr ? 'CHECK STATUS' : 'PROCESS QR'),
                    ),
                  ),
                ],
              ),
              if (!isAnpr) ...[
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _processQrDataForViolation(data);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                  ),
                  child: const Text('ISSUE VIOLATION'),
                ),
              ],
            ],
          ),
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() => _isScanned = false);
        // Resume camera?
      }
    });
  }

  void _navigateToViolationForm({required String plate, String? sessionId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ViolationFormScreen(vehiclePlate: plate, sessionId: sessionId),
      ),
    );
  }

  void _processQrData(String data) async {
    // Try to extract session ID
    String sessionId = '';
    try {
      final lines = data.split(RegExp(r'\r?\n'));
      final idLine = lines.firstWhere(
        (l) => l.toLowerCase().startsWith('id:'),
        orElse: () => '',
      );
      if (idLine.isNotEmpty) {
        sessionId = idLine.split(':').last.trim();
      }
    } catch (_) {}

    if (sessionId.isNotEmpty) {
      _showVerificationDialog(sessionId);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid QR: No Session ID found')),
        );
      }
    }
  }

  void _processQrDataForViolation(String data) {
    String plate = '';
    String sessionId = '';
    try {
      final lines = data.split(RegExp(r'\r?\n'));
      final vehicleLine = lines.firstWhere(
        (l) => l.toLowerCase().contains('vehicle:'),
        orElse: () => '',
      );
      if (vehicleLine.isNotEmpty) {
        plate = vehicleLine.split(':').last.trim();
      }
      final idLine = lines.firstWhere(
        (l) => l.toLowerCase().startsWith('id:'),
        orElse: () => '',
      );
      if (idLine.isNotEmpty) {
        sessionId = idLine.split(':').last.trim();
      }
    } catch (_) {}

    _navigateToViolationForm(
      plate: plate,
      sessionId: sessionId.isNotEmpty ? sessionId : null,
    );
  }

  void _showVerificationDialog(String sessionId) async {
    // ... Existing verification logic (simplified reuse) ...
    // Reuse existing functionality but wrapped:
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final qrService = QRVerificationService();
    final result = await qrService.verifyQRCode(sessionId);

    if (!mounted) return;
    Navigator.pop(context);

    final isValid = result['valid'] == true;
    final message = result['message']?.toString() ?? 'Unknown status';
    final session = result['session'] as Map<String, dynamic>?;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isValid ? Icons.check_circle : Icons.error,
              color: isValid ? Colors.green : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isValid ? 'Valid Session' : 'Invalid Session',
                style: TextStyle(color: isValid ? Colors.green : Colors.red),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (session != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildSessionDetail(
                'Vehicle',
                session['vehicle_plate']?.toString() ?? 'N/A',
              ),
              _buildSessionDetail(
                'Driver',
                session['driver_name']?.toString() ?? 'N/A',
              ),
              _buildSessionDetail(
                'Zone',
                session['zone_name']?.toString() ?? 'N/A',
              ),
              _buildSessionDetail(
                'Status',
                session['status']?.toString() ?? 'N/A',
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Vehicle'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildModeButton(ScanMode.qr, 'Scan QR'),
                const SizedBox(width: 16),
                _buildModeButton(ScanMode.anpr, 'Scan Plate (ANPR)'),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          if (_scanMode == ScanMode.qr)
            MobileScanner(onDetect: _onQrDetect, controller: _qrController),

          if (_scanMode == ScanMode.anpr)
            if (_cameraController != null &&
                _cameraController!.value.isInitialized)
              CameraPreview(_cameraController!)
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

          Center(
            child: Container(
              width: 300,
              height: 300, // widened to square
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.accentColor, width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              _scanMode == ScanMode.qr
                  ? 'Align QR Code in frame'
                  : 'Align Number Plate in frame',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                backgroundColor: Colors.black45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(ScanMode mode, String label) {
    final isActive = _scanMode == mode;
    return GestureDetector(
      onTap: () => _toggleMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppTheme.primaryColor : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
