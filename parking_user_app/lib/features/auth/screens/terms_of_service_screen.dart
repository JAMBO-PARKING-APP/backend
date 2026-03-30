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
            _buildTitle('Terms of Service for Space Park'),
            const SizedBox(height: 8),
            _buildSubtext('Effective Date: February 9, 2026'),
            _buildSubtext('Last Updated: February 9, 2026'),
            const SizedBox(height: 24),

            _buildSection(
              '1. Acceptance of Terms',
              'By creating an account, accessing, or using Space Park, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service. These terms constitute a legally binding agreement between you and Space Park Ltd. If you do not agree with any part of these terms, you must immediately cease all use of the Service.',
            ),

            _buildSection(
              '2. User Eligibility and Responsibilities',
              '• You must be at least 18 years of age and possess the legal authority to form a binding contract.\n'
              '• You are responsible for ensuring all information provided (vehicle details, phone number, etc.) is accurate and kept up to date.\n'
              '• You agree to comply with all local traffic and parking laws of Uganda.\n'
              '• You are solely responsible for any activity that occurs under your account.',
            ),

            _buildSection(
              '3. Account Security and Multi-Factor Auth',
              '• You must safeguard your login credentials and not share them with third parties.\n'
              '• We reserve the right to suspend or terminate accounts that show suspicious activity or violate our security protocols.\n'
              '• For enhanced security, certain transactions may require One-Time Passwords (OTP) sent to your registered mobile number.',
            ),

            _buildSection(
              '4. Parking Services and Limitations',
              'Space Park provides a digital platform for:\n\n'
              '• Locating parking zones and viewing real-time availability fees.\n'
              '• Digital payment processing and electronic receipting.\n'
              '• Managing active parking durations and extensions.\n'
              '• Reserving specific slots based on availability.\n\n'
              'Note: Availability data is dynamic and not a guarantee of a spot upon arrival. Space Park is not responsible for any modifications to parking zone accessibility by municipal authorities.',
            ),

            _buildSection(
              '5. Financial Terms and Wallet Usage',
              '• All rates are inclusive of applicable taxes unless stated otherwise.\n'
              '• Wallet balances are denominated in local currency and are strictly non-transferable.\n'
              '• You authorize Space Park to debit fees automatically upon session start or reservation confirmation.\n'
              '• For external payments (Mobile Money/Cards via Pesapal), processing fees may apply as determined by the payment gateway providers.\n'
              '• Refund requests for failed sessions must be submitted within 24 hours via the in-app support channel.',
            ),

            _buildSection(
              '6. Data Privacy and Processing',
              'We collect and process your personal data, including location information and vehicle registration, to provide the Services. Our use of your data is governed by our Privacy Policy, which is aligned with the Data Protection and Privacy Act of Uganda. By using the app, you consent to such processing.',
            ),

            _buildSection(
              '7. Violations, Fines, and Enforcement',
              'Breach of parking rules (e.g., overstaying, improper parking) may be recorded by on-ground officers using the Space Park Officer App. Violations may lead to:\n\n'
              '• Automatic fines deducted from your wallet.\n'
              '• Clamping or towing of the vehicle (handled by municipal authorities).\n'
              '• Permanent suspension of your Space Park account.',
            ),

            _buildSection(
              '8. Intellectual Property',
              'All content, including logos, UI designs, and underlying code, is the exclusive property of Space Park Ltd. Any unauthorized reproduction or reverse engineering is strictly prohibited.',
            ),

            _buildSection(
              '9. Dispute Resolution and Arbitration',
              'Any disputes arising from these Terms shall first be attempted to be resolved through good-faith mediation. If mediation fails, the dispute shall be settled by binding arbitration in Kampala, Uganda, in accordance with the Arbitration and Conciliation Act.',
            ),

            _buildSection(
              '10. Disclaimers and Indemnity',
              'SPACE PARK IS PROVIDED "AS IS" AND "AS AVAILABLE". TO THE MAXIMUM EXTENT PERMITTED BY LAW, SPACE PARK LTD DISCLAIMS ALL WARRANTIES. YOU AGREE TO INDEMNIFY AND HOLD HARMLESS SPACE PARK LTD FROM ANY CLAIMS ARISING FROM YOUR MISUSE OF THE SERVICE OR VIOLATION OF THIRD-PARTY RIGHTS.',
            ),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'BY USING SPACE PARK, YOU ACKNOWLEDGE THAT YOU HAVE READ, UNDERSTOOD, AND AGREE TO BE BOUND BY THESE TERMS OF SERVICE.',
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
