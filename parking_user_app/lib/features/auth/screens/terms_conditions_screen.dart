import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Space Park Terms of Service',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Last Updated: March 2026',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            SizedBox(height: 24),
            Text(
              '1. Acceptance of Terms',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'By accessing or using the Space Park application, you agree to be bound by these Terms of Service. If you do not agree to all of these terms, do not use our services.',
            ),
            SizedBox(height: 16),
            Text(
              '2. User Responsibilities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '• You must provide accurate vehicle identification and contact information.\n'
              '• You are responsible for ensuring your vehicle is parked within the designated slot boundaries.\n'
              '• You must adhere to all local traffic and parking regulations.',
            ),
            SizedBox(height: 16),
            Text(
              '3. Reservation & Payments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '• Reservations require pre-payment via Wallet or integrated payment providers (e.g., Pesapal).\n'
              '• "Pending Payment" states are not supported; reservations are only confirmed upon successful transaction.\n'
              '• Wallet balances are non-refundable but can be used for future parking sessions.',
            ),
            SizedBox(height: 16),
            Text(
              '4. Liability & Disclaimers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '• Space Park provides a platform to facilitate parking and is not responsible for the physical security of the parking zones.\n'
              '• We are not liable for any theft, damage, or loss of property occurring while using the service.\n'
              '• Users acknowledge that parking is at their own risk.',
            ),
            SizedBox(height: 16),
            Text(
              '5. Account Termination',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'We reserve the right to suspend or terminate accounts that frequently violate parking rules or attempt fraudulent transactions.',
            ),
            SizedBox(height: 32),
            Center(
              child: Text(
                'Thank you for trusting Space Park for your parking needs.',
                textAlign: TextAlign.center,
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
