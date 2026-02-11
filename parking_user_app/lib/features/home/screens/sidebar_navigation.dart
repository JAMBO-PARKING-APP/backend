import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:parking_user_app/features/auth/providers/auth_provider.dart';

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
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade900
            : Colors.white,
        child: Column(
          children: [
            // Header with user profile
            Container(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.3),
                    backgroundImage: (auth.user?.profilePhoto != null)
                        ? CachedNetworkImageProvider(auth.user!.profilePhoto!)
                        : null,
                    child: (auth.user?.profilePhoto == null)
                        ? Text(
                            (auth.user?.firstName.isNotEmpty ?? false)
                                ? auth.user!.firstName
                                      .substring(0, 1)
                                      .toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${auth.user?.firstName ?? 'User'} ${auth.user?.lastName ?? ''}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    auth.user?.phone ?? 'No Phone',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            // Navigation items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _SidebarItem(
                    icon: Icons.home,
                    label: 'Home',
                    index: 0,
                    isSelected: currentIndex == 0,
                    onTap: () {
                      onTabChanged(0);
                      Navigator.pop(context);
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.map,
                    label: 'Zones',
                    index: 1,
                    isSelected: currentIndex == 1,
                    onTap: () {
                      onTabChanged(1);
                      Navigator.pop(context);
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.history,
                    label: 'History',
                    index: 2,
                    isSelected: currentIndex == 2,
                    onTap: () {
                      onTabChanged(2);
                      Navigator.pop(context);
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.wallet,
                    label: 'Wallet',
                    index: 5,
                    isSelected: currentIndex == 5,
                    onTap: () {
                      onTabChanged(5);
                      Navigator.pop(context);
                    },
                  ),
                  // FEATURED: Chat with badge
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          onTabChanged(3);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: currentIndex == 3
                                ? Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.2)
                                : Colors.transparent,
                            border: currentIndex == 3
                                ? Border.all(
                                    color: Theme.of(context).primaryColor,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.chat_bubble,
                                size: 24,
                                color: currentIndex == 3
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey.shade700,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Live Chat',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: currentIndex == 3
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: currentIndex == 3
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _SidebarItem(
                    icon: Icons.notifications,
                    label: 'Notifications',
                    index: 4,
                    isSelected: currentIndex == 4,
                    onTap: () {
                      onTabChanged(4);
                      Navigator.pop(context);
                    },
                  ),
                  _SidebarItem(
                    icon: Icons.person,
                    label: 'Profile',
                    index: 6,
                    isSelected: currentIndex == 6,
                    onTap: () {
                      onTabChanged(6);
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(height: 16),
                  _SidebarItem(
                    icon: Icons.settings,
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
            // Footer with logout
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showLogoutDialog(context, auth);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              auth.logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
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
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isSelected
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade700,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade700,
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
