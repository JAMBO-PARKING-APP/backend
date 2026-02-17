import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parking_user_app/features/parking/models/parking_session_model.dart';
import 'package:parking_user_app/features/parking/providers/parking_provider.dart';
import 'package:parking_user_app/features/parking/screens/qr_code_view_screen.dart';
import 'package:parking_user_app/core/app_theme.dart';
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

class _ActiveSessionScreenState extends State<ActiveSessionScreen> {
  late Timer _timer;
  Duration _remaining = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTotalDuration();
    _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateRemaining();
    });
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
  }

  @override
  void didUpdateWidget(ActiveSessionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.endTime != widget.session.endTime) {
      _calculateTotalDuration();
      _calculateRemaining();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
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
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<ParkingProvider>().endParking(
        widget.session.id,
      );
      if (success && mounted) {
        if (!mounted) return;
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
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Extend Parking',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text('How many additional hours?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: additionalHours > 1
                        ? () => setModalState(() => additionalHours--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      '$additionalHours',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setModalState(() => additionalHours++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  final success = await context
                      .read<ParkingProvider>()
                      .extendParking(widget.session.id, additionalHours);
                  if (context.mounted) {
                    Navigator.pop(context);
                    if (success) {
                      DialogService.showSuccessDialog(
                        title: 'Session Extended!',
                        message:
                            'You have added $additionalHours hour(s) to your session.',
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to extend session'),
                        ),
                      );
                    }
                  }
                },
                child: const Text('CONFIRM EXTENSION'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Phase 6: Find My Car ---

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Parking photo saved!')));
      }
    }
  }

  void _handleLocateCar() async {
    final info = await context.read<ParkingProvider>().getSavedSpot(
      widget.session.id,
    );
    final double? lat = info['lat'];
    final double? lng = info['lng'];

    if (lat != null && lng != null) {
      final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No location saved for this session')),
        );
      }
    }
  }

  // --- Phase 8: Share My Parking ---

  void _handleShareSpot() async {
    final endTimeStr = widget.session.endTime != null
        ? DateFormat('hh:mm a').format(widget.session.endTime!)
        : 'Unknown';

    final message =
        'I am parked at ${widget.session.zoneName} '
        'in vehicle ${widget.session.vehiclePlate}. '
        'My session ends at $endTimeStr.';

    final url = 'whatsapp://send?text=${Uri.encodeComponent(message)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      // Fallback to generic share if whatsapp not found (ideally use share_plus)
      final genericUrl = 'sms:?body=${Uri.encodeComponent(message)}';
      if (await canLaunchUrl(Uri.parse(genericUrl))) {
        await launchUrl(Uri.parse(genericUrl));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parking Session')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.session.zoneName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vehicle: ${widget.session.vehiclePlate}',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 60),
              // Timer Circle
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: CircularProgressIndicator(
                      value: _totalDuration.inSeconds > 0
                          ? _remaining.inSeconds / _totalDuration.inSeconds
                          : 0.0,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'TIME LEFT',
                        style: TextStyle(letterSpacing: 2, color: Colors.grey),
                      ),
                      Text(
                        _formatDuration(_remaining),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Interactive Actions Phase 6 & 8
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCircleAction(
                    icon: Icons.location_searching,
                    label: 'Save Spot',
                    onTap: _handleSaveSpot,
                  ),
                  _buildCircleAction(
                    icon: Icons.camera_alt_outlined,
                    label: 'Photo',
                    onTap: _handleTakePhoto,
                  ),
                  _buildCircleAction(
                    icon: Icons.map_outlined,
                    label: 'Locate',
                    onTap: _handleLocateCar,
                  ),
                  _buildCircleAction(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    onTap: _handleShareSpot,
                  ),
                ],
              ),
              const SizedBox(height: 40),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          QRCodeViewScreen(session: widget.session),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('SHOW QR PASS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _handleExtendParking,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text('EXTEND SESSION'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _handleEndParking,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: Colors.red),
                  foregroundColor: Colors.red,
                ),
                child: const Text('STOP PARKING'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
