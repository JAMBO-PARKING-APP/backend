import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:parking_user_app/features/auth/providers/auth_provider.dart';
import 'package:parking_user_app/core/app_theme.dart';

class SidebarNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChanged;

  const SidebarNavigation({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Drawer(
      width: 280,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            // Header with user profile - Modern Glassmorphism Design
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                child: Stack(
                  children: [
                    // Decorative Abstract Shapes for Glassmorphism Background
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 32),
                      child: SafeArea(
                        bottom: false,
                        top: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User Avatar with Badge
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                                    backgroundImage:
                                        (auth.user?.profilePhoto != null)
                                        ? CachedNetworkImageProvider(
                                            auth.user!.profilePhoto!,
                                          )
                                        : null,
                                    child: (auth.user?.profilePhoto == null)
                                        ? Text(
                                            (auth.user?.firstName.isNotEmpty ??
                                                    false)
                                                ? auth.user!.firstName
                                                      .substring(0, 1)
                                                      .toUpperCase()
                                                : 'U',
                                            style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                                  ),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // User Name
                            Text(
                              '${auth.user?.firstName ?? 'User'} ${auth.user?.lastName ?? ''}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // User Phone
                            Text(
                              auth.user?.phone ?? 'No Phone',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Navigation items - Modern Spacing
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  _SidebarItem(
                    icon: Icons.home_filled,
                    label: 'Home',
                    index: 0,
                    isSelected: currentIndex == 0,
                    onTap: () {
                      onTabChanged(0);
                      Navigator.pop(context);
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.map_outlined,
                    label: 'Zones',
                    index: 1,
                    isSelected: currentIndex == 1,
                    onTap: () {
                      onTabChanged(1);
                      Navigator.pop(context);
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.history_outlined,
                    label: 'History',
                    index: 2,
                    isSelected: currentIndex == 2,
                    onTap: () {
                      onTabChanged(2);
                      Navigator.pop(context);
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Wallet',
                    index: 5,
                    isSelected: currentIndex == 5,
                    onTap: () {
                      onTabChanged(5);
                      Navigator.pop(context);
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    index: 4,
                    isSelected: currentIndex == 4,
                    onTap: () {
                      onTabChanged(4);
                      Navigator.pop(context);
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    index: 6,
                    isSelected: currentIndex == 6,
                    onTap: () {
                      onTabChanged(6);
                      Navigator.pop(context);
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(height: 0, thickness: 0.5),
                  ),
                  _SidebarItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    index: 7,
                    isSelected: currentIndex == 7,
                    onTap: () {
                      onTabChanged(7);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

            // Footer with logout - Modern Design
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showLogoutDialog(context, auth);
                  },
                  icon: const Icon(Icons.logout_outlined, size: 20),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              auth.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.12)
                  : Colors.transparent,
              border: isSelected
                  ? Border.all(color: AppTheme.primaryColor, width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
