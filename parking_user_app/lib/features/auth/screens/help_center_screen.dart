import 'package:flutter/material.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFaqItem(
            'How do I find a parking spot?',
            'You can find a parking spot by going to the Home tab and browsing the available zones on the map or list.',
          ),
          _buildFaqItem(
            'How do I pay for parking?',
            'We support various payment methods including MPESA and Credit Cards. You can manage your payment methods in the Wallet section.',
          ),
          _buildFaqItem(
            'Can I extend my parking session?',
            'Yes, you can extend your active parking session from the "Active Session" screen before it expires.',
          ),
          _buildFaqItem(
            'What happens if I overstay?',
            'If you overstay your parking duration, you may be issued a penalty or clamp. Ensure you extend your session if you need more time.',
          ),
          _buildFaqItem(
            'How do I contact support?',
            'You can reach our support team at support@jambopark.com or call our helpline.',
          ),
          _buildFaqItem(
            'How do I delete my account?',
            'You can delete your account from the Profile settings. Go to Profile > Delete Account.',
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: const TextStyle(height: 1.5, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
