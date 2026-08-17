import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A realistic 3D rotating globe icon widget.
/// Renders a dynamic sphere with specular lighting, depth gradient,
/// and smooth 60fps rotating meridian and latitude grid lines.
class RotatingGlobeIcon extends StatefulWidget {
  final double size;
  final List<Color>? gradientColors;

  const RotatingGlobeIcon({
    super.key,
    this.size = 64.0,
    this.gradientColors,
  });

  @override
  State<RotatingGlobeIcon> createState() => _RotatingGlobeIconState();
}

class _RotatingGlobeIconState extends State<RotatingGlobeIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.gradientColors ?? [
      const Color(0xFF2E8B77),
      const Color(0xFF14B8A6),
    ];

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _GlobePainter(
              rotationProgress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _GlobePainter extends CustomPainter {
  final double rotationProgress;

  _GlobePainter({required this.rotationProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // 1. Sphere 3D Specular Highlight & Depth Overlay
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.85,
        colors: [
          Colors.white.withValues(alpha: 0.45),
          Colors.white.withValues(alpha: 0.10),
          Colors.black.withValues(alpha: 0.25),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, highlightPaint);

    // Outer atmosphere ring
    final atmospherePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.85);

    canvas.drawCircle(center, radius, atmospherePaint);

    // 2. Latitude & Longitude Grid Lines (rotating)
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Colors.white.withValues(alpha: 0.90)
      ..strokeCap = StrokeCap.round;

    // Clip to sphere circle
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius - 1)));

    // Draw Latitudes (horizontal rings)
    for (double yRatio in [-0.6, -0.25, 0.0, 0.25, 0.6]) {
      final y = center.dy + yRatio * radius;
      final rx = math.sqrt(radius * radius - (yRatio * radius) * (yRatio * radius));
      final ry = rx * 0.32;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(center.dx, y), width: rx * 2, height: ry * 2),
        gridPaint..color = Colors.white.withValues(alpha: yRatio == 0.0 ? 0.95 : 0.65),
      );
    }

    // Draw Rotating Longitudes (vertical meridians shifting dynamically)
    final angleOffset = rotationProgress * math.pi * 2;
    for (int i = 0; i < 8; i++) {
      final meridianAngle = angleOffset + (i * math.pi / 4);
      final sinVal = math.sin(meridianAngle);
      final cosVal = math.cos(meridianAngle);

      // Only draw meridians facing front (cosVal > 0)
      if (cosVal > 0) {
        final rx = (radius * sinVal).abs();
        final alpha = (cosVal * 0.95).clamp(0.2, 0.95);
        gridPaint.color = Colors.white.withValues(alpha: alpha);

        final rect = Rect.fromCenter(
          center: center,
          width: rx * 2,
          height: radius * 2,
        );
        canvas.drawOval(rect, gridPaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GlobePainter oldDelegate) {
    return oldDelegate.rotationProgress != rotationProgress;
  }
}
