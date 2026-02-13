import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:parking_user_app/features/settings/providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Language Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Language Preferences',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'en', label: Text('English')),
                          ButtonSegment(value: 'sw', label: Text('Swahili')),
                          ButtonSegment(value: 'fr', label: Text('French')),
                          ButtonSegment(value: 'es', label: Text('Spanish')),
                        ],
                        selected: {settings.locale},
                        onSelectionChanged: (Set<String> newSelection) {
                          settings.setLocale(newSelection.first);
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Current: ${_getLanguageName(settings.locale)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Theme Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Theme Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ThemeOption(
                            icon: Icons.light_mode,
                            label: 'Light',
                            theme: ThemeMode.light,
                            isSelected: settings.themeMode == ThemeMode.light,
                            onTap: () => settings.setTheme(ThemeMode.light),
                          ),
                          _ThemeOption(
                            icon: Icons.dark_mode,
                            label: 'Dark',
                            theme: ThemeMode.dark,
                            isSelected: settings.themeMode == ThemeMode.dark,
                            onTap: () => settings.setTheme(ThemeMode.dark),
                          ),
                          _ThemeOption(
                            icon: Icons.brightness_auto,
                            label: 'System',
                            theme: ThemeMode.system,
                            isSelected: settings.themeMode == ThemeMode.system,
                            onTap: () => settings.setTheme(ThemeMode.system),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // App Information
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'About Space',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _InfoRow(label: 'App Version', value: '1.0.0'),
                      const SizedBox(height: 12),
                      _InfoRow(label: 'Build Number', value: '1'),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Last Updated',
                        value: 'February 10, 2026',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Help & Support
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('Help Center'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        final uri = Uri.parse('https://spacepark.com/help');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Privacy Policy'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        final uri = Uri.parse('https://spacepark.com/privacy');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Terms of Service'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        final uri = Uri.parse('https://spacepark.com/terms');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'sw':
        return 'Swahili (Kiswahili)';
      case 'fr':
        return 'French (Français)';
      case 'es':
        return 'Spanish (Español)';
      default:
        return 'English';
    }
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeMode theme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                  : null,
            ),
            child: Icon(
              icon,
              size: 28,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
