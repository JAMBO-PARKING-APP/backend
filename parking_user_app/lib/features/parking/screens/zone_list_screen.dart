import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:parking_user_app/features/parking/providers/zone_provider.dart';
import 'package:parking_user_app/features/parking/screens/parking_map_screen.dart';
import 'package:parking_user_app/features/payments/services/payment_service.dart';
import 'package:parking_user_app/core/app_theme.dart';
import 'package:parking_user_app/features/parking/screens/create_reservation_screen.dart';
import 'package:parking_user_app/features/home/screens/home_screen.dart';
import 'package:parking_user_app/core/localizations.dart';
import 'package:parking_user_app/core/utils/currency_formatter.dart';
import 'package:parking_user_app/widgets/base_scaffold.dart';

class ZoneListScreen extends StatefulWidget {
  const ZoneListScreen({super.key});

  @override
  State<ZoneListScreen> createState() => _ZoneListScreenState();
}

class _ZoneListScreenState extends State<ZoneListScreen> {
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ZoneProvider>().fetchZones();
      PaymentService().preWarmPesapal();
    });
  }

  Future<void> _determinePosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  double _calculateDistance(double lat, double lng) {
    if (_currentPosition == null) return 0.0;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lng,
    ) / 1000;
  }

  Future<void> _launchMaps(double lat, double lng) async {
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open maps')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BaseScaffold(
      title: l10n.zones,
      showDrawer: false,
      currentIndex: 1, // Zones index
      onTabChanged: (index) {
        // If it's a child of HomeScreen, it should notify parent
        // For simplicity, we can use a key or find the state
        final homeState = context.findAncestorStateOfType<HomeScreenState>();
        if (homeState != null) {
          homeState.navigateToTab(index);
        }
      },
      body: Consumer<ZoneProvider>(
        builder: (context, zoneProvider, _) {
          if (zoneProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final zones = zoneProvider.zones;
          if (zones.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car_filled_rounded,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No parking found',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => zoneProvider.fetchZones(),
                    child: Text(l10n.tryAgain),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: zones.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final zone = zones[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
                child: InkWell(
                  onTap: () {
                    // Navigate to Map for this zone instead of instant booking
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (pushContext) =>
                            ParkingMapScreen(initialZone: zone),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
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
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Consumer<SettingsProvider>(
                                    builder: (context, settings, _) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${l10n.rate}: ${CurrencyFormatter.formatCurrency(zone.hourlyRate, settings.countryConfig)}/hr',
                                        style: const TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.local_parking_rounded,
                                        size: 16,
                                        color: AppTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${zone.code} • ${zone.availableSlots}/${zone.totalSlots} ${l10n.slots} • ${_calculateDistance(zone.latitude, zone.longitude).toStringAsFixed(1)} ${l10n.km}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (zone.imageUrl != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    zone.imageUrl!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey.shade200,
                                              child: const Icon(
                                                Icons.image_not_supported,
                                                color: Colors.grey,
                                              ),
                                            ),
                                  ),
                                ),
                              ),
                            IconButton(
                              icon: Icon(
                                Icons.directions_car_filled_rounded,
                                color: AppTheme.primaryColor,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (pushContext) =>
                                        ParkingMapScreen(initialZone: zone),
                                  ),
                                );
                              },
                              tooltip: l10n.viewOnMap,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, thickness: 1),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () =>
                                  _launchMaps(zone.latitude, zone.longitude),
                              icon: const Icon(Icons.directions_outlined, size: 20),
                              label: Text(l10n.directions),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.textSecondary,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (pushContext) =>
                                            CreateReservationScreen(
                                          initialZone: zone,
                                          isImmediate: false,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(l10n.bookSpot),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (pushContext) =>
                                            CreateReservationScreen(
                                          initialZone: zone,
                                          isImmediate: true,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 0,
                                    ),
                                    minimumSize: const Size(0, 36),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(l10n.startParking),
                                ),
                              ],
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
        },
      ),
    );
  }
}
