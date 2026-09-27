import 'package:flutter/material.dart';
import 'package:parking_user_app/core/settings_provider.dart';
import 'package:provider/provider.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key, this.allowBack = false});

  final bool allowBack;

  static const _languages = <String, String>{
    'en': 'English',
    'fr': 'Français',
    'de': 'Deutsch',
    'sw': 'Kiswahili',
    'es': 'Español',
    'ar': 'العربية',
  };

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: allowBack ? AppBar(title: const Text('Language')) : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Choose your language',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text('You can change this later from your profile.'),
            const SizedBox(height: 16),
            ..._languages.entries.map(
              (entry) => Card(
                child: RadioListTile<String>(
                  value: entry.key,
                  groupValue: settings.currentLocale.languageCode,
                  title: Text(entry.value),
                  onChanged: (code) async {
                    if (code == null) return;
                    await settings.setLanguage(Locale(code));
                    if (allowBack && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
