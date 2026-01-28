import 'package:flutter/material.dart';
import 'dart:async';

/// Beautiful centered notification dialog
class BeautifulNotification {
  static Future<dynamic> show(
    BuildContext context, {
    required String title,
    required String message,
    required NotificationType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (BuildContext context) {
        // Auto dismiss after duration
        Timer(duration, () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });

        return _NotificationDialog(title: title, message: message, type: type);
      },
    );
  }
}

enum NotificationType { success, error, warning, info }

class _NotificationDialog extends StatefulWidget {
  final String title;
  final String message;
  final NotificationType type;

  const _NotificationDialog({
    required this.title,
    required this.message,
    required this.type,
  });

  @override
  State<_NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<_NotificationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColor() {
    switch (widget.type) {
      case NotificationType.success:
        return Colors.green;
      case NotificationType.error:
        return Colors.red;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.info:
        return Colors.blue;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.info:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final icon = _getIcon();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with circular background
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 50, color: color),
                ),
                // Close button (X) at top right
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.grey[400]),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),

                // Title
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Message
                Text(
                  widget.message,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Progress indicator (optional)
                SizedBox(
                  width: 60,
                  child: LinearProgressIndicator(
                    backgroundColor: color.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
