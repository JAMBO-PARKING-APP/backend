import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parking_officer_app/features/parking/providers/zone_provider.dart';
import 'package:parking_officer_app/features/auth/providers/auth_provider.dart';
import 'package:parking_officer_app/core/app_theme.dart';
import 'package:parking_officer_app/features/parking/models/zone_model.dart';
import 'package:parking_officer_app/features/parking/screens/zone_detail_screen.dart';
import 'package:parking_officer_app/features/parking/screens/scanner_screen.dart';
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Zones'),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
        ],
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildZoneMonitor();
      case 1:
        return const ScannerScreen();
      case 2:
        return const ChatListScreen();
      default:
        return _buildZoneMonitor();
    }
  }

  Widget _buildZoneMonitor() {
    // final officer = context.watch<AuthProvider>().user; // Removed unused variable

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zone Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
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
