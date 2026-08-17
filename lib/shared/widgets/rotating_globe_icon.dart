import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A premium 3D Glassmorphic Globe Badge widget.
/// Features a rich ocean-teal gradient sphere with specular glare reflection,
/// glassmorphic outer ring, and a gentle subtle floating animation (no dizzying spin).
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
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.gradientColors ?? [
      const Color(0xFF1E8B77), // Deep sea-green
      const Color(0xFF0D9488), // Rich teal
      const Color(0xFF14B8A6), // Bright aqua accent
    ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final floatY = math.sin(_controller.value * math.pi) * 3.0; // gentle 3px float
        final glowAlpha = 0.25 + 0.15 * math.sin(_controller.value * math.pi);

        return Transform.translate(
          offset: Offset(0, -floatY),
          child: Container(
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
                  color: colors[1].withValues(alpha: glowAlpha),
                  blurRadius: 18,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 1. Specular Gloss Reflection Curve (Top-Left Glare)
                Positioned(
                  top: 3,
                  left: 6,
                  right: 6,
                  height: widget.size * 0.38,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(widget.size / 2),
                        bottom: Radius.circular(widget.size / 4),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.45),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Glassmorphic Outer Border Ring
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.85),
                      width: 2.0,
                    ),
                  ),
                ),

                // 3. Crisp High-Resolution Language/Globe Icon
                Center(
                  child: Icon(
                    Icons.translate_rounded,
                    size: widget.size * 0.48,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        color: Colors.black38,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
