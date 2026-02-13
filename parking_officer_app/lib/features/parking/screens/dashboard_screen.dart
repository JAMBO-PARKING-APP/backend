import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parking_officer_app/features/parking/providers/zone_provider.dart';
import 'package:parking_officer_app/features/enforcement/providers/officer_provider.dart';
import 'package:parking_officer_app/features/auth/providers/auth_provider.dart';
import 'package:parking_officer_app/core/app_theme.dart';
import 'package:parking_officer_app/features/parking/models/zone_model.dart';
import 'package:parking_officer_app/features/parking/screens/zone_detail_screen.dart';
import 'package:parking_officer_app/features/parking/screens/scanner_screen.dart';
import 'package:parking_officer_app/features/enforcement/screens/activity_history_screen.dart';
import 'package:parking_officer_app/features/parking/screens/license_plate_search_screen.dart';
import 'package:parking_officer_app/features/auth/screens/profile_screen.dart';
import 'package:parking_officer_app/features/chat/screens/chat_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ZoneProvider>().fetchZones();
      context.read<OfficerProvider>().fetchOfficerStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 800;
        if (useRail) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) =>
                      setState(() => _currentIndex = index),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: AppTheme.cardColor,
                  useIndicator: true,
                  indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                  groupAlignment: -0.8,
                  leading: Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          width: 72,
                          height: 72,
                          errorBuilder: (c, e, s) => const SizedBox(),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Space Officer',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  selectedIconTheme: const IconThemeData(
                    size: 28,
                    color: AppTheme.primaryColor,
                  ),
                  unselectedIconTheme: const IconThemeData(
                    size: 22,
                    color: Colors.grey,
                  ),
                  selectedLabelTextStyle: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard),
                      label: Text('Zones'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.qr_code_scanner),
                      label: Text('Scan'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.search),
                      label: Text('Search'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.chat),
                      label: Text('Chat'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.history),
                      label: Text('History'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _buildBody()),
              ],
            ),
          );
        }

        // Mobile/tablet: use drawer
        return Scaffold(
          appBar: AppBar(title: const Text('Space Officer')),
          drawer: Drawer(
            child: SafeArea(
              child: Column(
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(color: AppTheme.primaryColor),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          width: 72,
                          height: 72,
                          errorBuilder: (c, e, s) => const SizedBox(),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Space Officer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.dashboard),
                    title: const Text('Zones'),
                    selected: _currentIndex == 0,
                    onTap: () => setState(() {
                      _currentIndex = 0;
                      Navigator.pop(context);
                    }),
                  ),
                  ListTile(
                    leading: const Icon(Icons.qr_code_scanner),
                    title: const Text('Scan'),
                    selected: _currentIndex == 1,
                    onTap: () => setState(() {
                      _currentIndex = 1;
                      Navigator.pop(context);
                    }),
                  ),
                  ListTile(
                    leading: const Icon(Icons.search),
                    title: const Text('Search'),
                    selected: _currentIndex == 2,
                    onTap: () => setState(() {
                      _currentIndex = 2;
                      Navigator.pop(context);
                    }),
                  ),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('History'),
                    selected: _currentIndex == 3,
                    onTap: () => setState(() {
                      _currentIndex = 3;
                      Navigator.pop(context);
                    }),
                  ),
                  ListTile(
                    leading: const Icon(Icons.chat),
                    title: const Text('Chat'),
                    selected: _currentIndex == 4,
                    onTap: () => setState(() {
                      _currentIndex = 4;
                      Navigator.pop(context);
                    }),
                  ),
                  const Spacer(),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Profile'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OfficerProfileScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    onTap: () {
                      Navigator.pop(context);
                      context.read<AuthProvider>().logout();
                    },
                  ),
                ],
              ),
            ),
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildZoneMonitor();
      case 1:
        return const ScannerScreen();
      case 2:
        return const LicensePlateSearchScreen();
      case 3:
        return const ActivityHistoryScreen();
      case 4:
        return const ChatListScreen();
      default:
        return _buildZoneMonitor();
    }
  }

  Widget _buildZoneMonitor() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zone Monitor'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryColor),
                ),
                child: Consumer<OfficerProvider>(
                  builder: (context, provider, _) => GestureDetector(
                    onTap: () => _showStatusDialog(context, provider),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 6,
                          backgroundColor: provider.isOnline
                              ? Colors.green
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          provider.isOnline ? 'Online' : 'Offline',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OfficerProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ZoneProvider>(
        builder: (context, zoneProvider, _) {
          if (zoneProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (zoneProvider.zones.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No active zones found.'),
                  TextButton(
                    onPressed: () => zoneProvider.fetchZones(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: zoneProvider.fetchZones,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: zoneProvider.zones.length,
              itemBuilder: (context, index) {
                final zone = zoneProvider.zones[index];
                return _ZoneCard(
                  zone: zone,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ZoneDetailScreen(zone: zone),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showStatusDialog(BuildContext context, OfficerProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Officer Status',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatusOption(
                  context,
                  'Go Online',
                  Icons.check_circle,
                  Colors.green,
                  !provider.isOnline,
                  () {
                    provider.toggleOnlineStatus(true);
                    Navigator.pop(context);
                  },
                ),
                _buildStatusOption(
                  context,
                  'Go Offline',
                  Icons.circle,
                  Colors.grey,
                  provider.isOnline,
                  () {
                    provider.toggleOnlineStatus(false);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    bool enabled,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 40),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  final Zone zone; // Changed type from dynamic to Zone
  final VoidCallback onTap; // Added onTap callback
  const _ZoneCard({
    required this.zone,
    required this.onTap,
  }); // Updated constructor

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          zone.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.numbers, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Code: ${zone.code}'),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: zone.totalSlots > 0
                  ? zone.occupiedSlots / zone.totalSlots
                  : 0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                zone.occupiedSlots / zone.totalSlots > 0.9
                    ? Colors.red
                    : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${zone.occupiedSlots} / ${zone.totalSlots} slots occupied',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap, // Used the onTap callback
      ),
    );
  }
}
