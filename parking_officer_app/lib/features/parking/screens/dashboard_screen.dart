import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:parking_officer_app/features/parking/providers/zone_provider.dart';
import 'package:parking_officer_app/features/enforcement/providers/officer_provider.dart';
import 'package:parking_officer_app/core/app_theme.dart';
import 'package:parking_officer_app/features/parking/screens/zone_detail_screen.dart';
import 'package:parking_officer_app/features/enforcement/screens/activity_history_screen.dart';
import 'package:parking_officer_app/features/auth/screens/profile_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:parking_officer_app/features/parking/screens/verification_hub_screen.dart';
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
    final officer = context.watch<OfficerProvider>();
    
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          _buildBody(),
          
          // Floating Bottom Navigation Bar
          Positioned(
            left: 24,
            right: 24,
            bottom: 32, 
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: BottomNavigationBar(
                    currentIndex: _currentIndex,
                    onTap: (index) => setState(() => _currentIndex = index),
                    type: BottomNavigationBarType.fixed,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    selectedItemColor: AppTheme.primaryColor,
                    unselectedItemColor: AppTheme.textSecondary,
                    selectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    items: const [
                      BottomNavigationBarItem(
                        icon: Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Icon(Icons.radar_rounded),
                        ),
                        activeIcon: Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Icon(Icons.radar_rounded),
                        ),
                        label: 'Patrol',
                      ),
                      BottomNavigationBarItem(
                        icon: Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Icon(Icons.verified_user_outlined),
                        ),
                        activeIcon: Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Icon(Icons.verified_user_rounded),
                        ),
                        label: 'Verify',
                      ),
                      BottomNavigationBarItem(
                        icon: Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Icon(Icons.history_rounded),
                        ),
                        label: 'Activity',
                      ),
                      BottomNavigationBarItem(
                        icon: Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Icon(Icons.person_outline_rounded),
                        ),
                        activeIcon: Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Icon(Icons.person_rounded),
                        ),
                        label: 'Account',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Offline Status Overlay / Dialog
          if (!officer.isOnline && _currentIndex != 3) // Don't show on profile tab
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.power_settings_new_rounded,
                                color: AppTheme.primaryColor,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Shift Inactive',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                             const SizedBox(height: 12),
                             const Text(
                               'Go online to see enforcement zones and start your patrol shift.',
                               textAlign: TextAlign.center,
                               style: TextStyle(
                                 fontSize: 14,
                                 color: AppTheme.textSecondary,
                                 height: 1.5,
                               ),
                             ),
                             if (officer.errorMessage != null) ...[
                               const SizedBox(height: 16),
                               Container(
                                 padding: const EdgeInsets.all(12),
                                 decoration: BoxDecoration(
                                   color: Colors.red.withValues(alpha: 0.1),
                                   borderRadius: BorderRadius.circular(12),
                                   border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                 ),
                                 child: Text(
                                   officer.errorMessage!,
                                   textAlign: TextAlign.center,
                                   style: const TextStyle(
                                     color: Colors.red,
                                     fontSize: 12,
                                     fontWeight: FontWeight.w600,
                                   ),
                                 ),
                               ),
                             ],
                             const SizedBox(height: 32),
                             if (officer.isLoading)
                               const CircularProgressIndicator()
                             else
                               ElevatedButton(
                                 onPressed: () async {
                                   final pos = await LocationService().getCurrentPosition();
                                   if (pos != null) {
                                     officer.toggleOnlineStatus(
                                       true,
                                       latitude: pos.latitude,
                                       longitude: pos.longitude,
                                     );
                                   } else {
                                     officer.toggleOnlineStatus(true);
                                   }
                                 },
                                 style: ElevatedButton.styleFrom(
                                   backgroundColor: AppTheme.primaryColor,
                                   minimumSize: const Size(double.infinity, 56),
                                   shape: RoundedRectangleBorder(
                                     borderRadius: BorderRadius.circular(16),
                                   ),
                                 ),
                                 child: const Text(
                                   'GO ONLINE',
                                   style: TextStyle(
                                     fontWeight: FontWeight.bold,
                                     letterSpacing: 1,
                                   ),
                                 ),
                               ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildZoneMonitor();
      case 1:
        return const VerificationHubScreen();
      case 2:
        return const ActivityHistoryScreen();
      case 3:
        return const OfficerProfileScreen();
      default:
        return _buildZoneMonitor();
    }
  }

  Widget _buildZoneMonitor() {
    return Stack(
      children: [
        // Base Layer: Map
        _buildPatrolMap(),

        // Top Layer: Status & Duty Header
        Positioned(top: 0, left: 0, right: 0, child: _buildPatrolHeader()),

        // Bottom Layer: Zone Stats Overlay
        Positioned(
          bottom: 120, // Moved up to clear the new floating nav bar
          left: 20,
          right: 20,
          child: _buildZoneSummaryOverlay(),
        ),
      ],
    );
  }

  Widget _buildPatrolMap() {
    return Consumer<ZoneProvider>(
      builder: (context, zoneProvider, _) {
        final zones = zoneProvider.zones;
        final initialCenter = zones.isNotEmpty
            ? LatLng(zones.first.latitude, zones.first.longitude)
            : const LatLng(0.3476, 32.5825); // Kampala Default

        return FlutterMap(
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: 15.0,
            maxZoom: 18.0,
            minZoom: 12.0,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.smartparking.officer',
            ),
            MarkerLayer(
              markers: zones.map((zone) {
                return Marker(
                  point: LatLng(zone.latitude, zone.longitude),
                  width: 80,
                  height: 80,
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ZoneDetailScreen(zone: zone),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Text(
                            '${(zone.occupiedSlots / zone.totalSlots * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.location_on_rounded,
                          color: AppTheme.primaryColor,
                          size: 32,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPatrolHeader() {
    final officer = context.watch<OfficerProvider>();
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Space Patrol',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final pos = await LocationService().getCurrentPosition();
                  if (pos != null) {
                    officer.toggleOnlineStatus(
                      !officer.isOnline,
                      latitude: pos.latitude,
                      longitude: pos.longitude,
                    );
                  } else {
                    officer.toggleOnlineStatus(!officer.isOnline);
                  }
                },
                child: _buildDutyStatusChip(officer),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildDutyStatusChip(OfficerProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: provider.isOnline ? AppTheme.successColor : Colors.white24,
        borderRadius: BorderRadius.circular(30),
        boxShadow: provider.isOnline
            ? [
                BoxShadow(
                  color: AppTheme.successColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            provider.isOnline ? 'ON DUTY' : 'GO ONLINE',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneSummaryOverlay() {
    return Consumer<ZoneProvider>(
      builder: (context, zoneProvider, _) {
        if (zoneProvider.isLoading || zoneProvider.zones.isEmpty) {
          return const SizedBox.shrink();
        }

        final zone = zoneProvider.zones.first; 

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zone.name.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ZoneDetailScreen(zone: zone),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryDark,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('DETAILS'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildMiniStatBox(
                    'TOTAL',
                    '${zone.totalSlots}',
                    Colors.blueGrey,
                  ),
                  const SizedBox(width: 12),
                  _buildMiniStatBox(
                    'OCCUPIED',
                    '${zone.occupiedSlots}',
                    AppTheme.accentColor,
                  ),
                  const SizedBox(width: 12),
                  _buildMiniStatBox(
                    'OPEN',
                    '${zone.availableSlots}',
                    AppTheme.successColor,
                  ),
                ],
              ),
            ],
          ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniStatBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
