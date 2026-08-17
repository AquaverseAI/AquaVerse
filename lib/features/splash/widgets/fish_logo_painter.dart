import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Translucent glass-style logo mark widget.
/// Renders a translucent glass-style stylized fish in side profile in a leaping
/// upward pose, set inside a rounded-square backdrop card using the locked gradient
/// palette (`deepNavy` -> `seaGreen` -> `brightMint`).
class FishLogoWidget extends StatelessWidget {
  final double size;

  const FishLogoWidget({
    super.key,
    this.size = 124.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.deepNavy,
            AppColors.seaGreen,
            AppColors.brightMint,
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brightMint.withValues(alpha: 0.4),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.deepNavy.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.26),
        child: Stack(
          children: [
            // Glass reflection radial glow overlay
            Positioned(
              top: -size * 0.25,
              left: -size * 0.25,
              child: Container(
                width: size * 0.85,
                height: size * 0.85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.35),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Custom Painted Leaping Fish Emblem
            Center(
              child: CustomPaint(
                size: Size(size * 0.62, size * 0.62),
                painter: LeapingFishGlassPainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Painter rendering the translucent glass stylized fish leaping upward in side profile.
class LeapingFishGlassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Translucent Teal-to-Deep-Navy Body Paint
    final Paint bodyPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, h),
        Offset(w, 0),
        [
          AppColors.paleSky.withValues(alpha: 0.95),
          Colors.white.withValues(alpha: 0.92),
          AppColors.brightMint.withValues(alpha: 0.88),
        ],
        [0.0, 0.5, 1.0],
      )
      ..style = PaintingStyle.fill;

    final Paint finPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, h),
        Offset(w * 0.5, 0),
        [
          AppColors.brightMint.withValues(alpha: 0.9),
          AppColors.paleSky.withValues(alpha: 0.75),
        ],
      )
      ..style = PaintingStyle.fill;

    final Paint accentLinePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, h),
        Offset(w, 0),
        [
          AppColors.deepNavy.withValues(alpha: 0.7),
          AppColors.seaGreen.withValues(alpha: 0.85),
        ],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    // Leaping Fish Body Path (curved upward pose)
    final Path fishBody = Path();
    fishBody.moveTo(w * 0.15, h * 0.78);
    fishBody.cubicTo(
      w * 0.35,
      h * 0.85,
      w * 0.75,
      h * 0.65,
      w * 0.88,
      h * 0.22,
    );
    fishBody.cubicTo(
      w * 0.75,
      h * 0.12,
      w * 0.42,
      h * 0.22,
      w * 0.15,
      h * 0.78,
    );
    canvas.drawPath(fishBody, bodyPaint);

    // Spread Tail Fin
    final Path tailFin = Path();
    tailFin.moveTo(w * 0.15, h * 0.78);
    tailFin.quadraticBezierTo(w * 0.04, h * 0.88, w * 0.02, h * 0.96);
    tailFin.quadraticBezierTo(w * 0.18, h * 0.88, w * 0.15, h * 0.78);
    tailFin.quadraticBezierTo(w * 0.08, h * 0.68, w * 0.03, h * 0.62);
    tailFin.quadraticBezierTo(w * 0.16, h * 0.74, w * 0.15, h * 0.78);
    canvas.drawPath(tailFin, finPaint);

    // Dorsal Fin
    final Path dorsalFin = Path();
    dorsalFin.moveTo(w * 0.48, h * 0.32);
    dorsalFin.quadraticBezierTo(w * 0.52, h * 0.12, w * 0.62, h * 0.18);
    dorsalFin.quadraticBezierTo(w * 0.58, h * 0.35, w * 0.48, h * 0.32);
    canvas.drawPath(dorsalFin, finPaint);

    // Pectoral Fin
    final Path pectoralFin = Path();
    pectoralFin.moveTo(w * 0.55, h * 0.55);
    pectoralFin.quadraticBezierTo(w * 0.45, h * 0.68, w * 0.38, h * 0.72);
    pectoralFin.quadraticBezierTo(w * 0.52, h * 0.62, w * 0.55, h * 0.55);
    canvas.drawPath(pectoralFin, finPaint);

    // Aerodynamic Body Accent Line
    final Path bodyLine = Path();
    bodyLine.moveTo(w * 0.25, h * 0.72);
    bodyLine.quadraticBezierTo(w * 0.52, h * 0.55, w * 0.78, h * 0.30);
    canvas.drawPath(bodyLine, accentLinePaint);

    // Eye Detail
    final Paint eyePaint = Paint()
      ..color = AppColors.deepNavy.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.76, h * 0.28), w * 0.035, eyePaint);

    final Paint eyeShine = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.77, h * 0.27), w * 0.012, eyeShine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
