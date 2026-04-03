import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parking_officer_app/features/auth/providers/auth_provider.dart';
import 'package:parking_officer_app/features/enforcement/providers/officer_provider.dart';
import 'package:parking_officer_app/core/app_theme.dart';
import 'package:intl/intl.dart';

class OfficerProfileScreen extends StatefulWidget {
  const OfficerProfileScreen({super.key});

  @override
  State<OfficerProfileScreen> createState() => _OfficerProfileScreenState();
}

class _OfficerProfileScreenState extends State<OfficerProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OfficerProvider>().fetchOfficerStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer2<AuthProvider, OfficerProvider>(
        builder: (context, authProvider, officerProvider, _) {
          final user = authProvider.user;
          if (user == null) {
            return const Center(child: Text('NOT AUTHENTICATED'));
          }

          return CustomScrollView(
            slivers: [
              _buildSliverHeader(user),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('ADMINISTRATIVE STATUS'),
                      const SizedBox(height: 16),
                      _buildStatusConsole(officerProvider),
                      const SizedBox(height: 32),
                      _buildSectionLabel('ACCOUNT INFORMATION'),
                      const SizedBox(height: 16),
                      _buildInfoGrid(user),
                      const SizedBox(height: 48),
                      _buildLogoutButton(context),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverHeader(dynamic user) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            color: AppTheme.primaryDark,
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.security_rounded,
                  size: 200,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: user.profilePhoto != null
                            ? NetworkImage(user.profilePhoto!)
                            : null,
                        child: user.profilePhoto == null
                            ? Text(
                                user.firstName[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 40,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.fullName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      'OFFICER ID: ${user.phone.substring(user.phone.length - 4)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
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

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade400,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildStatusConsole(OfficerProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'OPERATIONAL STATUS',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: provider.isOnline
                      ? AppTheme.successColor.withValues(alpha: 0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  provider.isOnline ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    color: provider.isOnline
                        ? AppTheme.successColor
                        : Colors.grey,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          _buildConsoleRow(
            Icons.login_rounded,
            'DUTY START',
            provider.officerStatus?.wentOnlineAt != null
                ? _formatTimeFull(provider.officerStatus!.wentOnlineAt!)
                : 'N/A',
          ),
          const SizedBox(height: 16),
          _buildConsoleRow(
            Icons.logout_rounded,
            'DUTY END',
            provider.officerStatus?.wentOfflineAt != null
                ? _formatTimeFull(provider.officerStatus!.wentOfflineAt!)
                : 'N/A',
          ),
        ],
      ),
    );
  }
  Widget _buildConsoleRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ],
    );
  }


  Widget _buildInfoGrid(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildInfoItem('EMAIL ARCHIVE', user.email ?? 'UNSET'),
          const SizedBox(height: 16),
          _buildInfoItem('SYSTEM ROLE', user.role.toUpperCase()),
          const SizedBox(height: 16),
          _buildInfoItem('PHONE LINK', user.phone),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontWeight: FontWeight.w900,
            fontSize: 10,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutDialog(context),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text('TERMINATE SESSION'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.errorColor,
          side: const BorderSide(color: AppTheme.errorColor, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  String _formatTimeFull(DateTime time) {
    return DateFormat('MMM d, HH:mm').format(time);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('TERMINATE SESSION'),
        content: const Text(
          'Are you sure you want to log out of the enforcement console?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pop(context);
            },
            child: const Text(
              'LOGOUT',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
