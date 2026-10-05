import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'app_card.dart';
import 'speaker_button.dart';

/// ActionCard Component (PRD-AV-04).
/// Recommended daily farmer action with integrated TTS Speaker button.
/// Matches Light Pastel Design System (Standard or Healthy card based on completion).
class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? timeText;
  final VoidCallback? onTap;
  final bool isCompleted;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.timeText,
    this.onTap,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      type: isCompleted ? CardType.healthy : CardType.standard,
      onTap: onTap,
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          // Icon circle
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? AppColors.green600.withValues(alpha: 0.12)
                  : AppColors.primary100,
            ),
            child: Icon(
              icon,
              color: isCompleted ? AppColors.green600 : AppColors.primary700,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
                if (timeText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    timeText!,
                    style: TextStyle(fontSize: 12, color: isCompleted ? AppColors.green600 : AppColors.primary700, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          // TTS
          SpeakerButton(textToSpeak: '$title. ${subtitle ?? ""}'),
          const SizedBox(width: 4),
          // Indicator
          Icon(
            isCompleted ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
            size: 16,
            color: isCompleted ? AppColors.green600 : AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
