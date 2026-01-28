import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final bool showIcon;

  const StatusBadge({
    Key? key,
    required this.status,
    this.fontSize = 12,
    this.showIcon = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: config['backgroundColor'],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              config['icon'],
              size: fontSize + 2,
              color: config['textColor'],
            ),
            const SizedBox(width: 4),
          ],
          Text(
            config['text'],
            style: TextStyle(
              color: config['textColor'],
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'selesai':
        return {
          'backgroundColor': Colors.teal.shade100,
          'textColor': Colors.teal.shade900,
          'icon': Icons.done_outline,
          'text': 'Selesai',
        };
      case 'diterima':
        return {
          'backgroundColor': Colors.blue.shade100,
          'textColor': Colors.blue.shade900,
          'icon': Icons.check_circle_outline,
          'text': 'Diterima',
        };
      case 'menunggu':
        return {
          'backgroundColor': Colors.orange.shade100,
          'textColor': Colors.orange.shade900,
          'icon': Icons.schedule,
          'text': 'Menunggu',
        };
      case 'ditolak':
        return {
          'backgroundColor': Colors.red.shade100,
          'textColor': Colors.red.shade900,
          'icon': Icons.cancel_outlined,
          'text': 'Ditolak',
        };
      case 'ditolak':
        return {
          'backgroundColor': Colors.red.shade100,
          'textColor': Colors.red.shade900,
          'icon': Icons.cancel_outlined,
          'text': 'Ditolak',
        };
      case 'ditolak':
        return {
          'backgroundColor': Colors.red.shade100,
          'textColor': Colors.red.shade900,
          'icon': Icons.cancel_outlined,
          'text': 'Ditolak',
        };
      case 'berlangsung':
        return {
          'backgroundColor': Colors.purple.shade100,
          'textColor': Colors.purple.shade900,
          'icon': Icons.play_circle_outline,
          'text': 'Berlangsung',
        };
      case 'selesai':
        return {
          'backgroundColor': Colors.teal.shade100,
          'textColor': Colors.teal.shade900,
          'icon': Icons.done_outline,
          'text': 'Selesai',
        };
      case 'terkonfirmasi':
        return {
          'backgroundColor': Colors.green.shade100,
          'textColor': Colors.green.shade900,
          'icon': Icons.verified_outlined,
          'text': 'Terkonfirmasi',
        };
      case 'dibatalkan':
        return {
          'backgroundColor': Colors.grey.shade300,
          'textColor': Colors.grey.shade800,
          'icon': Icons.block,
          'text': 'Dibatalkan',
        };
      case 'kedaluwarsa':
        return {
          'backgroundColor': Colors.grey.shade300,
          'textColor': Colors.grey.shade800,
          'icon': Icons.access_time,
          'text': 'Kedaluwarsa',
        };
      default:
        return {
          'backgroundColor': Colors.grey.shade200,
          'textColor': Colors.grey.shade700,
          'icon': Icons.info_outline,
          'text': status,
        };
    }
  }
}
