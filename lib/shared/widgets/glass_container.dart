import 'dart:ui';
import 'package:flutter/material.dart';

/// Reusable Glassmorphism 40% container widget.
/// Wraps content in a ClipRRect + BackdropFilter blur + 40% translucent surface
/// with a frosted white glass border and soft drop shadow.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double opacity;
  final double blur;
  final double borderRadius;
  final Color fillColor;
  final Border? border;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final List<BoxShadow>? boxShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.opacity = 0.40,
    this.blur = 12.0,
    this.borderRadius = 16.0,
    this.fillColor = Colors.white,
    this.border,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = border ??
        Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: 1.2,
        );

    final defaultShadows = boxShadow ?? [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 16,
        spreadRadius: 0,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.30),
        blurRadius: 8,
        spreadRadius: -2,
        offset: const Offset(0, -1),
      ),
    ];

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: defaultShadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: fillColor.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: effectiveBorder,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
