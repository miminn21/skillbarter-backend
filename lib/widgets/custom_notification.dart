import 'package:flutter/material.dart';
import 'dart:ui';

class CustomNotification {
  static void show(
    BuildContext context, {
    required String message,
    required NotificationType type,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _NotificationWidget(
        message: message,
        type: type,
        onDismiss: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message: message, type: NotificationType.success);
  }

  static void showError(BuildContext context, String message) {
    show(context, message: message, type: NotificationType.error);
  }

  static void showInfo(BuildContext context, String message) {
    show(context, message: message, type: NotificationType.info);
  }

  static void showWarning(BuildContext context, String message) {
    show(context, message: message, type: NotificationType.warning);
  }
}

enum NotificationType { success, error, info, warning }

class _NotificationWidget extends StatefulWidget {
  final String message;
  final NotificationType type;
  final VoidCallback onDismiss;

  const _NotificationWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

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
        return const Color(0xFF4CAF50);
      case NotificationType.error:
        return const Color(0xFFF44336);
      case NotificationType.info:
        return const Color(0xFF2196F3);
      case NotificationType.warning:
        return const Color(0xFFFF9800);
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.info:
        return Icons.info_outline;
      case NotificationType.warning:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Backdrop blur
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
        ),
        // Centered notification
        Center(
          child: Material(
            color: Colors.transparent,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getColor().withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_getIcon(), size: 48, color: _getColor()),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _getTitle(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _getColor(),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.message,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getTitle() {
    switch (widget.type) {
      case NotificationType.success:
        return 'Berhasil!';
      case NotificationType.error:
        return 'Gagal!';
      case NotificationType.info:
        return 'Info';
      case NotificationType.warning:
        return 'Peringatan';
    }
  }
}
