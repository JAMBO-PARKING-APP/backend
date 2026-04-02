import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:parking_user_app/features/parking/screens/parking_map_screen.dart';
import 'package:parking_user_app/features/parking/screens/zone_list_screen.dart';
import 'package:parking_user_app/features/payments/screens/wallet_screen.dart';
import 'package:parking_user_app/features/auth/screens/profile_screen.dart';
import 'package:parking_user_app/features/home/screens/dashboard_screen.dart';
import 'package:parking_user_app/core/app_theme.dart';
import 'package:parking_user_app/core/location_service.dart';
import 'package:parking_user_app/features/payments/providers/payment_provider.dart';
import 'package:parking_user_app/features/parking/providers/parking_provider.dart';
import 'package:parking_user_app/features/parking/providers/violation_provider.dart';
import 'package:parking_user_app/features/auth/providers/vehicle_provider.dart';
import 'package:parking_user_app/features/notifications/providers/notification_provider.dart';
import 'package:parking_user_app/features/parking/providers/reservation_provider.dart';
import 'package:parking_user_app/features/parking/providers/zone_provider.dart';
import 'package:parking_user_app/features/parking/screens/active_session_screen.dart'; // Added import for ActiveSessionScreen
// Removed GlassContainer import

// NEW: Import new location, profile, host providers
import 'package:parking_user_app/features/location/providers/location_provider.dart';
import 'package:parking_user_app/features/profile/providers/profile_provider.dart';
import 'package:parking_user_app/features/profile/screens/profile_screen.dart'
    as new_profile;
import 'package:parking_user_app/features/host_parking/providers/host_provider.dart';
import 'package:parking_user_app/features/host_parking/screens/host_parking_screen.dart';
import 'package:parking_user_app/features/reservations/providers/reservation_provider.dart'
    as reservations_provider;
import 'package:parking_user_app/features/reservations/screens/reservations_list_screen.dart';
import 'package:parking_user_app/features/auth/providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().fetchWalletData();
      context.read<ParkingProvider>().fetchSessions();
      context
          .read<ZoneProvider>()
          .fetchZones(); // Use ZoneProvider as source of truth
      context.read<ViolationProvider>().fetchViolations();
      context.read<VehicleProvider>().fetchVehicles();
      context.read<NotificationProvider>().fetchNotifications();
      context.read<ReservationProvider>().fetchReservations();
      context.read<ParkingProvider>().initNotifications();

      // Start Location Tracking
      LocationService().startTracking();

      // NEW: Initialize location provider
      final locationProvider = context.read<LocationProvider>();
      locationProvider.initialize();
      locationProvider.startTracking();
      locationProvider.detectCountry();

      // NEW: Load profile data
      context.read<ProfileProvider>().fetchProfile(refresh: true);
      context.read<ProfileProvider>().fetchNotifications(refresh: true);

      // NEW: Load reservations
      context
          .read<reservations_provider.ReservationProvider>()
          .fetchReservations(refresh: true);

      // NEW: Load host dashboard (if user is host)
      context.read<HostProvider>().fetchDashboard(refresh: true);

      // Auto-navigation to active session on startup
      _checkForActiveSession();
    });
  }

  Future<void> _checkForActiveSession() async {
    // Redirection is now handled by the dynamic Home tab in build()
    // and setting _currentIndex in initState or provider listeners if needed.
  }

  // No longer using global scaffold key here as sub-pages manage their own scaffolds

  @override
  Widget build(BuildContext context) {
    return Consumer<ParkingProvider>(
      builder: (context, parkingProvider, child) {
        // Detect NEW session start and switch tab to Home (which now shows Timer)
        if (parkingProvider.newlyStartedSession != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            parkingProvider.clearNewlyStartedSession();
            setState(() {
              _currentIndex = 0; // Switch to Home tab showing the timer
            });
          });
        }

        final List<Widget> pages = [
          DashboardScreen(),
          const ZoneListScreen(),
          const WalletScreen(),
          const ProfileScreen(),
        ];

        return Scaffold(
          backgroundColor: Colors.white,
          extendBody: true,
          appBar: AppBar(
            title: const Text('Jambo Parking'),
            elevation: 0,
            actions: [
              // NEW: Profile button
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const new_profile.ProfileScreen()),
                ),
                tooltip: 'New Profile',
              ),
              // NEW: Reservations button
              IconButton(
                icon: const Icon(Icons.bookmark),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReservationsListScreen()),
                ),
                tooltip: 'Reservations',
              ),
              // NEW: Host dashboard button (if user is host)
              Consumer<HostProvider>(
                builder: (context, hostProvider, _) {
                  return hostProvider.isHost
                      ? IconButton(
                          icon: const Icon(Icons.business),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HostParkingScreen(),
                            ),
                          ),
                          tooltip: 'Host Dashboard',
                        )
                      : const SizedBox();
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              IndexedStack(index: _currentIndex, children: pages),
              Positioned(
                left: 24,
                right: 24,
                bottom: 32, // Floating padding from bottom
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Global Active Session Overlay
                    Consumer<ParkingProvider>(
                      builder: (context, provider, _) {
                        final active = provider.activeSessions;
                        if (active.isEmpty) return const SizedBox.shrink();
                        
                        final session = active.first;
                        final now = DateTime.now();
                        final remaining = session.endTime?.difference(now) ?? Duration.zero;
                        
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (_) => ActiveSessionScreen(session: session))
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0078D4).withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0078D4),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.timer_rounded, color: Colors.white, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          session.zoneName,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        Text(
                                          'Time remaining: ${provider.formatDuration(remaining)}',
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'VIEW',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Bottom Navigation Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BottomNavigationBar(
                              currentIndex: _currentIndex,
                              onTap: (index) => setState(() => _currentIndex = index),
                              type: BottomNavigationBarType.fixed,
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              selectedItemColor: const Color(0xFF0078D4),
                              unselectedItemColor: const Color(0xFF64748B),
                              showSelectedLabels: true,
                              showUnselectedLabels: true,
                              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                              items: [
                                const BottomNavigationBarItem(
                                  icon: Padding(
                                    padding: EdgeInsets.only(bottom: 4),
                                    child: Icon(Icons.home_outlined),
                                  ),
                                  activeIcon: Padding(
                                    padding: EdgeInsets.only(bottom: 4),
                                    child: Icon(Icons.home_rounded),
                                  ),
                                  label: 'Home',
                                ),
                                const BottomNavigationBarItem(
                                  icon: Padding(
                                    padding: EdgeInsets.only(bottom: 4),
                                    child: Icon(Icons.map_outlined),
                                  ),
                                  activeIcon: Padding(
                                    padding: EdgeInsets.only(bottom: 4),
                                    child: Icon(Icons.map_rounded),
                                  ),
                                  label: 'Zones',
                                ),
                                const BottomNavigationBarItem(
                                  icon: Padding(
                                    padding: EdgeInsets.only(bottom: 4),
                                    child: Icon(Icons.account_balance_wallet_outlined),
                                  ),
                                  activeIcon: Padding(
                                    padding: EdgeInsets.only(bottom: 4),
                                    child: Icon(Icons.account_balance_wallet_rounded),
                                  ),
                                  label: 'Wallet',
                                ),
                                const BottomNavigationBarItem(
                                  icon: Padding(
                                    padding: EdgeInsets.only(bottom: 4),
                                    child: Icon(Icons.person_outline_rounded),
                                  ),
                                  activeIcon: Padding(
                                    padding: EdgeInsets.only(bottom: 4),
                                    child: Icon(Icons.person_rounded),
                                  ),
                                  label: 'Profile',
                                ),
                              ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void setTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
