import 'package:flutter/material.dart';
import 'package:parking_officer_app/core/app_theme.dart';
import 'package:parking_officer_app/features/parking/screens/scanner_screen.dart';
import 'package:parking_officer_app/features/parking/screens/license_plate_search_screen.dart';

import 'package:parking_officer_app/features/violations/screens/violation_wizard_screen.dart';

class VerificationHubScreen extends StatefulWidget {
  const VerificationHubScreen({super.key});

  @override
  State<VerificationHubScreen> createState() => _VerificationHubScreenState();
}

class _VerificationHubScreenState extends State<VerificationHubScreen> {
  final TextEditingController _plateController = TextEditingController();

  void _startViolationWizard(String plate) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViolationWizardScreen(licensePlate: plate),
      ),
    );
  }

  void _showPlateSearchDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LicensePlateSearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VERIFICATION HUB',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  color: AppTheme.primaryColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Verify vehicles and enforce parking policies.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),

              // Action Cards Row
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      'SCAN QR',
                      Icons.qr_code_scanner_rounded,
                      AppTheme.primaryColor,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ScannerScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionCard(
                      'PLATE SEARCH',
                      Icons.search_rounded,
                      AppTheme.accentColor,
                      () => _showPlateSearchDialog(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              const Text(
                'QUICK ENFORCEMENT',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              _buildPlateInputCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlateInputCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _plateController,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
            decoration: InputDecoration(
              hintText: 'ENTER PLATE',
              hintStyle: TextStyle(color: Colors.grey[300], letterSpacing: 2.0),
              prefixIcon: const Icon(Icons.directions_car_rounded),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                if (_plateController.text.isNotEmpty) {
                  _startViolationWizard(_plateController.text);
                }
              },
              child: const Text('DETECT & VERIFY'),
            ),
          ),
        ],
      ),
    );
  }
}
