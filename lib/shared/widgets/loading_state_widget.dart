import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// LoadingStateWidget — shimmer skeleton placeholders.
///
/// Use while FutureProviders load to give the user visual feedback
/// without showing blank screens. The shimmer is a static animated
/// gradient that does not require the `shimmer` package.
///
/// [count] controls how many skeleton card rows to display.
class LoadingStateWidget extends StatefulWidget {
  final int count;
  final LoadingLayout layout;

  const LoadingStateWidget({
    super.key,
    this.count = 3,
    this.layout = LoadingLayout.card,
  });

  @override
  State<LoadingStateWidget> createState() => _LoadingStateWidgetState();
}

class _LoadingStateWidgetState extends State<LoadingStateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _shimmer = Tween<double>(begin: 0.4, end: 0.85).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        return Column(
          children: List.generate(
            widget.count,
            (i) => _buildSkeleton(i),
          ),
        );
      },
    );
  }

  Widget _buildSkeleton(int index) {
    switch (widget.layout) {
      case LoadingLayout.card:
        return _cardSkeleton(index);
      case LoadingLayout.listTile:
        return _listTileSkeleton(index);
      case LoadingLayout.metric:
        return _metricSkeleton(index);
    }
  }

  Widget _cardSkeleton(int index) {
    return Container(
      margin: EdgeInsets.only(
        top: index == 0 ? 0 : AppSpacing.md,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _shimmerBox(40, 40, radius: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(null, 14, widthFactor: 0.6),
                    const SizedBox(height: AppSpacing.xs),
                    _shimmerBox(null, 12, widthFactor: 0.4),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _shimmerBox(null, 12, widthFactor: 0.9),
          const SizedBox(height: AppSpacing.xs),
          _shimmerBox(null, 12, widthFactor: 0.7),
        ],
      ),
    );
  }

  Widget _listTileSkeleton(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _shimmerBox(44, 44, radius: 8),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(null, 14, widthFactor: 0.5),
                const SizedBox(height: AppSpacing.xs),
                _shimmerBox(null, 12, widthFactor: 0.35),
              ],
            ),
          ),
          _shimmerBox(60, 24, radius: AppRadius.pill),
        ],
      ),
    );
  }

  Widget _metricSkeleton(int index) {
    return Container(
      margin: const EdgeInsets.only(
        top: AppSpacing.sm,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
    );
  }

  Widget _shimmerBox(
    double? width,
    double height, {
    double? widthFactor,
    double radius = AppRadius.sm,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedWidth = width ??
            (widthFactor != null
                ? constraints.maxWidth * widthFactor
                : double.infinity);

        return Container(
          width: resolvedWidth,
          height: height,
          decoration: BoxDecoration(
            color: Color.lerp(
              AppColors.border,
              AppColors.background,
              _shimmer.value,
            ),
            borderRadius: BorderRadius.circular(radius),
          ),
        );
      },
    );
  }
}

enum LoadingLayout { card, listTile, metric }

