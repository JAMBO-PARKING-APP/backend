import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:parking_user_app/features/parking/models/zone_model.dart';
import 'package:parking_user_app/features/settings/providers/settings_provider.dart';
import 'package:parking_user_app/core/utils/currency_formatter.dart';
import 'package:parking_user_app/features/parking/providers/zone_provider.dart';
import 'package:parking_user_app/core/app_theme.dart';
import 'package:parking_user_app/core/widgets/glass_container.dart';
import 'package:parking_user_app/features/parking/providers/parking_provider.dart';
import 'package:parking_user_app/features/parking/providers/reservation_provider.dart';
import 'package:parking_user_app/features/parking/screens/create_reservation_screen.dart';
import 'package:parking_user_app/features/home/screens/home_screen.dart';

class ParkingMapScreen extends StatefulWidget {
  final Zone? initialZone;

  const ParkingMapScreen({super.key, this.initialZone});

  @override
  State<ParkingMapScreen> createState() => _ParkingMapScreenState();
}

class _ParkingMapScreenState extends State<ParkingMapScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _isLoading = true;
  List<Marker> _markers = [];
  List<LatLng> _routePoints = [];
  StreamSubscription<Position>? _positionStreamSubscription;
  Zone? _selectedZone;
  double? _distanceToTarget;

  @override
  void initState() {
    super.initState();
    if (widget.initialZone != null) {
      _isLoading = false;
      _selectedZone = widget.initialZone;
    }
    _getCurrentLocation();
    _startLocationUpdates();
    _loadZones();

    // Listen to ParkingProvider updates for marker highlighting
    context.read<ParkingProvider>().addListener(_onParkingStatusChanged);
  }

  void _onParkingStatusChanged() {
    if (mounted) {
      _updateMarkers();
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    context.read<ParkingProvider>().removeListener(_onParkingStatusChanged);
    _mapController.dispose();
    super.dispose();
  }

  void _startLocationUpdates() {
    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          if (mounted) {
            setState(() {
              _currentPosition = position;
              _updateDistance();
            });
          }
        });
  }

  void _updateDistance() {
    if (_currentPosition != null && _selectedZone != null) {
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _selectedZone!.latitude,
        _selectedZone!.longitude,
      );
      setState(() {
        _distanceToTarget = distance;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (widget.initialZone == null) setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (widget.initialZone == null) setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (widget.initialZone == null) setState(() => _isLoading = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
          _updateDistance();
        });
        if (widget.initialZone != null) {
          _fetchRoute(
            LatLng(widget.initialZone!.latitude, widget.initialZone!.longitude),
          );
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (widget.initialZone == null && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchRoute(LatLng destination) async {
    if (_currentPosition == null) return;

    final start = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List;
        if (routes.isNotEmpty) {
          final geometry = routes[0]['geometry'];
          final coordinates = geometry['coordinates'] as List;
          setState(() {
            _routePoints = coordinates
                .map(
                  (coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()),
                )
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
    }
  }

  Future<void> _loadZones() async {
    await context.read<ZoneProvider>().fetchZones();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateMarkers();
      }
    });

    if (widget.initialZone != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showZoneDetails(widget.initialZone!);
        }
      });
    }
  }

  void _updateMarkers() {
    final zones = context.read<ZoneProvider>().zones;
    final parkingProvider = context.read<ParkingProvider>();
    final activeZones = parkingProvider.activeSessions
        .map((s) => s.zoneName)
        .toSet();
    final markers = <Marker>[];

    for (var zone in zones) {
      final bool isActive = activeZones.contains(zone.name);
      final bool isFull = zone.availableSlots == 0;
      final Color markerColor = isActive
          ? AppTheme.accentColor
          : (isFull
                ? AppTheme.errorColor
                : (zone.availableSlots < 5
                      ? AppTheme.warningColor
                      : AppTheme.successColor));

      markers.add(
        Marker(
          point: LatLng(zone.latitude, zone.longitude),
          width: isActive ? 80 : 60,
          height: isActive ? 90 : 70,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedZone = zone;
                _updateDistance();
              });
              _showZoneDetails(zone);
              _fetchRoute(LatLng(zone.latitude, zone.longitude));
            },
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Highlight Pulse for active
                if (isActive) _ActiveMarkerPulse(color: markerColor),

                // Main Pin Icon
                Icon(
                  Icons.location_on,
                  color: markerColor,
                  size: isActive ? 60 : 50,
                ),
                // Inner Car Icon
                Positioned(
                  top: isActive ? 10 : 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isActive
                          ? Icons.stars_rounded
                          : Icons.directions_car_filled_rounded,
                      color: markerColor,
                      size: isActive ? 20 : 16,
                    ),
                  ),
                ),
                // Available Slots Badge
                if (!isActive)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: markerColor, width: 1),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 2),
                        ],
                      ),
                      child: Text(
                        '${zone.availableSlots}',
                        style: TextStyle(
                          color: markerColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    if (mounted) {
      setState(() => _markers = markers);
    }
  }

  void _showZoneDetails(Zone zone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        borderRadius: BorderRadius.circular(32),
        blur: 20,
        opacity: 0.8,
        padding: EdgeInsets.zero,
        gradientColors: [
          Colors.white.withValues(alpha: 0.9),
          Colors.white.withValues(alpha: 0.8),
        ],
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          zone.description ?? 'Street Parking',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.navigation,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItemModern(
                    Icons.directions_car_filled_rounded,
                    'Available',
                    '${zone.availableSlots}/${zone.totalSlots}',
                    AppTheme.primaryColor,
                  ),
                  _buildStatItemModern(
                    Icons.access_time_rounded,
                    'Hourly Rate',
                    context.select<SettingsProvider, String>(
                      (settings) => CurrencyFormatter.formatCurrency(
                        zone.hourlyRate,
                        settings.countryConfig,
                      ),
                    ),
                    AppTheme.accentColor,
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Consumer<ReservationProvider>(
                builder: (context, resProvider, _) {
                  final hasActiveReservation = resProvider.reservations.any(
                    (r) => r.zoneName == zone.name && r.status == 'confirmed',
                  );

                  if (hasActiveReservation) {
                    return ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Logic to start session from reservation
                        final homeState = context
                            .findAncestorStateOfType<HomeScreenState>();
                        if (homeState != null) {
                          // Navigate to Home tab which might have start session logic
                          homeState.navigateToTab(0);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        backgroundColor: AppTheme.successColor,
                      ),
                      child: const Text('Start Reserved Session'),
                    );
                  }

                  return ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate directly to booking screen for this zone
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
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Text('Start Parking Session'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItemModern(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    LatLng? initialCenter;
    if (widget.initialZone != null) {
      initialCenter = LatLng(
        widget.initialZone!.latitude,
        widget.initialZone!.longitude,
      );
    } else if (_currentPosition != null) {
      initialCenter = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Nearby Parking',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        automaticallyImplyLeading: false,
        leading: null, // Ensure no drawer icon
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : initialCenter == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text('Unable to get your location'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _getCurrentLocation,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: widget.initialZone != null ? 16 : 14,
                    maxZoom: 18,
                    minZoom: 3,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.spacepark.app',
                    ),
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 5.0,
                            color: AppTheme.primaryColor.withValues(alpha: 0.7),
                          ),
                        ],
                      ),
                    MarkerLayer(markers: _markers),
                    if (_currentPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            width: 60,
                            height: 60,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.directions_car_filled_rounded,
                                color: AppTheme.primaryColor,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

          // Search Bar Overlay
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: GlassContainer(
              borderRadius: BorderRadius.circular(24),
              blur: 15,
              opacity: 0.85,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search for parking...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.primaryColor,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.tune,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Floating Location Button
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                if (_currentPosition != null) {
                  _mapController.move(
                    LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    14,
                  );
                } else {
                  _getCurrentLocation();
                }
              },
              backgroundColor: Colors.white,
              child: const Icon(
                Icons.my_location,
                color: AppTheme.primaryColor,
              ),
            ),
          ),

          // Live Monitoring Overlay (Distance)
          if (_selectedZone != null && _distanceToTarget != null)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Navigating to ${_selectedZone!.name}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            '${(_distanceToTarget! / 1000).toStringAsFixed(1)} km remaining',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.directions_car,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedZone = null;
                          _distanceToTarget = null;
                          _routePoints = [];
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActiveMarkerPulse extends StatefulWidget {
  final Color color;
  const _ActiveMarkerPulse({required this.color});

  @override
  State<_ActiveMarkerPulse> createState() => _ActiveMarkerPulseState();
}

class _ActiveMarkerPulseState extends State<_ActiveMarkerPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _animation = Tween<double>(
      begin: 1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 50 * _animation.value,
          height: 50 * _animation.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: 1.0 - _controller.value),
          ),
        );
      },
    );
  }
}
