import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:parking_user_app/core/localizations.dart';
import 'package:parking_user_app/core/app_theme.dart';
import 'package:parking_user_app/features/auth/providers/auth_provider.dart';

import 'package:parking_user_app/features/settings/providers/settings_provider.dart';
import 'package:parking_user_app/widgets/base_scaffold.dart';
import 'package:parking_user_app/features/home/screens/home_screen.dart';
import 'package:parking_user_app/features/partner/screens/partner_info_screen.dart';
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BaseScaffold(
      title: l10n.settings,
      currentIndex: 7,
      onTabChanged: (index) {
        final homeState = context.findAncestorStateOfType<HomeScreenState>();
        if (homeState != null) homeState.navigateToTab(index);
      },
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) => SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B67C2), Color(0xFF0087F6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Personalize your experience',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Language Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.languagePreferences,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<String>(
                        segments: [
                          ButtonSegment(value: 'system', label: Text(l10n.system)),
                          ButtonSegment(value: 'en', label: Text(l10n.english)),
                          ButtonSegment(value: 'sw', label: Text(l10n.swahili)),
                          ButtonSegment(value: 'fr', label: Text(l10n.french)),
                          ButtonSegment(value: 'es', label: Text(l10n.spanish)),
                          ButtonSegment(value: 'ar', label: Text(l10n.arabic)),
                        ],
                        selected: {settings.locale},
                        onSelectionChanged: (Set<String> newSelection) {
                          settings.setLocale(newSelection.first);
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${l10n.current}: ${_getLanguageName(settings.locale, l10n)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
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
                      Text(
                        l10n.themeSettings,
                        style: const TextStyle(
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.aboutSpacePark,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          final version = snapshot.data?.version ?? '...';
                          final buildNumber = snapshot.data?.buildNumber ?? '...';
                          return Column(
                            children: [
                              _InfoRow(label: AppLocalizations.of(context).appVersion, value: version),
                              const SizedBox(height: 12),
                              _InfoRow(label: AppLocalizations.of(context).buildNumber, value: buildNumber),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: AppLocalizations.of(context).lastUpdated,
                        value: 'March 2026',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Partner Program
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.business_center, color: Theme.of(context).colorScheme.primary),
                      title: Text(l10n.hostParkingSpace, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(l10n.hostParkingSpaceSubtitle),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PartnerInfoScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Help & Support
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: Text(l10n.helpCenter),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        final uri = Uri.parse('https://p-space.ai/');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: Text(l10n.privacyPolicy),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        final uri = Uri.parse('https://p-space.ai/privacy');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(l10n.termsOfService),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        final uri = Uri.parse('https://p-space.ai/terms');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Danger Zone
              Card(
                elevation: 0,
                color: Colors.red.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red.shade100),
                ),
                child: ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text(
                    'Delete Account',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text('Temporarily deactivate and schedule for deletion'),
                  onTap: () => _showDeleteConfirmation(context),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'Your account will be deactivated immediately and permanently deleted in 30 days. You can cancel this by logging back in within 30 days.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              final authProvider = context.read<AuthProvider>();
              final success = await authProvider.deleteAccount();
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account deletion requested.')),
                );
                // AuthState listener will handle navigation to login
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to request deletion.')),
                );
              }
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code, AppLocalizations l10n) {
    switch (code) {
      case 'system':
        return l10n.system;
      case 'sw':
        return l10n.swahili;
      case 'fr':
        return l10n.french;
      case 'es':
        return l10n.spanish;
      case 'ar':
        return l10n.arabic;
      case 'de':
        return l10n.german;
      default:
        return l10n.english;
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
