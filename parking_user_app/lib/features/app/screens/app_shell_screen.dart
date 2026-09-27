import 'package:flutter/material.dart';
import 'package:parking_user_app/core/app_theme.dart';
import 'package:parking_user_app/core/location_service.dart';
import 'package:parking_user_app/features/auth/providers/auth_provider.dart';
import 'package:parking_user_app/features/auth/models/vehicle_model.dart';
import 'package:parking_user_app/features/auth/providers/vehicle_provider.dart';
import 'package:parking_user_app/features/auth/screens/profile_screen.dart';
import 'package:parking_user_app/features/notifications/providers/notification_provider.dart';
import 'package:parking_user_app/features/notifications/screens/notification_screen.dart';
import 'package:parking_user_app/features/parking/models/zone_model.dart';
import 'package:parking_user_app/features/parking/providers/parking_session_provider.dart';
import 'package:parking_user_app/features/parking/providers/reservation_provider.dart';
import 'package:parking_user_app/features/parking/providers/zone_provider.dart';
import 'package:parking_user_app/features/payments/screens/wallet_screen.dart';
import 'package:parking_user_app/features/rewards/screens/rewards_screen.dart';
import 'package:parking_user_app/features/support/screens/support_screen.dart';
import 'package:provider/provider.dart';

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ZoneProvider>().fetchZones();
      context.read<ParkingSessionProvider>().fetchSessions();
      context.read<ReservationProvider>().fetchReservations();
      context.read<VehicleProvider>().fetchVehicles();
      context.read<NotificationProvider>().fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    final pages = <Widget>[
      _ExploreTab(onStartParking: _startParking),
      const _SessionsTab(),
      _ReservationsTab(onCreate: _createReservation),
      const WalletScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.local_parking_outlined),
            selectedIcon: Icon(Icons.local_parking_rounded),
            label: 'Explore',
          ),
          const NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer_rounded),
            label: 'Sessions',
          ),
          const NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            selectedIcon: Icon(Icons.event_available_rounded),
            label: 'Reserve',
          ),
          const NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.person_outline_rounded),
            ),
            selectedIcon: const Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Future<void> _startParking(Zone zone) async {
    final vehicles = context.read<VehicleProvider>().vehicles;
    if (vehicles.isEmpty) {
      _showMessage('Add a vehicle to your profile before starting parking.');
      return;
    }
    final vehicleId = await showDialog<String>(
      context: context,
      builder: (context) => _VehiclePickerDialog(vehicles: vehicles),
    );
    if (vehicleId == null || !mounted) return;
    final position = await LocationService().getCurrentPosition();
    if (!mounted) return;
    if (position == null) {
      _showMessage('Enable location services to start a parking session.');
      return;
    }
    final success = await context.read<ParkingSessionProvider>().startSession(
      vehicleId: vehicleId,
      zoneId: zone.id,
      durationMinutes: 60,
      latitude: position.latitude,
      longitude: position.longitude,
    );
    if (mounted) {
      _showMessage(
        success
            ? 'Parking session started.'
            : context.read<ParkingSessionProvider>().errorMessage ??
                  'Could not start your session.',
      );
    }
  }

  Future<void> _createReservation() async {
    final zones = context.read<ZoneProvider>().zones;
    final vehicles = context.read<VehicleProvider>().vehicles;
    if (zones.isEmpty || vehicles.isEmpty) {
      _showMessage('Add a vehicle and load an available parking zone first.');
      return;
    }
    final selection = await showDialog<_ReservationSelection>(
      context: context,
      builder: (context) =>
          _ReservationDialog(zones: zones, vehicles: vehicles),
    );
    if (selection == null || !mounted) return;
    final from = DateTime.now().add(const Duration(minutes: 15));
    final success = await context.read<ReservationProvider>().createReservation(
      vehicleId: selection.vehicleId,
      zoneId: selection.zoneId,
      reservedFrom: from,
      reservedUntil: from.add(const Duration(hours: 1)),
      confirmImmediately: true,
      paymentMethod: 'wallet',
    );
    if (mounted) {
      _showMessage(
        success
            ? 'Reservation created.'
            : context.read<ReservationProvider>().errorMessage ??
                  'Could not create your reservation.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ExploreTab extends StatelessWidget {
  const _ExploreTab({required this.onStartParking});

  final ValueChanged<Zone> onStartParking;

  @override
  Widget build(BuildContext context) {
    final zones = context.watch<ZoneProvider>();
    final user = context.watch<AuthProvider>().user;
    final sessions = context.watch<ParkingSessionProvider>().activeSessions;
    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user?.firstName ?? 'there'}'),
        actions: [
          IconButton(
            tooltip: 'Rewards',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const RewardsScreen())),
            icon: const Icon(Icons.stars_rounded),
          ),
          Consumer<NotificationProvider>(
            builder: (context, notifications, _) => IconButton(
              tooltip: 'Notifications',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              ),
              icon: Badge(
                isLabelVisible: notifications.unreadCount > 0,
                label: Text('${notifications.unreadCount}'),
                child: const Icon(Icons.notifications_outlined),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Help',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SupportScreen())),
            icon: const Icon(Icons.help_outline_rounded),
          ),
          IconButton(
            tooltip: 'Refresh zones',
            onPressed: zones.fetchZones,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: zones.fetchZones,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryDark, AppTheme.primaryColor],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Find parking nearby',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${zones.zones.length} parking zones available',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${sessions.length} active ${sessions.length == 1 ? 'session' : 'sessions'}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Nearby zones', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (zones.isLoading && zones.zones.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (zones.errorMessage != null && zones.zones.isEmpty)
              _EmptyState(
                icon: Icons.wifi_off_rounded,
                title: 'Could not load parking zones',
                message: zones.errorMessage!,
              )
            else if (zones.zones.isEmpty)
              const _EmptyState(
                icon: Icons.location_off_outlined,
                title: 'No parking zones found',
                message: 'Pull down to retry, or check back later.',
              )
            else
              ...zones.zones.map(
                (zone) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.local_parking_rounded),
                    ),
                    title: Text(zone.name),
                    subtitle: Text(
                      '${zone.availableSlots} spaces available'
                      '${zone.distanceKm == null ? '' : ' · ${zone.distanceKm!.toStringAsFixed(1)} km'}',
                    ),
                    trailing: FilledButton(
                      onPressed: zone.availableSlots > 0
                          ? () => onStartParking(zone)
                          : null,
                      child: const Text('Park'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SessionsTab extends StatelessWidget {
  const _SessionsTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ParkingSessionProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('My parking sessions'),
        actions: [
          IconButton(
            onPressed: provider.fetchSessions,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: provider.isLoading && provider.sessions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.sessions.isEmpty
          ? const _EmptyState(
              icon: Icons.timer_off_outlined,
              title: 'No sessions yet',
              message:
                  'Your active and completed parking sessions will appear here.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.sessions.length,
              itemBuilder: (context, index) {
                final session = provider.sessions[index];
                final active = session.status == 'active';
                return Card(
                  child: ListTile(
                    title: Text(session.vehiclePlate),
                    subtitle: Text(
                      '${session.zoneName ?? 'Parking zone'} · ${session.status}'
                      '\nEnds ${TimeOfDay.fromDateTime(session.plannedEndTime).format(context)}',
                    ),
                    isThreeLine: true,
                    trailing: active
                        ? IconButton(
                            tooltip: 'End session',
                            icon: const Icon(Icons.stop_circle_outlined),
                            onPressed: () async {
                              final ended = await context
                                  .read<ParkingSessionProvider>()
                                  .endSession(session.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ended
                                          ? 'Session ended.'
                                          : provider.errorMessage ??
                                                'Could not end session.',
                                    ),
                                  ),
                                );
                              }
                            },
                          )
                        : const Icon(Icons.receipt_long_outlined),
                  ),
                );
              },
            ),
    );
  }
}

class _ReservationsTab extends StatelessWidget {
  const _ReservationsTab({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReservationProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservations'),
        actions: [
          IconButton(
            onPressed: provider.fetchReservations,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onCreate,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Reserve'),
      ),
      body: provider.isLoading && provider.reservations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.reservations.isEmpty
          ? const _EmptyState(
              icon: Icons.event_busy_outlined,
              title: 'No reservations',
              message: 'Reserve a parking space in a nearby zone.',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
              itemCount: provider.reservations.length,
              itemBuilder: (context, index) {
                final reservation = provider.reservations[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(reservation.zoneName),
                          subtitle: Text(
                            '${reservation.vehiclePlate} · ${reservation.status}\n'
                            '${reservation.startTime.toLocal()}',
                          ),
                          isThreeLine: true,
                          trailing: Text(reservation.cost.toStringAsFixed(0)),
                        ),
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 8,
                          children: [
                            if (reservation.status == 'confirmed')
                              TextButton(
                                onPressed: () =>
                                    provider.confirmReservationWithWallet(
                                      reservation.id,
                                    ),
                                child: const Text('Pay with wallet'),
                              ),
                            if (reservation.isPendingPayment)
                              TextButton(
                                onPressed: () async {
                                  final started = await provider
                                      .startReservation(reservation.id);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        started
                                            ? 'Parking started.'
                                            : provider.errorMessage ??
                                                  'Could not start parking.',
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Start'),
                              ),
                            if (reservation.canCancel)
                              TextButton(
                                onPressed: () =>
                                    provider.cancelReservation(reservation.id),
                                child: const Text('Cancel'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _VehiclePickerDialog extends StatelessWidget {
  const _VehiclePickerDialog({required this.vehicles});

  final List<VehicleModel> vehicles;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Choose a vehicle'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: vehicles
          .map(
            (vehicle) => ListTile(
              title: Text(vehicle.licensePlate),
              subtitle: Text('${vehicle.make} ${vehicle.model}'.trim()),
              onTap: () => Navigator.of(context).pop(vehicle.id),
            ),
          )
          .toList(),
    ),
  );
}

class _ReservationSelection {
  const _ReservationSelection(this.zoneId, this.vehicleId);

  final String zoneId;
  final String vehicleId;
}

class _ReservationDialog extends StatefulWidget {
  const _ReservationDialog({required this.zones, required this.vehicles});

  final List<Zone> zones;
  final List<VehicleModel> vehicles;

  @override
  State<_ReservationDialog> createState() => _ReservationDialogState();
}

class _ReservationDialogState extends State<_ReservationDialog> {
  late String _zoneId = widget.zones.first.id;
  late String _vehicleId = widget.vehicles.first.id;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Reserve parking'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _zoneId,
          decoration: const InputDecoration(labelText: 'Zone'),
          items: widget.zones
              .map(
                (zone) =>
                    DropdownMenuItem(value: zone.id, child: Text(zone.name)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _zoneId = value);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _vehicleId,
          decoration: const InputDecoration(labelText: 'Vehicle'),
          items: widget.vehicles
              .map(
                (vehicle) => DropdownMenuItem<String>(
                  value: vehicle.id,
                  child: Text(vehicle.licensePlate),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _vehicleId = value);
          },
        ),
        const SizedBox(height: 12),
        const Text('One-hour reservation starting in 15 minutes.'),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(
          context,
        ).pop(_ReservationSelection(_zoneId, _vehicleId)),
        child: const Text('Create'),
      ),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 46, color: AppTheme.textSecondary),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}
