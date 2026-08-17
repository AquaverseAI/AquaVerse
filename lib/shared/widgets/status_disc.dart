import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum PondStatusLevel {
  good,
  caution,
  critical,
}

/// StatusDisc Component (PRD-AV-04 Mandatory Constraint).
/// Icon-first status indicator — never shows a bare risk percentage or numeral
/// without a qualitative label (Good / Caution / Critical).
class StatusDisc extends StatelessWidget {
  final PondStatusLevel status;
  final String? customLabel;
  final double size;
  final bool showLabel;

  const StatusDisc({
    super.key,
    required this.status,
    this.customLabel,
    this.size = 40.0,
    this.showLabel = true,
  });

  Color get color {
    switch (status) {
      case PondStatusLevel.good:
        return AppColors.brightMint;
      case PondStatusLevel.caution:
        return const Color(0xFFF59E0B); // Amber
      case PondStatusLevel.critical:
        return const Color(0xFFEF4444); // Red
    }
  }

  IconData get icon {
    switch (status) {
      case PondStatusLevel.good:
        return Icons.check_circle_rounded;
      case PondStatusLevel.caution:
        return Icons.warning_rounded;
      case PondStatusLevel.critical:
        return Icons.error_rounded;
    }
  }

  String get labelText {
    if (customLabel != null) return customLabel!;
    switch (status) {
      case PondStatusLevel.good:
        return 'Good';
      case PondStatusLevel.caution:
        return 'Caution';
      case PondStatusLevel.critical:
        return 'Critical';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color, width: 2.0),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              size: size * 0.55,
              color: color,
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Text(
            labelText,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ],
    );
  }
}
