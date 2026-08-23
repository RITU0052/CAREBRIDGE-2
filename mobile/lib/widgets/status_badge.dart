import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum StatusBadgeType {
  upcoming,
  confirmed,
  highAlert,
  warning,
  success,
  pending,
  info,
  neutral,
}

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeType type;
  final IconData? icon;
  final EdgeInsetsGeometry padding;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusBadgeType.info,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  factory StatusBadge.fromStatus(String status) {
    final s = status.toLowerCase();
    if (s.contains('upcoming') || s.contains('schedule')) {
      return StatusBadge(label: status, type: StatusBadgeType.upcoming);
    } else if (s.contains('confirm') || s.contains('active') || s.contains('verified') || s.contains('in stock')) {
      return StatusBadge(label: status, type: StatusBadgeType.confirmed);
    } else if (s.contains('high') || s.contains('emergency') || s.contains('out of stock')) {
      return StatusBadge(label: status, type: StatusBadgeType.highAlert);
    } else if (s.contains('warning') || s.contains('low') || s.contains('pending')) {
      return StatusBadge(label: status, type: StatusBadgeType.warning);
    }
    return StatusBadge(label: status, type: StatusBadgeType.info);
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (type) {
      case StatusBadgeType.upcoming:
      case StatusBadgeType.info:
        bg = const Color(0xFFEEF2FF);
        fg = const Color(0xFF4F46E5);
        break;
      case StatusBadgeType.confirmed:
      case StatusBadgeType.success:
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
        break;
      case StatusBadgeType.highAlert:
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        break;
      case StatusBadgeType.warning:
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFD97706);
        break;
      case StatusBadgeType.pending:
        bg = const Color(0xFFF5F3FF);
        fg = const Color(0xFF7C3AED);
        break;
      case StatusBadgeType.neutral:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
