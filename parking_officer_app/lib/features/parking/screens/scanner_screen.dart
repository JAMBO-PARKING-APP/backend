import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:parking_officer_app/features/violations/providers/enforcement_provider.dart';
import 'package:parking_officer_app/features/violations/screens/violation_form_screen.dart';
import 'package:parking_officer_app/features/parking/services/qr_verification_service.dart';
import 'package:parking_officer_app/core/app_theme.dart';

enum ScanMode { qr, manual }

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  ScanMode _scanMode = ScanMode.qr;
  bool _isProcessing = false;

  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _manualPlateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    _manualPlateController.dispose();
    super.dispose();
  }

  void _toggleMode(ScanMode mode) async {
    if (_scanMode == mode) return;

    if (mode == ScanMode.qr) {
      await _scannerController.start();
    } else {
      await _scannerController.stop();
    }

    setState(() {
      _scanMode = mode;
      _isProcessing = false;
      _manualPlateController.clear();
    });
  }

  void _onScan(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        _processQRData(code);
      }
    }
  }

  Future<void> _processQRData(String data) async {
    setState(() => _isProcessing = true);
    _showResult(data);
  }

  void _showResult(String data) {
    context.read<EnforcementProvider>().logAction(
      'scan_qr',
      details: {'raw_data': data},
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Scan Result',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  data,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('RESCAN'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _processQrDataForVerification(data);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('VERIFY'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _processQrDataForViolation(data);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('ISSUE VIOLATION'),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() => _isProcessing = false);
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

  void _processQrDataForVerification(String data) async {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isValid ? Icons.check_circle : Icons.error,
              color: isValid ? Colors.green : Colors.red,
              size: 28,
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
            Text(message, style: const TextStyle(fontSize: 16)),
            if (session != null) ...[
              const SizedBox(height: 20),
              _buildSessionDetail(
                'Vehicle',
                session['vehicle_plate']?.toString() ?? 'N/A',
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
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualEntry() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _manualPlateController,
            decoration: InputDecoration(
              labelText: 'Enter License Plate',
              hintText: 'e.g. UBK 123X',
              prefixIcon: const Icon(Icons.directions_car),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _submitManualPlate,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'CHECK STATUS',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _submitManualPlate() {
    final plate = _manualPlateController.text.trim();
    if (plate.isNotEmpty) {
      _navigateToViolationForm(plate: plate);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a license plate')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enforcement Scanner'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildModeTab('QR Scan', ScanMode.qr, Icons.qr_code_scanner),
                const SizedBox(width: 12),
                _buildModeTab('Manual', ScanMode.manual, Icons.edit),
              ],
            ),
          ),
        ),
      ),
      body: _scanMode == ScanMode.qr
          ? Stack(
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onScan,
                ),
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Stack(
                      children: [
                        _buildCorner(0, 0, 24, 0),
                        _buildCorner(null, 0, 0, 24),
                        _buildCorner(0, null, 24, 0),
                        _buildCorner(null, null, 0, 24),
                      ],
                    ),
                  ),
                ),
                const Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Text(
                    'Position QR code within the frame',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      shadows: [Shadow(blurRadius: 10)],
                    ),
                  ),
                ),
              ],
            )
          : _buildManualEntry(),
    );
  }

  Widget _buildCorner(double? top, double? left, double tr, double br) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: top != null
                ? const BorderSide(color: AppTheme.primaryColor, width: 4)
                : BorderSide.none,
            left: left != null
                ? const BorderSide(color: AppTheme.primaryColor, width: 4)
                : BorderSide.none,
            right: left == null
                ? const BorderSide(color: AppTheme.primaryColor, width: 4)
                : BorderSide.none,
            bottom: top == null
                ? const BorderSide(color: AppTheme.primaryColor, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildModeTab(String label, ScanMode mode, IconData icon) {
    final isActive = _scanMode == mode;
    return GestureDetector(
      onTap: () => _toggleMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
