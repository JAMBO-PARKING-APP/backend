import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:ui' as ui;
import 'package:geolocator/geolocator.dart';
import 'package:parking_user_app/features/parking/screens/zone_list_screen.dart';
import 'package:parking_user_app/features/parking/screens/parking_history_screen.dart';
import 'package:parking_user_app/features/auth/screens/profile_screen.dart';
import 'package:parking_user_app/features/parking/providers/parking_provider.dart';
import 'package:parking_user_app/features/parking/screens/parking_map_screen.dart';
import 'package:parking_user_app/features/payments/providers/payment_provider.dart';
import 'package:parking_user_app/core/localizations.dart';
import 'package:parking_user_app/features/parking/providers/violation_provider.dart';
import 'package:parking_user_app/features/auth/providers/vehicle_provider.dart';
import 'package:parking_user_app/features/notifications/providers/notification_provider.dart';
import 'package:parking_user_app/features/parking/providers/reservation_provider.dart';
import 'package:parking_user_app/features/parking/providers/zone_provider.dart';
import 'package:parking_user_app/features/parking/screens/active_session_screen.dart';

import 'package:parking_user_app/features/payments/screens/wallet_screen.dart';
import 'package:parking_user_app/features/auth/screens/vehicle_list_screen.dart';
import 'package:parking_user_app/features/parking/screens/create_reservation_screen.dart';
import 'package:parking_user_app/features/notifications/screens/notification_screen.dart';
import 'package:parking_user_app/features/support/ai_chat_screen.dart';
import 'package:parking_user_app/features/home/screens/sidebar_navigation.dart';
import 'package:parking_user_app/features/settings/screens/settings_screen.dart';
import 'package:parking_user_app/core/app_theme.dart';
import 'package:parking_user_app/core/location_service.dart';
import 'package:parking_user_app/features/parking/models/zone_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:parking_user_app/features/settings/providers/settings_provider.dart';
import 'package:parking_user_app/core/utils/currency_formatter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _hasRedirectedToActiveSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().fetchWalletData();
      context.read<ParkingProvider>().fetchSessions();
      context.read<ParkingProvider>().fetchZones();
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
    if (_hasRedirectedToActiveSession) return;

    final parkingProvider = context.read<ParkingProvider>();
    // Wait for sessions to be fetched if they haven't been already
    if (parkingProvider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (parkingProvider.activeSessions.isNotEmpty && mounted) {
      final session = parkingProvider.activeSessions.first;
      _hasRedirectedToActiveSession = true;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActiveSessionScreen(session: session),
        ),
      );
    }
  }

  // No longer using global scaffold key here as sub-pages manage their own scaffolds

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeDashboard(onMenuPressed: () => _openDrawer()), // 0: Home
      const ZoneListScreen(), // 1: Zones
      const ParkingHistoryScreen(), // 2: History
      const AIChatScreen(), // 3: Live Chat (AI)
      const NotificationScreen(), // 4: Notifications
      const WalletScreen(), // 5: Wallet
      const ProfileScreen(), // 6: Profile
      const SettingsScreen(), // 7: Settings
    ];

    // No Scaffold here to avoid nested Scaffolds when sub-pages use BaseScaffold
    return IndexedStack(index: _currentIndex, children: pages);
  }

  void _openDrawer() {
    // This is tricky if the Scaffold is now in children.
    // Children should handle opening their own drawer.
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

class HomeDashboard extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  const HomeDashboard({super.key, this.onMenuPressed});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  Position? _currentPosition;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startCountdownTimer();
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    // final auth = context.read<AuthProvider>();

    return Scaffold(
      drawer: SidebarNavigation(
        currentIndex: 0,
        onTabChanged: (index) {
          final homeState = context.findAncestorStateOfType<HomeScreenState>();
          if (homeState != null) {
            homeState.navigateToTab(index);
          }
        },
      ),
      body:
          Consumer6<
            ParkingProvider,
            PaymentProvider,
            ViolationProvider,
            VehicleProvider,
            NotificationProvider,
            ReservationProvider
          >(
            builder:
                (
                  context,
                  parking,
                  payment,
                  violations,
                  vehicleProvider,
                  notifications,
                  reservations,
                  _,
                ) {
                  final zoneProvider = context.watch<ZoneProvider>();
                  return SafeArea(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await Future.wait([
                          context.read<PaymentProvider>().fetchWalletData(),
                          context.read<ParkingProvider>().fetchSessions(),
                          context.read<ParkingProvider>().fetchZones(),
                          context.read<ViolationProvider>().fetchViolations(),
                          context.read<VehicleProvider>().fetchVehicles(),
                          context
                              .read<NotificationProvider>()
                              .fetchNotifications(),
                          context
                              .read<ReservationProvider>()
                              .fetchReservations(),
                        ]);
                      },
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          // Extended App Bar with Profile & Glassmorphism Header
                          SliverAppBar(
                            expandedHeight: 120.0,
                            floating: false,
                            pinned: true,
                            elevation: 0,
                            backgroundColor: AppTheme.primaryColor,
                            leading: IconButton(
                              icon: const Icon(Icons.menu, color: Colors.white),
                              onPressed:
                                  widget.onMenuPressed ??
                                  () => Scaffold.of(context).openDrawer(),
                            ),
                            flexibleSpace: FlexibleSpaceBar(
                              titlePadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              title: Text(
                                AppLocalizations.of(context).appTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              background: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppTheme.primaryColor,
                                      AppTheme.primaryColor.withValues(
                                        alpha: 0.8,
                                      ),
                                    ],
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      right: -20,
                                      top: -20,
                                      child: CircleAvatar(
                                        radius: 60,
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // 1. Smart Status Card (Hero)
                                  if (parking.isLoading &&
                                      parking.activeSessions.isEmpty)
                                    _buildSkeletonLoader(context)
                                  else
                                    _buildSmartStatusCard(
                                      context,
                                      parking,
                                      reservations,
                                    ),
                                  const SizedBox(height: 24),

                                  // 2. Data-Rich Alerts Section
                                  if (parking.isLoading &&
                                      violations.violations.isEmpty)
                                    _buildSkeletonLoader(context, height: 80)
                                  else
                                    _buildAlertsSection(
                                      context,
                                      violations,
                                      notifications,
                                      payment,
                                    ),

                                  // Phase 7: Recent & Favorite Zones Carousel
                                  if (zoneProvider.recentZones.isNotEmpty) ...[
                                    _buildRecentZonesSection(
                                      context,
                                      zoneProvider,
                                    ),
                                    const SizedBox(height: 24),
                                  ],

                                  // 3. Nearby Zones Carousel
                                  if (parking.isLoading &&
                                      parking.zones.isEmpty)
                                    _buildSkeletonLoader(context, height: 140)
                                  else
                                    _buildNearbyZonesSection(context, parking),

                                  // 4. Quick Actions Grid
                                  Text(
                                    AppLocalizations.of(context).quickActions,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  GridView.count(
                                    crossAxisCount: 4,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 8,
                                    childAspectRatio: 0.85,
                                    children: [
                                      _buildQuickActionItem(
                                        context,
                                        AppLocalizations.of(context).myVehicles,
                                        Icons.directions_car_filled_outlined,
                                        AppTheme.primaryColor,
                                        () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const VehicleListScreen(),
                                          ),
                                        ),
                                      ),
                                      _buildQuickActionItem(
                                        context,
                                        AppLocalizations.of(
                                          context,
                                        ).reservations,
                                        Icons.calendar_month_outlined,
                                        AppTheme.primaryColor,
                                        () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const CreateReservationScreen(),
                                          ),
                                        ),
                                      ),
                                      _buildQuickActionItem(
                                        context,
                                        AppLocalizations.of(context).wallet,
                                        Icons.account_balance_wallet_outlined,
                                        AppTheme.primaryColor,
                                        () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const WalletScreen(),
                                          ),
                                        ),
                                      ),
                                      _buildQuickActionItem(
                                        context,
                                        AppLocalizations.of(context).aiHelp,
                                        Icons.chat_bubble_outline_rounded,
                                        AppTheme.accentColor,
                                        () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const AIChatScreen(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 32),

                                  // 5. Recent Activity
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        ).recentActivity,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          final homeState = context
                                              .findAncestorStateOfType<
                                                HomeScreenState
                                              >();
                                          if (homeState != null) {
                                            homeState.setTab(2);
                                          }
                                        },
                                        child: Text(
                                          AppLocalizations.of(context).viewAll,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (parking.isLoading &&
                                      parking.sessions.isEmpty)
                                    _buildSkeletonLoader(context, height: 100)
                                  else if (parking.sessions.isEmpty)
                                    _buildModernEmptyState(
                                      AppLocalizations.of(
                                        context,
                                      ).noRecentSessions,
                                    )
                                  else
                                    for (var s in parking.sessions.take(3))
                                      _buildModernActivityItem(context, s),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ), // CustomScrollView
                    ), // RefreshIndicator
                  ); // SafeArea
                },
          ),
    );
  }

  // --- 1. Smart Status Card Implementations ---

  Widget _buildSmartStatusCard(
    BuildContext context,
    ParkingProvider parking,
    ReservationProvider reservations,
  ) {
    // A. Active Session Logic
    if (parking.activeSessions.isNotEmpty) {
      final session = parking.activeSessions.first;
      return GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActiveSessionScreen(session: session),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.7),
                    AppTheme.primaryDark.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.timer,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context).activeParking,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    session.zoneName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.vehiclePlate,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context).timeLeft,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Builder(
                            builder: (context) {
                              final remaining =
                                  session.endTime?.difference(DateTime.now()) ??
                                  Duration.zero;
                              return Text(
                                _formatDuration(
                                  remaining.isNegative
                                      ? Duration.zero
                                      : remaining,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context).currentCost,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Consumer<SettingsProvider>(
                            builder: (context, settings, _) => Text(
                              CurrencyFormatter.formatCurrency(
                                session.totalCost,
                                settings.countryConfig,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ActiveSessionScreen(session: session),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('View'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // B. Upcoming Reservation Logic
    // Sort and find next upcoming reservation
    final upcomingList =
        reservations.reservations
            .where(
              (r) =>
                  r.status == 'confirmed' &&
                  r.startTime.isAfter(DateTime.now()),
            )
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (upcomingList.isNotEmpty) {
      final reservation = upcomingList.first;
      final timeUntil = reservation.startTime.difference(DateTime.now());
      String timeDisplay;
      if (timeUntil.inHours > 0) {
        timeDisplay = 'in ${timeUntil.inHours}h ${timeUntil.inMinutes % 60}m';
      } else {
        timeDisplay = 'in ${timeUntil.inMinutes} mins';
      }

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.accentColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentColor.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).upcomingReservation,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    timeDisplay,
                    style: const TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              reservation.zoneName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, hh:mm a').format(reservation.startTime),
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ParkingMapScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.navigation, size: 16),
                label: Text(AppLocalizations.of(context).navigateToZone),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // C. Default: Find Parking
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ParkingMapScreen()),
      ),
      child: Container(
        height: 180,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(20),
          // Removed missing asset image
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context).lookingForParking,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).findSpotsNearYou,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppTheme.textSecondary),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context).searchDestination,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.tune,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. Alerts Section Implementation ---

  Widget _buildAlertsSection(
    BuildContext context,
    ViolationProvider violations,
    NotificationProvider notifications,
    PaymentProvider payment,
  ) {
    List<Widget> alerts = [];

    // Unpaid Violations Alert
    if (violations.unpaidCount > 0) {
      alerts.add(
        _buildActionableAlert(
          context: context,
          icon: Icons.warning_amber_rounded,
          color: AppTheme.errorColor,
          title:
              '${violations.unpaidCount} ${AppLocalizations.of(context).unpaidViolations}',
          subtitle: Consumer<SettingsProvider>(
            builder: (context, settings, _) => Text(
              'Total: ${CurrencyFormatter.formatCurrency(violations.totalUnpaidAmount, settings.countryConfig)}',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ),
          actionLabel: AppLocalizations.of(context).payNow,
          onTap: () {
            // Navigate to violations screen (Need to implement or link)
            // For now, toggle main tab to history perhaps?
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Navigate to Violations')),
            );
          },
        ),
      );
    }

    // Low Balance Alert
    if (payment.balance < 500) {
      // Threshold 500
      alerts.add(
        _buildActionableAlert(
          context: context,
          icon: Icons.account_balance_wallet_outlined,
          color: AppTheme.warningColor,
          title: 'Low Wallet Balance',
          subtitle: Consumer<SettingsProvider>(
            builder: (context, settings, _) => Text(
              'Current: ${CurrencyFormatter.formatCurrency(payment.balance, settings.countryConfig)}',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ),
          actionLabel: 'Top Up',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WalletScreen()),
          ),
        ),
      );
    }

    // Unread Notifications Alert
    if (notifications.unreadCount > 0) {
      alerts.add(
        _buildActionableAlert(
          context: context,
          icon: Icons.notifications_outlined,
          color: AppTheme.primaryColor,
          title: '${notifications.unreadCount} New Notifications',
          subtitle: const Text(
            'Stay updated',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          actionLabel: 'View',
          onTap: () {
            final homeState = context
                .findAncestorStateOfType<HomeScreenState>();
            if (homeState != null) homeState.setTab(4);
          },
        ),
      );
    }

    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        ...alerts.map(
          (alert) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: alert,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildActionableAlert({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required Widget subtitle,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                ),
                subtitle,
              ],
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: color.withValues(alpha: 0.3)),
              ),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Nearby Zones Carousel ---

  Widget _buildNearbyZonesSection(
    BuildContext context,
    ParkingProvider parking,
  ) {
    if (parking.zones.isEmpty) return const SizedBox.shrink();

    // Sort zones by distance if location available
    List<Zone> zones = List.from(parking.zones);
    if (_currentPosition != null) {
      zones.sort((a, b) {
        final distA = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          a.latitude,
          a.longitude,
        );
        final distB = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          b.latitude,
          b.longitude,
        );
        return distA.compareTo(distB);
      });
    }

    final displayZones = zones.take(5).toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Nearby Zones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                final homeState = context
                    .findAncestorStateOfType<HomeScreenState>();
                if (homeState != null) homeState.setTab(1);
              },
              child: const Text('View Map'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: displayZones.length,
            itemBuilder: (context, index) {
              final zone = displayZones[index];
              double? distance;
              if (_currentPosition != null) {
                distance = Geolocator.distanceBetween(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                  zone.latitude,
                  zone.longitude,
                );
              }

              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: _buildZoneCard(context, zone, distance),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildZoneCard(
    BuildContext context,
    Zone zone,
    double? distanceMeters,
  ) {
    String distanceDisplay = '';
    if (distanceMeters != null) {
      if (distanceMeters < 1000) {
        distanceDisplay = '${distanceMeters.toStringAsFixed(0)}m';
      } else {
        distanceDisplay = '${(distanceMeters / 1000).toStringAsFixed(1)}km';
      }
    }

    return GestureDetector(
      onTap: () {
        // Navigate to create reservation or zone details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateReservationScreen(initialZone: zone),
          ),
        );
      },
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Placeholder
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  color: Colors.grey[200],
                  image: zone.imageUrl != null
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(zone.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    if (zone.imageUrl == null)
                      Center(
                        child: Icon(
                          Icons.local_parking,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                      ),
                    if (distanceDisplay.isNotEmpty)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            distanceDisplay,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      zone.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Consumer<SettingsProvider>(
                          builder: (context, settings, _) => Text(
                            '${CurrencyFormatter.formatCurrency(zone.hourlyRate, settings.countryConfig)}/hr',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${zone.availableSlots} spots left',
                          style: TextStyle(
                            color: zone.availableSlots > 5
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widgets (Same as before, just kept for context if needed, but updated logic above replaces them mostly)

  Widget _buildQuickActionItem(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 0.5),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.history_rounded, size: 32, color: AppTheme.borderColor),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernActivityItem(BuildContext context, dynamic session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.local_parking_rounded,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          session.zoneName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          DateFormat('MMM dd, HH:mm').format(session.startTime),
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Consumer<SettingsProvider>(
              builder: (context, settings, _) => Text(
                CurrencyFormatter.formatCurrency(
                  session.totalCost,
                  settings.countryConfig,
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const Text(
              'Completed',
              style: TextStyle(color: AppTheme.successColor, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader(BuildContext context, {double height = 160}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildRecentZonesSection(
    BuildContext context,
    ZoneProvider zoneProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recently Used',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: zoneProvider.recentZones.length,
            itemBuilder: (context, index) {
              final zone = zoneProvider.recentZones[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: InkWell(
                  onTap: () {
                    // Navigate to start parking for this zone
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ZoneListScreen(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.history,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          zone.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${zone.hourlyRate}/hr',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
