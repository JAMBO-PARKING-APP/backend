import 'package:flutter/material.dart';
import 'package:parking_user_app/core/app_theme.dart';

class DialogHelper {
  static Future<void> showSuccess(
    BuildContext context,
    String title,
    String message,
  ) => _show(context, title, message, AppTheme.successColor);

  static Future<void> showError(
    BuildContext context,
    String title,
    String message,
  ) => _show(context, title, message, AppTheme.errorColor);

  static Future<void> _show(
    BuildContext context,
    String title,
    String message,
    Color color,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
