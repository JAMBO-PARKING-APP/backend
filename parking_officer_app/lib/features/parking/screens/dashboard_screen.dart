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

import 'package:parking_officer_app/core/location_service.dart';

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

      // Start Location Tracking
      LocationService().startTracking();
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Zone Monitor',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 80, left: 20, right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Daily Scans',
                        context.watch<OfficerProvider>().dailyScans,
                        Icons.qr_code_scanner,
                      ),
                      _buildStatItem(
                        'Violations',
                        context.watch<OfficerProvider>().dailyViolations,
                        Icons.gavel_rounded,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              Consumer<OfficerProvider>(
                builder: (context, provider, _) => Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: ActionChip(
                    avatar: CircleAvatar(
                      radius: 6,
                      backgroundColor: provider.isOnline
                          ? Colors.greenAccent
                          : Colors.white24,
                    ),
                    label: Text(
                      provider.isOnline ? 'ONLINE' : 'OFFLINE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    backgroundColor: Colors.white24,
                    onPressed: () => _showStatusDialog(context, provider),
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Zones',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  TextButton.icon(
                    onPressed: () => context.read<ZoneProvider>().fetchZones(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            ),
          ),
          Consumer<ZoneProvider>(
            builder: (context, zoneProvider, _) {
              if (zoneProvider.isLoading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (zoneProvider.zones.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text('No active zones found.'),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
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
                  }, childCount: zoneProvider.zones.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
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
    final occupancy = zone.totalSlots > 0
        ? zone.occupiedSlots / zone.totalSlots
        : 0.0;
    final color = occupancy > 0.9
        ? AppTheme.errorColor
        : (occupancy > 0.7 ? AppTheme.warningColor : AppTheme.primaryColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zone.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF262626),
                          ),
                        ),
                        Text(
                          'Zone Code: ${zone.code}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(occupancy * 100).toInt()}% Full',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniStat('Occupied', '${zone.occupiedSlots}', color),
                  _buildMiniStat(
                    'Available',
                    '${zone.availableSlots}',
                    Colors.green[600]!,
                  ),
                  _buildMiniStat(
                    'Total',
                    '${zone.totalSlots}',
                    Colors.grey[600]!,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: occupancy,
                  minHeight: 8,
                  backgroundColor: Colors.grey[100],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
