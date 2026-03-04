import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms & Conditions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Welcome to Space. By using our application, you agree to comply with and be bound by the following terms and conditions.',
            ),
            SizedBox(height: 16),
            Text(
              '1. Use of Service',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'You agree to use the app only for lawful purposes related to parking management.',
            ),
            SizedBox(height: 16),
            Text(
              '2. Payments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Users are responsible for ensuring sufficient wallet balance for parking sessions.',
            ),
            SizedBox(height: 16),
            Text(
              '3. Liability',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Space is not liable for any damages to vehicles or loss of property in parking zones.',
            ),
            SizedBox(height: 24),
            Text('Thank you for choosing Space.'),
          ],
        ),
      ),
    );
  }
}
