import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.system_update_alt_rounded, size: 64),
              const SizedBox(height: 20),
              Text(
                'Update required',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              const Text(
                'This version is no longer supported or the service is temporarily under maintenance. Update the app or try again later.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  final store = Uri.parse(
                    'https://play.google.com/store/apps/details?id=com.jambo.parking_user_app',
                  );
                  if (!await launchUrl(
                    store,
                    mode: LaunchMode.externalApplication,
                  )) {
                    throw StateError('Unable to open the app store.');
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Get the latest version'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
