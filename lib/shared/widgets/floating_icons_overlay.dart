import 'package:flutter/material.dart';

/// Renders dark, high-contrast floating outline icons (Water drop, Growth chart, Fish, Sprout 1, Sprout 2)
/// over the floating constellation nodes on the background image.
class FloatingIconsOverlay extends StatelessWidget {
  final Color iconColor;

  const FloatingIconsOverlay({
    super.key,
    this.iconColor = const Color(0xFF073248), // Dark Navy/Teal for maximum contrast
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // Position nodes matching the background graphic constellation layout
        final nodes = [
          // 1. Top Node: Water Drop
          _IconNodeData(
            offset: Offset(w * 0.77, h * 0.20),
            radius: 22,
            icon: Icons.water_drop_rounded,
          ),
          // 2. Left-Upper Node: Growth Chart
          _IconNodeData(
            offset: Offset(w * 0.60, h * 0.29),
            radius: 22,
            icon: Icons.trending_up_rounded,
          ),
          // 3. Right Node: Fish / Yield
          _IconNodeData(
            offset: Offset(w * 0.96, h * 0.30),
            radius: 20,
            icon: Icons.phishing_rounded,
          ),
          // 4. Center Node: Plant Sprout 1
          _IconNodeData(
            offset: Offset(w * 0.81, h * 0.37),
            radius: 24,
            icon: Icons.eco_rounded,
          ),
          // 5. Bottom-Center Node: Plant Sprout 2
          _IconNodeData(
            offset: Offset(w * 0.70, h * 0.44),
            radius: 22,
            icon: Icons.grass_rounded,
          ),
        ];

        return Stack(
          children: nodes.map((node) {
            return Positioned(
              left: node.offset.dx - node.radius,
              top: node.offset.dy - node.radius,
              child: Container(
                width: node.radius * 2,
                height: node.radius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF073248).withValues(alpha: 0.12),
                  border: Border.all(
                    color: iconColor,
                    width: 2.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                    const BoxShadow(
                      color: Colors.white,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  node.icon,
                  size: node.radius * 1.0,
                  color: iconColor,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _IconNodeData {
  final Offset offset;
  final double radius;
  final IconData icon;

  const _IconNodeData({
    required this.offset,
    required this.radius,
    required this.icon,
  });
}
