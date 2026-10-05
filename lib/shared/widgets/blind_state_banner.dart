import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'speaker_button.dart';

/// BlindStateBanner Component (PRD-AV-04 Mandatory Constraint).
/// Rendered whenever `blind_state: true` or a `suppression_reason` is returned
/// by the backend. Never silently dropped.
class BlindStateBanner extends StatelessWidget {
  final String suppressionReason;
  final VoidCallback? onAddLogTap;

  const BlindStateBanner({
    super.key,
    required this.suppressionReason,
    this.onAddLogTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warningBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Alert Suppression Active',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.warning),
                ),
              ),
              SpeakerButton(textToSpeak: suppressionReason),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            suppressionReason,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          if (onAddLogTap != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAddLogTap,
                icon: const Icon(Icons.add_chart_rounded, size: 16),
                label: const Text('Add Pond Log Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
