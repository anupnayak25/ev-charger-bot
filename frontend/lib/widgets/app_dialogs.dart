import 'package:flutter/material.dart';

import '../services/app_error.dart';

class AppDialogs {
  static Future<void> showMessage(
    BuildContext context, {
    required String title,
    required String message,
    String okText = 'OK',
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(okText),
          ),
        ],
      ),
    );
  }

  static Future<void> showError(
    BuildContext context, {
    required AppError error,
    VoidCallback? onRetry,
  }) {
    final display = error.toDisplay();

    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(display.title),
        content: Text(display.message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                onRetry();
              },
              child: const Text('Try again'),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
