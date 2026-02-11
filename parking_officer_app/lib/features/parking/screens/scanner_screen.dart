import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:parking_officer_app/features/violations/providers/enforcement_provider.dart';
import 'package:parking_officer_app/features/violations/screens/violation_form_screen.dart';
import 'package:parking_officer_app/core/app_theme.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isScanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      setState(() => _isScanned = true);
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        _showResult(code);
      }
    }
  }

  void _showResult(String data) {
    // Log the scan action
    context.read<EnforcementProvider>().logAction(
      'scan_qr',
      details: {'raw_data': data},
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
              const Text(
                'Scan Result',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  data,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('DISMISS'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        // Parse vehicle plate from QR payload (server uses 'Vehicle: {plate}')
                        String plate = '';
                        try {
                          final lines = data.split('\n');
                          final vehicleLine = lines.firstWhere(
                            (l) => l.toLowerCase().contains('vehicle:'),
                            orElse: () => '',
                          );
                          if (vehicleLine.isNotEmpty) {
                            plate = vehicleLine.split(':').last.trim();
                          }
                        } catch (_) {}

                        if (!mounted) return;
                        Navigator.pop(context);
                        if (plate.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ViolationFormScreen(vehiclePlate: plate),
                            ),
                          );
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Could not extract vehicle plate from QR',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                      ),
                      child: const Text('ISSUE VIOLATION'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        // Try to extract session ID (server encodes as 'ID: {id}')
                        String sessionId = '';
                        try {
                          final lines = data.split('\n');
                          final idLine = lines.firstWhere(
                            (l) => l.toLowerCase().startsWith('id:'),
                            orElse: () => '',
                          );
                          if (idLine.isNotEmpty) {
                            sessionId = idLine.split(':').last.trim();
                          }
                        } catch (_) {}

                        if (sessionId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Could not extract session ID from QR',
                              ),
                            ),
                          );
                          return;
                        }

                        // Call scan API via provider
                        final provider = context.read<dynamic>();
                        try {
                          final result = await provider.scanQRCode(
                            sessionId,
                            data,
                          );
                          if (context.mounted) {
                            if (result['success'] == true) {
                              final msg =
                                  result['message'] ?? 'Scan successful';
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(msg)));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result['message'] ?? 'Scan failed',
                                  ),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Scan error: ${e.toString()}'),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('VERIFY SESSION'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ).then((_) => setState(() => _isScanned = false));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Parking Pass')),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.accentColor, width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'Center the QR code in the frame',
              style: TextStyle(
                color: Colors.white,
                backgroundColor: Colors.black45,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
