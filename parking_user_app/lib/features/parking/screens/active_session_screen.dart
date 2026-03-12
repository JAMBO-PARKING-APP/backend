import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parking_user_app/features/parking/models/parking_session_model.dart';
import 'package:parking_user_app/features/parking/providers/parking_provider.dart';
import 'package:parking_user_app/features/parking/screens/qr_code_view_screen.dart';
import 'package:parking_user_app/core/app_theme.dart';
import 'package:parking_user_app/core/widgets/glass_container.dart';
import 'package:parking_user_app/core/dialog_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class ActiveSessionScreen extends StatefulWidget {
  final ParkingSession session;
  const ActiveSessionScreen({super.key, required this.session});

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  Duration _remaining = Duration.zero;
  Duration _totalDuration = Duration.zero;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _calculateTotalDuration();
    _calculateRemaining();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _calculateRemaining();
        _updateDistance();
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadSavedData();
  }

  String? _localPhotoPath;
  double? _distance;
  double? _savedLat;
  double? _savedLng;

  Future<void> _loadSavedData() async {
    final info = await context.read<ParkingProvider>().getSavedSpot(
      widget.session.id,
    );
    setState(() {
      _savedLat = info['lat'];
      _savedLng = info['lng'];
      _localPhotoPath = info['photo_path'];
    });
  }

  Future<void> _updateDistance() async {
    if (_savedLat == null || _savedLng == null) return;
    try {
      Position current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
      double dist = Geolocator.distanceBetween(
        current.latitude,
        current.longitude,
        _savedLat!,
        _savedLng!,
      );
      if (mounted) setState(() => _distance = dist);
    } catch (_) {}
  }

  void _calculateTotalDuration() {
    if (widget.session.endTime == null) return;
    _totalDuration = widget.session.endTime!.difference(
      widget.session.startTime,
    );
  }

  void _calculateRemaining() {
    if (widget.session.endTime == null) return;
    final now = DateTime.now();
    final diff = widget.session.endTime!.difference(now);
    setState(() {
      _remaining = diff.isNegative ? Duration.zero : diff;
    });

    if (_remaining.inMinutes < 15 && _remaining.inSeconds > 0) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _handleEndParking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Parking'),
        content: const Text(
          'Are you sure you want to end this parking session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('End Session'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<ParkingProvider>().endParking(
        widget.session.id,
      );
      if (success && mounted) {
        Navigator.pop(context);
        DialogService.showSuccessDialog(
          title: 'Session Ended',
          message: 'Your parking session has been stopped successfully.',
        );
      }
    }
  }

  void _handleExtendParking() {
    int additionalHours = 1;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Extend Duration',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAdjustButton(
                      icon: Icons.remove,
                      onTap: additionalHours > 1
                          ? () => setModalState(() => additionalHours--)
                          : null,
                    ),
                    Container(
                      width: 120,
                      alignment: Alignment.center,
                      child: Text(
                        '$additionalHours hr${additionalHours > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    _buildAdjustButton(
                      icon: Icons.add,
                      onTap: () => setModalState(() => additionalHours++),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () async {
                    final success = await context
                        .read<ParkingProvider>()
                        .extendParking(widget.session.id, additionalHours);
                    if (context.mounted) {
                      Navigator.pop(context);
                      if (success) {
                        DialogService.showSuccessDialog(
                          title: 'Extended!',
                          message:
                              'Added $additionalHours hour(s) to your session.',
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('CONFIRM EXTENSION'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdjustButton({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  void _handleSaveSpot() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        await context.read<ParkingProvider>().saveSpot(
          widget.session.id,
          position.latitude,
          position.longitude,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Parking location saved!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save location: $e')));
      }
    }
  }

  void _handleTakePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null && mounted) {
      await context.read<ParkingProvider>().savePhoto(
        widget.session.id,
        image.path,
      );
      if (mounted) {
        setState(() => _localPhotoPath = image.path);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Parking photo saved!')));
      }
    }
  }

  void _handleLocateCar() async {
    if (_savedLat != null && _savedLng != null) {
      final url =
          'https://www.google.com/maps/search/?api=1&query=$_savedLat,$_savedLng';
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _handleShareSpot() async {
    final endTimeStr = widget.session.endTime != null
        ? DateFormat('hh:mm a').format(widget.session.endTime!)
        : 'Unknown';
    final message =
        'I am parked at ${widget.session.zoneName} (${widget.session.vehiclePlate}). Session ends at $endTimeStr.';
    final url = 'whatsapp://send?text=${Uri.encodeComponent(message)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLowTime = _remaining.inMinutes < 15;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            height: MediaQuery.of(context).size.height * 0.45,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  isLowTime ? AppTheme.errorColor : AppTheme.primaryColor,
                  AppTheme.backgroundColor,
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Active Session',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.share_outlined,
                          color: Colors.white,
                        ),
                        onPressed: _handleShareSpot,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Zone & Vehicle Info
                        GlassContainer(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.directions_car_filled_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.session.zoneName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Plate: ${widget.session.vehiclePlate}',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_distance != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_distance!.toStringAsFixed(0)}m',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Futuristic Timer
                        ScaleTransition(
                          scale: isLowTime
                              ? _pulseAnimation
                              : const AlwaysStoppedAnimation(1.0),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Glow/Shadow
                              Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (isLowTime
                                                  ? AppTheme.errorColor
                                                  : AppTheme.primaryColor)
                                              .withValues(alpha: 0.3),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 250,
                                height: 250,
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(
                                    begin: 0.0,
                                    end: _totalDuration.inSeconds > 0
                                        ? _remaining.inSeconds /
                                              _totalDuration.inSeconds
                                        : 0.0,
                                  ),
                                  duration: const Duration(seconds: 1),
                                  builder: (context, value, child) =>
                                      CircularProgressIndicator(
                                        value: value,
                                        strokeWidth: 10,
                                        strokeCap: StrokeCap.round,
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.1),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              isLowTime
                                                  ? Colors.white
                                                  : Colors.white,
                                            ),
                                      ),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isLowTime ? 'HURRY UP!' : 'REMAINING',
                                    style: TextStyle(
                                      fontSize: 12,
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDuration(_remaining),
                                    style: const TextStyle(
                                      fontSize: 44,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFeatures: [
                                        ui.FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Actions Grid
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildActionItem(
                              icon: Icons.my_location,
                              label: 'Save Spot',
                              onTap: _handleSaveSpot,
                            ),
                            _buildActionItem(
                              icon: Icons.camera_alt_outlined,
                              label: 'Photo',
                              onTap: _handleTakePhoto,
                            ),
                            _buildActionItem(
                              icon: Icons.explore_outlined,
                              label: 'Locate',
                              onTap: _handleLocateCar,
                            ),
                            _buildActionItem(
                              icon: Icons.qr_code,
                              label: 'QR Pass',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      QRCodeViewScreen(session: widget.session),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        if (_localPhotoPath != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            width: double.infinity,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: DecorationImage(
                                image: FileImage(File(_localPhotoPath!)),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                                onPressed: () =>
                                    setState(() => _localPhotoPath = null),
                              ),
                            ),
                          ),

                        // Bottom Buttons
                        ElevatedButton(
                          onPressed: _handleExtendParking,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                          child: const Text(
                            'EXTEND PARKING',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _handleEndParking,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            side: BorderSide(
                              color: AppTheme.errorColor.withValues(alpha: 0.5),
                            ),
                            foregroundColor: AppTheme.errorColor,
                          ),
                          child: const Text(
                            'END SESSION',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
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
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
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
            child: Icon(icon, color: AppTheme.primaryColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
