import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parking_user_app/features/parking/models/parking_session_model.dart';
import 'package:parking_user_app/features/parking/providers/parking_provider.dart';
import 'package:parking_user_app/features/parking/screens/qr_code_view_screen.dart';
import 'package:parking_user_app/core/app_theme.dart';
import 'package:parking_user_app/core/dialog_service.dart';
import 'package:parking_user_app/core/services/local_notification_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:parking_user_app/widgets/base_scaffold.dart';
import 'package:parking_user_app/features/home/screens/home_screen.dart';
import 'package:parking_user_app/features/notifications/services/chat_service.dart';
import 'package:parking_user_app/features/notifications/screens/chat_screen.dart';

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

  @override
  void initState() {
    super.initState();
    try {
      _calculateTotalDuration();
      _calculateRemaining();
    } catch (e) {
      debugPrint('Error calculating durations: $e');
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _calculateRemaining();
        _updateDistance();
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    try {
      _scheduleLocalNotifications();
    } catch (e) {
      debugPrint('Error scheduling notifications: $e');
    }

    try {
      _loadSavedData();
    } catch (e) {
      debugPrint('Error loading saved data: $e');
    }
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

  void _scheduleLocalNotifications() {
    if (widget.session.endTime == null) return;
    LocalNotificationService.cancelAll();

    final end = widget.session.endTime!;
    _schedule(
      end.subtract(const Duration(minutes: 15)),
      "15 Minutes Left",
      "Your parking at ${widget.session.zoneName} expires in 15 minutes.",
    );
    _schedule(
      end.subtract(const Duration(minutes: 5)),
      "5 Minutes Left",
      "Your parking at ${widget.session.zoneName} expires in 5 minutes. Act now!",
    );
    _schedule(
      end.subtract(const Duration(minutes: 1)),
      "Expiring Now",
      "Your parking session is about to end. Avoid violations!",
    );
  }

  void _schedule(DateTime time, String title, String body) {
    LocalNotificationService.scheduleReminder(
      id: time.hashCode,
      title: title,
      body: body,
      scheduledDate: time,
    );
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

    // Start pulsing if less than 15 minutes left
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

  void _handleChatWithOfficer() async {
    final chatService = ChatService();
    setState(() => isLoading = true);
    try {
      // Create or find an existing conversation for this session
      final result = await chatService.createConversation(
        subject:
            'Chat about session ${widget.session.vehiclePlate} at ${widget.session.zoneName}',
        category: 'parking',
        priority: 'medium',
      );

      if (mounted) {
        if (result['success']) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ChatDetailScreen(conversation: result['data']),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to start chat'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'Parking Session',
      currentIndex: -1, // Not a primary tab
      onTabChanged: (index) {
        final homeState = context.findAncestorStateOfType<HomeScreenState>();
        if (homeState != null) {
          homeState.navigateToTab(index);
          Navigator.pop(context);
        }
      },
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
              if (_distance != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.directions_walk,
                        size: 14,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_distance!.toStringAsFixed(0)}m to vehicle',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Vehicle: ${widget.session.vehiclePlate}',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              if (_localPhotoPath != null)
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_localPhotoPath!),
                        height: 100,
                        width: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Saved Spot Photo',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              const SizedBox(height: 30),
              // Timer Circle
              ScaleTransition(
                scale: _remaining.inMinutes < 15
                    ? _pulseAnimation
                    : const AlwaysStoppedAnimation(1.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 240,
                      height: 240,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0.0,
                          end: _totalDuration.inSeconds > 0
                              ? _remaining.inSeconds / _totalDuration.inSeconds
                              : 0.0,
                        ),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, value, child) =>
                            CircularProgressIndicator(
                              value: value,
                              strokeWidth: 12,
                              strokeCap: StrokeCap.round,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _remaining.inMinutes < 15
                                    ? Colors.red
                                    : AppTheme.primaryColor,
                              ),
                            ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _remaining.inMinutes < 15 ? 'HURRY UP!' : 'TIME LEFT',
                          style: TextStyle(
                            letterSpacing: 2,
                            color: _remaining.inMinutes < 15
                                ? Colors.red
                                : Colors.grey,
                            fontWeight: _remaining.inMinutes < 15
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(opacity: animation, child: child),
                          child: Text(
                            _formatDuration(_remaining),
                            key: ValueKey(_remaining.inSeconds),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
              ElevatedButton.icon(
                onPressed: isLoading ? null : _handleChatWithOfficer,
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.chat_outlined),
                label: const Text('CHAT WITH OFFICER'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
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
