import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle('Privacy Policy for Jambo Park'),
            const SizedBox(height: 8),
            _buildSubtext('Effective Date: February 9, 2026'),
            _buildSubtext('Last Updated: February 9, 2026'),
            const SizedBox(height: 24),

            _buildSection(
              '1. Introduction',
              'We are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and services.',
            ),

            _buildSection(
              '2. Information We Collect',
              'We collect personal information including:\n\n'
                  '• Phone Number - for account creation and authentication\n'
                  '• Name - for account identification\n'
                  '• Email Address - optional, for account recovery\n'
                  '• Profile Photo - optional, for personalization\n'
                  '• Vehicle Information - license plate, make, model, color\n'
                  '• Location Data - real-time location for nearby parking zones\n'
                  '• Payment Information - wallet balance and transaction history\n'
                  '• Usage Data - parking sessions, app usage, device information',
            ),

            _buildSection(
              '3. How We Use Your Information',
              'We use collected information to:\n\n'
                  '• Create and manage your account\n'
                  '• Process parking sessions and payments\n'
                  '• Provide real-time parking availability\n'
                  '• Send booking confirmations and receipts\n'
                  '• Provide customer support\n'
                  '• Improve our services and develop new features\n'
                  '• Comply with legal obligations',
            ),

            _buildSection(
              '4. Data Sharing',
              'We do NOT sell your data. We may share information with:\n\n'
                  '• Service providers (payment processors, cloud hosting)\n'
                  '• Legal authorities when required by law\n'
                  '• Business partners in case of merger or acquisition\n\n'
                  'All service providers are contractually obligated to protect your data.',
            ),

            _buildSection(
              '5. Data Security',
              'We implement industry-standard security measures:\n\n'
                  '• Encryption using SSL/TLS\n'
                  '• Secure storage on protected servers\n'
                  '• Limited employee access\n'
                  '• Regular security audits',
            ),

            _buildSection(
              '6. Your Rights',
              'You have the right to:\n\n'
                  '• Access your personal information\n'
                  '• Correct inaccurate data\n'
                  '• Request deletion of your account\n'
                  '• Disable location services\n'
                  '• Opt out of promotional notifications\n'
                  '• Request data export',
            ),

            _buildSection(
              '7. Children\'s Privacy',
              'Our Service is not intended for children under 13. We do not knowingly collect information from children under 13.',
            ),

            _buildSection(
              '8. Contact Us',
              'For questions regarding this Privacy Policy:\n\n'
                  'Email: support@jambopark.com\n'
                  'Phone: +256 XXX XXX XXX',
            ),

            const SizedBox(height: 24),
            const Text(
              'By using Jambo Park, you consent to this Privacy Policy.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This Privacy Policy complies with GDPR, CCPA, Google Play Store, and Apple App Store requirements.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSubtext(String text) {
    return Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey));
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}
