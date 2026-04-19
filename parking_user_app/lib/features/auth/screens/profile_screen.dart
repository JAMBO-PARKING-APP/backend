import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:parking_user_app/core/app_theme.dart';
import 'package:parking_user_app/features/auth/providers/auth_provider.dart';
import 'package:parking_user_app/features/auth/providers/vehicle_provider.dart';
import 'package:parking_user_app/features/settings/screens/language_selection_screen.dart';
import 'package:parking_user_app/features/support/screens/support_screen.dart';
import 'package:parking_user_app/features/auth/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:parking_user_app/core/dialog_helper.dart';
import 'package:parking_user_app/features/parking/providers/country_provider.dart';
import 'package:parking_user_app/core/storage_manager.dart';
import 'package:parking_user_app/core/constants.dart';
import 'package:parking_user_app/features/parking/providers/parking_session_provider.dart';
import 'package:parking_user_app/features/parking/providers/reservation_provider.dart';
import 'package:parking_user_app/features/parking/providers/zone_provider.dart';
import 'package:parking_user_app/features/payments/providers/wallet_provider.dart';
import 'package:parking_user_app/features/notifications/providers/notification_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploadingProfilePic = false;
  String? _selectedCountryCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<AuthProvider>().refreshProfile();
      context.read<VehicleProvider>().fetchVehicles();
      context.read<CountryProvider>().loadCountries();
      final code = await StorageManager().getSelectedCountryCode();
      if (mounted && code != null) {
        setState(() => _selectedCountryCode = code);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final vehicles = context.watch<VehicleProvider>().vehicles;
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickAndUploadProfilePic,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppTheme.primaryColor,
                        backgroundImage: (user?.profilePhoto != null && user!.profilePhoto!.isNotEmpty)
                            ? NetworkImage(user.profilePhoto!)
                            : null,
                        child: (user?.profilePhoto == null || user!.profilePhoto!.isEmpty)
                            ? Text(
                                (user?.firstName.isNotEmpty == true ? user!.firstName[0] : 'U').toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryDark,
                            shape: BoxShape.circle,
                          ),
                          child: _isUploadingProfilePic
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.fullName ?? 'User', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(user?.phone ?? ''),
                      if ((user?.email ?? '').isNotEmpty) Text(user!.email!),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ProfileCard(
            title: 'Account details',
            child: Column(
              children: [
                _ProfileRow(label: 'Role', value: user?.role ?? 'driver'),
                const SizedBox(height: 12),
                Consumer<CountryProvider>(
                  builder: (context, prov, _) {
                    if (prov.countries.isEmpty) return const SizedBox.shrink();
                    final sortedCountries = prov.countries.where((c) => c.isActive).toList();
                    if (sortedCountries.isEmpty) return const SizedBox.shrink();
                    
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Active Country/Region'),
                      value: _selectedCountryCode,
                      items: sortedCountries.map((c) => DropdownMenuItem(
                        value: c.code,
                        child: Text('${c.flag} ${c.name}'),
                      )).toList(),
                      onChanged: (newCode) async {
                        if (newCode != null) {
                          setState(() => _selectedCountryCode = newCode);
                          await StorageManager().saveSelectedCountryCode(newCode);
                          if (!mounted) return;
                          
                          // Refresh all app state for new country context
                          context.read<ZoneProvider>().fetchZones();
                          context.read<ParkingSessionProvider>().fetchSessions();
                          context.read<ReservationProvider>().fetchReservations();
                          context.read<WalletProvider>().loadWallet();
                          context.read<NotificationProvider>().fetchAll();
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('App region updated securely.')),
                          );
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ProfileRow(label: 'Phone verified', value: user?.isPhoneVerified == true ? 'Yes' : 'No'),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LanguageSelectionScreen(allowBack: true),
                        ),
                      );
                    },
                    icon: const Icon(Icons.translate_rounded),
                    label: const Text('Change language'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ProfileCard(
            title: 'My vehicles',
            action: TextButton(
              onPressed: _openAddVehicleSheet,
              child: const Text('Add vehicle'),
            ),
            child: vehicles.isEmpty
                ? const Text('No vehicles added yet.')
                : Column(
                    children: vehicles
                        .map((vehicle) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(vehicle.licensePlate),
                              subtitle: Text('${vehicle.make} ${vehicle.model} - ${vehicle.color}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded),
                                onPressed: () => context.read<VehicleProvider>().deleteVehicle(vehicle.id),
                              ),
                            ))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 18),
          _ProfileCard(
            title: 'Account & Support',
            child: Column(
              children: [
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SupportScreen()),
                    );
                  },
                  icon: const Icon(Icons.support_agent_rounded),
                  label: const Text('Help & support'),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () => context.read<AuthProvider>().logout(),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _confirmDeleteAccount,
                  icon: const Icon(Icons.delete_forever_rounded, color: AppTheme.errorColor),
                  label: const Text('Delete Account', style: TextStyle(color: AppTheme.errorColor)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.errorColor)),
                ),
                const SizedBox(height: 24),
                Text('App Version: ${AppConstants.appVersion}', style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddVehicleSheet() async {
    final plate = TextEditingController();
    final make = TextEditingController();
    final model = TextEditingController();
    final color = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: plate, decoration: const InputDecoration(labelText: 'License plate')),
              const SizedBox(height: 12),
              TextField(controller: make, decoration: const InputDecoration(labelText: 'Make')),
              const SizedBox(height: 12),
              TextField(controller: model, decoration: const InputDecoration(labelText: 'Model')),
              const SizedBox(height: 12),
              TextField(controller: color, decoration: const InputDecoration(labelText: 'Color')),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final ok = await context.read<VehicleProvider>().createVehicle(
                        licensePlate: plate.text.trim(),
                        make: make.text.trim(),
                        model: model.text.trim(),
                        color: color.text.trim(),
                      );
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  if (ok) {
                    DialogHelper.showSuccess(context, 'Success', 'Vehicle added.');
                  } else {
                    DialogHelper.showError(context, 'Failed', 'Failed to add vehicle.');
                  }
                },
                child: const Text('Save vehicle'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to permanently delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      final result = await AuthService().deleteAccount();
      if (!mounted) return;
      if (result['success'] == true) {
        DialogHelper.showSuccess(context, 'Account Deleted', 'Your account has been deleted.');
      } else {
        DialogHelper.showError(context, 'Delete Failed', result['message'] ?? 'Failed to delete account.');
      }
    }
  }

  Future<void> _pickAndUploadProfilePic() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);
    
    if (pickedFile != null) {
      if (!mounted) return;
      setState(() => _isUploadingProfilePic = true);
      try {
        final authService = AuthService();
        final result = await authService.uploadProfilePicture(File(pickedFile.path));
        
        if (result['success'] == true) {
          if (mounted) {
            await context.read<AuthProvider>().checkAuth();
            DialogHelper.showSuccess(context, 'Success', 'Profile picture updated.');
          }
        } else {
          if (mounted) {
            DialogHelper.showError(context, 'Failed', result['message'] ?? 'Upload failed.');
          }
        }
      } catch (e) {
        if (mounted) {
          DialogHelper.showError(context, 'Error', 'Error uploading image.');
        }
      } finally {
        if (mounted) setState(() => _isUploadingProfilePic = false);
      }
    }
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.title,
    required this.child,
    this.action,
  });

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
