import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parking_user_app/features/parking/models/parking_session_model.dart';
import 'package:parking_user_app/features/parking/providers/parking_provider.dart';
import 'package:parking_user_app/core/app_theme.dart';
import 'package:parking_user_app/core/dialog_service.dart';
import 'package:parking_user_app/features/parking/screens/qr_code_view_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:parking_user_app/features/auth/providers/auth_provider.dart';

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
  bool _isLoading = false;
  double? _savedLat;
  double? _savedLng;

  @override
  void initState() {
    super.initState();
    _calculateTotalDuration();
    _calculateRemaining();
    _loadSavedData();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _calculateRemaining();
      }
    });
  }

  Future<void> _loadSavedData() async {
    final info = await context.read<ParkingProvider>().getSavedSpot(widget.session.id);
    if (mounted) {
      setState(() {
        _savedLat = info['lat'];
        _savedLng = info['lng'];
      });
    }
  }

  @override
  void didUpdateWidget(ActiveSessionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.session.endTime != oldWidget.session.endTime ||
        widget.session.id != oldWidget.session.id) {
      _calculateTotalDuration();
      _calculateRemaining();
    }
  }

  void _calculateTotalDuration() {
    if (widget.session.endTime == null) {
      _totalDuration = Duration.zero;
      return;
    }
    _totalDuration = widget.session.endTime!.difference(widget.session.startTime);
  }

  void _calculateRemaining() {
    if (widget.session.endTime == null) {
      setState(() => _remaining = Duration.zero);
      return;
    }
    final now = DateTime.now();
    final diff = widget.session.endTime!.difference(now);
    final newVal = diff.isNegative ? Duration.zero : diff;
    
    if (newVal.inSeconds != _remaining.inSeconds) {
      setState(() {
        _remaining = newVal;
      });
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
        content: const Text('Are you sure you want to end this parking session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('End Session'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      final success = await context.read<ParkingProvider>().endParking(widget.session.id);
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          DialogService.showSuccessDialog(
            title: 'Session Ended',
            message: 'Your parking session has been stopped successfully.',
          );
        }
      }
    }
  }

  void _handleExtendParking() {
    int additionalHours = 1;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAdjustButton(
                      icon: Icons.remove,
                      onTap: additionalHours > 1 ? () => setModalState(() => additionalHours--) : null,
                    ),
                    const SizedBox(width: 32),
                    Text(
                      '$additionalHours hr${additionalHours > 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: 32),
                    _buildAdjustButton(
                      icon: Icons.add,
                      onTap: () => setModalState(() => additionalHours++),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Additional Cost:', style: TextStyle(color: Colors.white70)),
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        final hourlyRate = widget.session.hourlyRate;
                        final total = hourlyRate * additionalHours;
                        final currency = auth.user?.countryDetails?.currencySymbol ?? 'UGX';
                        return Text(
                          '$currency $total',
                          style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 18),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    final auth = context.read<AuthProvider>();
                    final hourlyRate = widget.session.hourlyRate;
                    final total = hourlyRate * additionalHours;
                    
                    if ((auth.user?.walletBalance ?? 0) < total) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Insufficient wallet balance. Please top up.')),
                      );
                      return;
                    }

                    setState(() => _isLoading = true);
                    final success = await context.read<ParkingProvider>().extendParking(widget.session.id, additionalHours);
                    if (mounted) {
                      setState(() => _isLoading = false);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                      if (success) {
                        DialogService.showSuccessDialog(
                          title: 'Extended!',
                          message: 'Parking session extended by $additionalHours hour(s).',
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: AppTheme.primaryDark,
                  ),
                  child: const Text('PAY & EXTEND NOW', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdjustButton({required IconData icon, VoidCallback? onTap}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 32),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _handleSaveSpot() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        await context.read<ParkingProvider>().saveSpot(
          widget.session.id,
          position.latitude,
          position.longitude,
        );
        if (!mounted) return;
        setState(() {
          _savedLat = position.latitude;
          _savedLng = position.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parking location saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save location: $e')),
        );
      }
    }
  }

  void _handleLocateCar() async {
    if (_savedLat != null && _savedLng != null) {
      final url = 'https://www.google.com/maps/search/?api=1&query=$_savedLat,$_savedLng';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved location found. Tap "Save Spot" first.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLowTime = _remaining.inMinutes < 15 && _remaining.inSeconds > 0;
    
    double progress = 0.0;
    if (_totalDuration.inSeconds > 0) {
      progress = (_remaining.inSeconds / _totalDuration.inSeconds).clamp(0.0, 1.0);
    }

    return Scaffold(
      backgroundColor: isLowTime ? AppTheme.errorColor : AppTheme.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'ACTIVE SESSION',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Removed back button to "pin" user
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Zone Info Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.location_on, color: AppTheme.accentColor, size: 28),
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
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Vehicle: ${widget.session.vehiclePlate}',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 50),
                    
                    // Countdown Section
                    Text(
                      'REMAINING TIME',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _formatDuration(_remaining),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 10,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isLowTime ? Colors.white : AppTheme.accentColor,
                              boxShadow: [
                                if (!isLowTime)
                                  BoxShadow(
                                    color: AppTheme.accentColor.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Inline QR Code
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: widget.session.id,
                        version: QrVersions.auto,
                        size: 180.0,
                        gapless: false,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppTheme.primaryDark,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Scan to Verify',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Quick Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionIcon(
                          icon: Icons.qr_code_2_rounded,
                          label: 'QR Code',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => QRCodeViewScreen(session: widget.session)),
                          ),
                        ),
                        _buildActionIcon(
                          icon: Icons.my_location_rounded,
                          label: 'Save Spot',
                          onTap: _handleSaveSpot,
                        ),
                        _buildActionIcon(
                          icon: Icons.directions_rounded,
                          label: 'Find Car',
                          onTap: _handleLocateCar,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 60),
                    
                    if (_isLoading)
                      const CircularProgressIndicator(color: Colors.white)
                    else ...[
                      ElevatedButton(
                        onPressed: _handleExtendParking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                          foregroundColor: AppTheme.primaryDark,
                          minimumSize: const Size(double.infinity, 64),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 0,
                        ),
                        child: const Text('EXTEND PARKING', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _handleEndParking,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          foregroundColor: Colors.white.withValues(alpha: 0.7),
                        ),
                        child: const Text('End Session Early', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcon({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
