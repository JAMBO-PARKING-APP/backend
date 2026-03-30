import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:parking_user_app/features/auth/providers/auth_provider.dart';
import 'package:parking_user_app/features/auth/screens/vehicle_list_screen.dart';
import 'package:parking_user_app/features/payments/screens/wallet_screen.dart';
import 'package:parking_user_app/features/parking/screens/reservation_list_screen.dart';
import 'package:parking_user_app/features/notifications/screens/notification_screen.dart';
import 'package:parking_user_app/features/parking/screens/parking_history_screen.dart';
import 'package:parking_user_app/features/home/screens/about_screen.dart';
import 'package:parking_user_app/features/auth/screens/help_center_screen.dart';
import 'package:parking_user_app/features/partner/screens/partner_info_screen.dart';
import 'package:parking_user_app/core/app_theme.dart';
import 'package:parking_user_app/core/localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _requestPermissions() async {
    final l10n = AppLocalizations.of(context);
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    await [Permission.photos, Permission.camera].request();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.permissionsUpdated)));
    }
  }

  Future<void> _pickImage() async {
    final l10n = AppLocalizations.of(context);
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.uploadingPhoto)));
      final success = await context.read<AuthProvider>().updateProfilePhoto(
        image.path,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? l10n.photoUpdated : l10n.uploadFailed),
            backgroundColor: success
                ? AppTheme.successColor
                : AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Text(
          l10n.deleteAccountConfirmation,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: Text(l10n.deleteAccount),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await context.read<AuthProvider>().deleteAccount();
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToRequestDeletion),
          ),
        );
      }
    }
  }

  void _showDigitalPass(dynamic user) {
    if (user == null) return;
    final l10n = AppLocalizations.of(context);
    
    // Construct data string: Name, Phone, Vehicle
    final vehiclePlate = user.vehicles.isNotEmpty ? user.vehicles.first.licensePlate : 'No Vehicle';
    final qrData = 'Name: ${user.fullName}\nPhone: ${user.phone}\nVehicle: $vehiclePlate';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.yourDigitalPass,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.scanToVerify,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200.0,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppTheme.primaryColor,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildPassInfoRow(l10n.name, user.fullName),
            _buildPassInfoRow(l10n.phone, user.phone),
            _buildPassInfoRow(l10n.vehicleLabel, vehiclePlate),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                minimumSize: const Size(double.infinity, 56),
              ),
              child: Text(l10n.ok.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with Gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
              decoration: const BoxDecoration(
                color: AppTheme.primaryDark, // Stark, high-contrast flat header
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: user?.profilePhoto != null
                              ? NetworkImage(user!.profilePhoto!)
                              : null,
                          child: user?.profilePhoto == null
                              ? Text(
                                  user?.fullName
                                          .substring(0, 1)
                                          .toUpperCase() ??
                                      'U',
                                  style: const TextStyle(
                                    fontSize: 40,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.fullName ?? 'User Name',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    user?.phone ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Profile Options
            _ProfileOptionGroup(
              title: l10n.account.toUpperCase(),
              options: [
                _ProfileOption(
                  icon: Icons.qr_code_rounded,
                  title: l10n.viewVerificationQR,
                  onTap: () => _showDigitalPass(user),
                ),
                _ProfileOption(
                  icon: Icons.history,
                  title: l10n.parkingHistory,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ParkingHistoryScreen(),
                    ),
                  ),
                ),
                _ProfileOption(
                  icon: Icons.directions_car_outlined,
                  title: l10n.myVehicles,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VehicleListScreen(),
                    ),
                  ),
                ),
                _ProfileOption(
                  icon: Icons.account_balance_wallet_outlined,
                  title: '${l10n.wallet} & ${l10n.payments}',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WalletScreen(),
                    ),
                  ),
                ),
                _ProfileOption(
                  icon: Icons.calendar_today_outlined,
                  title: l10n.reservations,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReservationListScreen(),
                    ),
                  ),
                ),
              ],
            ),

            _ProfileOptionGroup(
              title: l10n.partnerProgram,
              options: [
                _ProfileOption(
                  icon: Icons.business_center_outlined,
                  title: l10n.bookSpot,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PartnerInfoScreen(),
                    ),
                  ),
                ),
              ],
            ),

            _ProfileOptionGroup(
              title: l10n.preferences.toUpperCase(),
              options: [
                _ProfileOption(
                  icon: Icons.notifications_none,
                  title: l10n.notifications,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen(),
                    ),
                  ),
                ),
                _ProfileOption(
                  icon: Icons.location_on_outlined,
                  title: l10n.about,
                  onTap: _requestPermissions,
                ),
              ],
            ),

            _ProfileOptionGroup(
              title: l10n.support.toUpperCase(),
              options: [
                _ProfileOption(
                  icon: Icons.help_outline,
                  title: l10n.helpCenter,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HelpCenterScreen(),
                    ),
                  ),
                ),
                _ProfileOption(
                  icon: Icons.info_outline,
                  title: l10n.about,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutScreen(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: () => context.read<AuthProvider>().logout(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor.withValues(alpha: 0.1),
                  foregroundColor: AppTheme.errorColor,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: Text(
                  l10n.logout.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),

            // Delete Account Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: OutlinedButton(
                onPressed: () => _confirmDeleteAccount(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(color: AppTheme.errorColor, width: 1.5),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: Text(
                  l10n.deleteAccount.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _ProfileOptionGroup extends StatelessWidget {
  final String title;
  final List<_ProfileOption> options;

  const _ProfileOptionGroup({required this.title, required this.options});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            children: [
              for (var i = 0; i < options.length; i++) ...[
                options[i],
                if (i < options.length - 1)
                  Divider(height: 1, indent: 60, color: Theme.of(context).dividerColor),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: 18,
        color: Colors.grey.shade300,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
