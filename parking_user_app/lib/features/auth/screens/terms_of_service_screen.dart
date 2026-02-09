import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle('Terms of Service for Jambo Park'),
            const SizedBox(height: 8),
            _buildSubtext('Effective Date: February 9, 2026'),
            _buildSubtext('Last Updated: February 9, 2026'),
            const SizedBox(height: 24),

            _buildSection(
              '1. Acceptance of Terms',
              'By creating an account or using Jambo Park, you agree to be bound by these Terms of Service. If you do not agree, you may not use our Service.',
            ),

            _buildSection(
              '2. Eligibility',
              '• You must be at least 18 years old\n'
                  '• You must have legal capacity to enter contracts\n'
                  '• You agree to provide accurate information',
            ),

            _buildSection(
              '3. Account Security',
              '• You are responsible for maintaining account confidentiality\n'
                  '• Single device login for security\n'
                  '• Notify us immediately of unauthorized use\n'
                  '• We may suspend accounts for violations',
            ),

            _buildSection(
              '4. Parking Services',
              'Jambo Park provides:\n\n'
                  '• Real-time parking zone availability\n'
                  '• Mobile parking session management\n'
                  '• Digital payment processing\n'
                  '• Parking reservations and violation notifications\n\n'
                  'We do not guarantee uninterrupted service and may modify features at any time.',
            ),

            _buildSection(
              '5. Payment Terms',
              '• Parking rates vary by zone and are displayed in the app\n'
                  '• We accept wallet balance and mobile money\n'
                  '• Wallet top-ups are non-refundable except as required by law\n'
                  '• You authorize us to charge applicable fees\n'
                  '• Refunds issued only for service errors or duplicate charges',
            ),

            _buildSection(
              '6. Parking Sessions',
              '• Payment must be completed before starting\n'
                  '• You must park only in designated slots\n'
                  '• You must end sessions through the app\n'
                  '• Overstay may result in additional charges',
            ),

            _buildSection(
              '7. Violations and Penalties',
              'Violations include:\n\n'
                  '• Parking in unauthorized zones\n'
                  '• Exceeding paid time without payment\n'
                  '• Providing false information\n'
                  '• Blocking other vehicles\n\n'
                  'Penalties may include fines and account suspension.',
            ),

            _buildSection(
              '8. User Conduct',
              'You agree NOT to:\n\n'
                  '• Use the Service for illegal purposes\n'
                  '• Violate any laws or regulations\n'
                  '• Infringe on intellectual property\n'
                  '• Interfere with or disrupt the Service\n'
                  '• Harass or harm others',
            ),

            _buildSection(
              '9. Disclaimers',
              'THE SERVICE IS PROVIDED "AS IS" WITHOUT WARRANTIES. We do not guarantee parking availability or accuracy of real-time data.',
            ),

            _buildSection(
              '10. Limitation of Liability',
              'We are not liable for:\n\n'
                  '• Indirect or consequential damages\n'
                  '• Vehicle damage, theft, or loss while parked\n'
                  '• Third-party service failures\n\n'
                  'Our total liability shall not exceed amounts you paid in the past 12 months.',
            ),

            _buildSection(
              '11. Governing Law',
              'These Terms are governed by the laws of Uganda. Disputes shall be resolved through arbitration.',
            ),

            _buildSection(
              '12. Contact Information',
              'For questions about these Terms:\n\n'
                  'Email: support@jambopark.com\n'
                  'Phone: +256 XXX XXX XXX',
            ),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'BY USING JAMBO PARK, YOU ACKNOWLEDGE THAT YOU HAVE READ, UNDERSTOOD, AND AGREE TO BE BOUND BY THESE TERMS OF SERVICE.',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Compliant with Google Play Store and Apple App Store requirements.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
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
