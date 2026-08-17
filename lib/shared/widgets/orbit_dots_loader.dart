import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A lightweight, reusable orbiting dual-dot loading indicator.
///
/// Features two dots orbiting 180° out of phase around a shared center point.
/// Built using native [Transform.translate] and trigonometric [sin]/[cos] offsets.
class OrbitDotsLoader extends StatefulWidget {
  final double size;
  final double dotSize;
  final Color color1;
  final Color color2;
  final Duration period;

  const OrbitDotsLoader({
    super.key,
    this.size = 48.0,
    this.dotSize = 12.0,
    this.color1 = AppColors.seaGreen,
    this.color2 = const Color(0x733FCCA6), // brightMint @ ~45% opacity
    this.period = const Duration(milliseconds: 1200),
  });

  @override
  State<OrbitDotsLoader> createState() => _OrbitDotsLoaderState();
}

class _OrbitDotsLoaderState extends State<OrbitDotsLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.period,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double radius = (widget.size - widget.dotSize) / 2.5;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double angle = _controller.value * math.pi * 2;

          // Dot 1 coordinates
          final double dx1 = math.cos(angle) * radius;
          final double dy1 = math.sin(angle) * radius;

          // Dot 2 coordinates (180° / pi radians out of phase)
          final double dx2 = math.cos(angle + math.pi) * radius;
          final double dy2 = math.sin(angle + math.pi) * radius;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Dot 1 (Solid)
              Transform.translate(
                offset: Offset(dx1, dy1),
                child: Container(
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    color: widget.color1,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color1.withValues(alpha: 0.3),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),

              // Dot 2 (Translucent)
              Transform.translate(
                offset: Offset(dx2, dy2),
                child: Container(
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    color: widget.color2,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
