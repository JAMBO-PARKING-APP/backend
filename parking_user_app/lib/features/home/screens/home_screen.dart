import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:parking_user_app/features/parking/screens/parking_map_screen.dart';
import 'package:parking_user_app/features/parking/screens/zone_list_screen.dart';
import 'package:parking_user_app/features/payments/screens/wallet_screen.dart';
import 'package:parking_user_app/features/auth/screens/profile_screen.dart';
import 'package:parking_user_app/features/parking/screens/active_session_screen.dart';
import 'package:parking_user_app/core/app_theme.dart';
import 'package:parking_user_app/core/location_service.dart';
import 'package:parking_user_app/features/payments/providers/payment_provider.dart';
import 'package:parking_user_app/features/parking/providers/parking_provider.dart';
import 'package:parking_user_app/features/parking/providers/violation_provider.dart';
import 'package:parking_user_app/features/auth/providers/vehicle_provider.dart';
import 'package:parking_user_app/features/notifications/providers/notification_provider.dart';
import 'package:parking_user_app/features/parking/providers/reservation_provider.dart';
import 'package:parking_user_app/features/parking/providers/zone_provider.dart';

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
          Consumer<ParkingProvider>(
            builder: (context, provider, _) {
              final active = provider.activeSessions;
              if (active.isEmpty) return const ParkingMapScreen();
              return ActiveSessionScreen(
                key: ValueKey('active_${active.first.id}'),
                session: active.first,
              );
            },
          ),
          const ZoneListScreen(),
          const WalletScreen(),
          const ProfileScreen(),
        ];

        return Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              IndexedStack(index: _currentIndex, children: pages),
              Positioned(
                left: 24,
                right: 24,
                bottom: 32, // Floating padding from bottom
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85), // Frosted glass overlay
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
                        onTap:
                            (index) => setState(() => _currentIndex = index),
                        type: BottomNavigationBarType.fixed,
                        backgroundColor:
                            Colors.transparent, // Transparent for blur
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
                        items: [
                          BottomNavigationBarItem(
                            icon: const Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Icon(Icons.map_outlined),
                            ),
                            activeIcon: Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Selector<ParkingProvider, bool>(
                                selector: (_, p) => p.activeSessions.isNotEmpty,
                                builder: (context, hasActive, _) => Icon(
                                  hasActive
                                      ? Icons.timer_outlined
                                      : Icons.map_rounded,
                                ),
                              ),
                            ),
                            label: 'Home',
                          ),
                          const BottomNavigationBarItem(
                            icon: Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Icon(Icons.directions_car_outlined),
                            ),
                            activeIcon: Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Icon(Icons.directions_car_rounded),
                            ),
                            label: 'Explore',
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
