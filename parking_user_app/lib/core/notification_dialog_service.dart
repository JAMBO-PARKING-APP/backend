import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parking_user_app/features/settings/providers/settings_provider.dart';
import 'package:parking_user_app/core/utils/currency_formatter.dart';

/// Service to show in-app notification dialogs
class NotificationDialogService {
  static final NotificationDialogService _instance =
      NotificationDialogService._internal();
  factory NotificationDialogService() => _instance;
  NotificationDialogService._internal();

  BuildContext? _context;

  /// Set the current context for showing dialogs
  void setContext(BuildContext context) {
    _context = context;
  }

  /// Show notification dialog based on notification data
  void showNotificationDialog(Map<String, dynamic> data) {
    if (_context == null) return;

    final type = data['type'] ?? data['event'];
    final showDialog =
        data['show_dialog'] == 'true' || data['show_dialog'] == true;

    if (!showDialog) return;

    switch (type) {
      case 'parking_started':
        _showParkingStartedDialog(data);
        break;
      case 'payment_success':
        _showPaymentSuccessDialog(data);
        break;
      case 'wallet_refund':
        _showWalletRefundDialog(data);
        break;
      case 'reservation_confirmed':
        _showReservationConfirmedDialog(data);
        break;
      case 'parking_ended':
        _showParkingEndedDialog(data);
        break;
      case 'parking_expiring':
        _showParkingExpiringDialog(data);
        break;
      case 'custom_admin':
        _showCustomAdminDialog(data);
        break;
      case 'campaign':
        _showCampaignDialog(data);
        break;
      case 'payment_failed':
        _showPaymentFailedDialog(data);
        break;
      case 'violation_issued':
        _showViolationIssuedDialog(data);
        break;
      case 'payment_refund':
        _showPaymentRefundDialog(data);
        break;
      case 'reservation_cancelled':
        _showReservationCancelledDialog(data);
        break;
      default:
        _showGenericDialog(data);
        break;
    }
  }

  void _showCampaignDialog(Map<String, dynamic> data) {
    final title = data['title'] ?? 'Special Offer';
    final body = data['body'] ?? '';
    final imageUrl = data['image_url'];

    _showCustomDialog(
      title: title,
      message: body,
      icon: Icons.local_offer,
      iconColor: Colors.deepPurple,
      primaryButtonText: 'Claim Now',
      onPrimaryPressed: () => Navigator.of(_context!).pop(),
      secondaryButtonText: 'Dismiss',
      onSecondaryPressed: () => Navigator.of(_context!).pop(),
      imageUrl: imageUrl,
    );
  }

  void _showParkingStartedDialog(Map<String, dynamic> data) {
    final slotCode = data['slot_code'] ?? 'N/A';

    _showCustomDialog(
      title: '🅿️ Parking Started',
      message: 'Your parking session has started!\nSlot: $slotCode',
      icon: Icons.check_circle,
      iconColor: Colors.green,
      primaryButtonText: 'OK',
      onPrimaryPressed: () => Navigator.of(_context!).pop(),
    );
  }

  void _showPaymentSuccessDialog(Map<String, dynamic> data) {
    final amount = data['amount'] ?? '0';

    final settings = Provider.of<SettingsProvider>(_context!, listen: false);
    final formattedAmount = CurrencyFormatter.formatCurrency(
      double.tryParse(amount.toString()) ?? 0.0,
      settings.countryConfig,
    );

    _showCustomDialog(
      title: '✅ Payment Successful',
      message: 'Your payment of $formattedAmount was successful.',
      icon: Icons.check_circle,
      iconColor: Colors.green,
      primaryButtonText: 'OK',
      onPrimaryPressed: () => Navigator.of(_context!).pop(),
    );
  }

  void _showWalletRefundDialog(Map<String, dynamic> data) {
    final amount = data['amount'] ?? '0';

    final settings = Provider.of<SettingsProvider>(_context!, listen: false);
    final formattedAmount = CurrencyFormatter.formatCurrency(
      double.tryParse(amount.toString()) ?? 0.0,
      settings.countryConfig,
    );

    _showCustomDialog(
      title: '💰 Wallet Refund',
      message:
          'You\'ve been refunded $formattedAmount for ending your parking session early.',
      icon: Icons.account_balance_wallet,
      iconColor: Colors.green,
      primaryButtonText: 'OK',
      onPrimaryPressed: () => Navigator.of(_context!).pop(),
    );
  }

  void _showReservationConfirmedDialog(Map<String, dynamic> data) {
    final slotCode = data['slot_code'] ?? 'N/A';
    final zoneName = data['zone_name'] ?? 'Parking Zone';

    _showCustomDialog(
      title: '✅ Reservation Confirmed',
      message: 'Your reservation at $zoneName is confirmed!\nSlot: $slotCode',
      icon: Icons.event_available,
      iconColor: Colors.green,
      primaryButtonText: 'OK',
      onPrimaryPressed: () => Navigator.of(_context!).pop(),
    );
  }

  void _showPaymentFailedDialog(Map<String, dynamic> data) {
    final reason = data['reason'] ?? 'Unknown error';

    _showCustomDialog(
      title: '❌ Payment Failed',
      message: 'Your payment could not be processed.\nReason: $reason',
      icon: Icons.error_outline,
      iconColor: Colors.red,
      primaryButtonText: 'Try Again',
      onPrimaryPressed: () => Navigator.of(_context!).pop(),
    );
  }

  void _showViolationIssuedDialog(Map<String, dynamic> data) {
    final fineAmount = data['fine_amount'] ?? '0';

    _showCustomDialog(
      title: '👮 Violation Issued',
      message:
          'A parking violation has been issued for your vehicle.\nFine Amount: $fineAmount',
      icon: Icons.warning_amber_rounded,
      iconColor: Colors.red,
      primaryButtonText: 'View Details',
      onPrimaryPressed: () {
        Navigator.of(_context!).pop();
      },
      secondaryButtonText: 'Dismiss',
      onSecondaryPressed: () => Navigator.of(_context!).pop(),
    );
  }

  void _showPaymentRefundDialog(Map<String, dynamic> data) {
    final amount = data['amount'] ?? '0';

    _showCustomDialog(
      title: '💰 Refund Processed',
      message: 'A refund of $amount has been processed successfully.',
      icon: Icons.replay_circle_filled,
      iconColor: Colors.green,
      primaryButtonText: 'Great',
      onPrimaryPressed: () => Navigator.of(_context!).pop(),
    );
  }

  void _showReservationCancelledDialog(Map<String, dynamic> data) {
    _showCustomDialog(
      title: '🚫 Reservation Cancelled',
      message: 'Your parking reservation has been cancelled.',
      icon: Icons.cancel,
      iconColor: Colors.red,
      primaryButtonText: 'OK',
      onPrimaryPressed: () => Navigator.of(_context!).pop(),
    );
  }

  void _showCustomAdminDialog(Map<String, dynamic> data) {
    final title = data['title'] ?? 'Notification';
    final body = data['body'] ?? '';
    final priority = data['priority'] ?? 'medium';

    // Choose icon and color based on priority
    IconData icon;
    Color iconColor;

    switch (priority) {
      case 'high':
        icon = Icons.priority_high;
        iconColor = Colors.red;
        break;
      case 'low':
        icon = Icons.info_outline;
        iconColor = Colors.blue;
        break;
      default: // medium
        icon = Icons.notifications_active;
        iconColor = Colors.orange;
    }

    _showCustomDialog(
      title: title,
      message: body,
      icon: icon,
      iconColor: iconColor,
      primaryButtonText: 'Got it',
      onPrimaryPressed: () => Navigator.of(_context!).pop(),
    );
  }

  void _showParkingEndedDialog(Map<String, dynamic> data) {
    final finalCost = data['final_cost'] ?? '0';

    final settings = Provider.of<SettingsProvider>(_context!, listen: false);
    final formattedCost = CurrencyFormatter.formatCurrency(
      double.tryParse(finalCost.toString()) ?? 0.0,
      settings.countryConfig,
    );

    _showCustomDialog(
      title: '🅿️ Parking Session Ended',
      message: 'Your parking session has ended.\nTotal cost: $formattedCost',
      icon: Icons.local_parking,
      iconColor: Colors.blue,
      primaryButtonText: 'View Details',
      onPrimaryPressed: () {
        Navigator.of(_context!).pop();
        // Navigate to parking history
        // Navigator.pushNamed(_context!, '/parking-history');
      },
      secondaryButtonText: 'OK',
      onSecondaryPressed: () => Navigator.of(_context!).pop(),
    );
  }

  void _showParkingExpiringDialog(Map<String, dynamic> data) {
    final minutesRemaining = data['minutes_remaining'] ?? '0';

    _showCustomDialog(
      title: '⏰ Parking Expiring Soon',
      message: 'Your parking session will expire in $minutesRemaining minutes.',
      icon: Icons.timer,
      iconColor: Colors.orange,
      primaryButtonText: 'Extend Session',
      onPrimaryPressed: () {
        Navigator.of(_context!).pop();
        // Navigate to extend parking
        // Navigator.pushNamed(_context!, '/extend-parking', arguments: data['session_id']);
      },
      secondaryButtonText: 'Dismiss',
      onSecondaryPressed: () => Navigator.of(_context!).pop(),
    );
  }

  void _showGenericDialog(Map<String, dynamic> data) {
    final title = data['title'] ?? 'Notification';
    final body = data['body'] ?? '';

    _showCustomDialog(
      title: title,
      message: body,
      icon: Icons.notifications,
      iconColor: Colors.blue,
      primaryButtonText: 'OK',
      onPrimaryPressed: () => Navigator.of(_context!).pop(),
    );
  }

  void _showCustomDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required String primaryButtonText,
    required VoidCallback onPrimaryPressed,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
    String? imageUrl,
  }) {
    if (_context == null) return;

    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image if provided
              if (imageUrl != null && imageUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),

              // Icon
              if (imageUrl == null || imageUrl.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 48, color: iconColor),
                ),
              const SizedBox(height: 16),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                message,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            // Secondary button (if provided)
            if (secondaryButtonText != null && onSecondaryPressed != null)
              TextButton(
                onPressed: onSecondaryPressed,
                child: Text(
                  secondaryButtonText,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),

            // Primary button
            ElevatedButton(
              onPressed: onPrimaryPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: iconColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                primaryButtonText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
