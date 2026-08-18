import 'dart:math' as math;
import 'package:flutter/material.dart';

/// AuroraAiOrb — Pixel-perfect AI Voice Assistant Animation.
///
/// Features:
/// - Multi-layered organic fluid morphing orb.
/// - Continuous Aurora color flow across 4 brand shades:
///   1. Teal Blue (#0E9488 / #14B8A6)
///   2. Sea Green (#2E8B77 / #35A58A)
///   3. Green (#24866F / #10B981)
///   4. Aqua Blue (#27AFC0 / #06B6D4)
/// - State-aware motion: Idle breathing, Listening expanding wave, Thinking concentric rotation.
class AuroraAiOrb extends StatefulWidget {
  final double size;
  final bool isListening;
  final bool isThinking;
  final VoidCallback? onTap;
  final Widget? child;

  const AuroraAiOrb({
    super.key,
    this.size = 160.0,
    this.isListening = false,
    this.isThinking = false,
    this.onTap,
    this.child,
  });

  @override
  State<AuroraAiOrb> createState() => _AuroraAiOrbState();
}

class _AuroraAiOrbState extends State<AuroraAiOrb>
    with TickerProviderStateMixin {
  late AnimationController _colorController;
  late AnimationController _morphController;
  late AnimationController _pulseController;

  static const List<Color> _auroraPalette = [
    Color(0xFF0E9488), // Teal Blue primary
    Color(0xFF14B8A6), // Teal Blue accent
    Color(0xFF2E8B77), // Sea Green
    Color(0xFF35A58A), // Sea Green bright
    Color(0xFF24866F), // Natural Green
    Color(0xFF10B981), // Emerald Green
    Color(0xFF27AFC0), // Aqua Blue
    Color(0xFF06B6D4), // Cyan Aqua
  ];

  @override
  void initState() {
    super.initState();
    // Continuous 2.5s aurora color sweep
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    // 1.0s quick fluid background wave animation
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    // 0.8s state pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _updateControllers();
  }

  @override
  void didUpdateWidget(AuroraAiOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isListening != widget.isListening ||
        oldWidget.isThinking != widget.isThinking) {
      _updateControllers();
    }
  }

  void _updateControllers() {
    if (widget.isListening) {
      _pulseController.repeat(reverse: true);
    } else if (widget.isThinking) {
      _pulseController.repeat();
    } else {
      _pulseController.stop();
      _pulseController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _colorController.dispose();
    _morphController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Color _getCurrentColor(double progress) {
    final count = _auroraPalette.length;
    final double scaled = (progress * count) % count;
    final int index1 = scaled.floor();
    final int index2 = (index1 + 1) % count;
    final double t = scaled - index1;
    return Color.lerp(_auroraPalette[index1], _auroraPalette[index2], t)!;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge(
            [_colorController, _morphController, _pulseController]),
        builder: (context, child) {
          final colorT = _colorController.value;
          final morphT = _morphController.value;
          final pulseT = _pulseController.value;

          final Color primaryAurora = _getCurrentColor(colorT);
          final Color secondaryAurora = _getCurrentColor((colorT + 0.33) % 1.0);
          final Color accentAurora = _getCurrentColor((colorT + 0.66) % 1.0);

          final double scaleFactor = widget.isListening
              ? 1.0 + (pulseT * 0.12)
              : (widget.isThinking ? 0.96 + (pulseT * 0.08) : 1.0);

          return Transform.scale(
            scale: scaleFactor,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Aurora Glow Ring
                  CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _AuroraGlowPainter(
                      color1: primaryAurora,
                      color2: secondaryAurora,
                      color3: accentAurora,
                      morphValue: morphT,
                      isListening: widget.isListening,
                      isThinking: widget.isThinking,
                    ),
                  ),

                  // Core Fluid Orb Layer
                  CustomPaint(
                    size: Size(widget.size * 0.72, widget.size * 0.72),
                    painter: _AuroraFluidOrbPainter(
                      color1: primaryAurora,
                      color2: secondaryAurora,
                      color3: accentAurora,
                      morphValue: morphT,
                    ),
                  ),

                  // Inner Child (Mic Icon or Status)
                  if (widget.child != null) widget.child!,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Custom Painter rendering the outer fluid Aurora glow rings & ripples
class _AuroraGlowPainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final Color color3;
  final double morphValue;
  final bool isListening;
  final bool isThinking;

  _AuroraGlowPainter({
    required this.color1,
    required this.color2,
    required this.color3,
    required this.morphValue,
    required this.isListening,
    required this.isThinking,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2;

    // Layer 1: Diffused Outer Aurora Halo
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color1.withValues(alpha: isListening ? 0.35 : 0.22),
          color2.withValues(alpha: 0.12),
          color3.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.60, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, baseRadius, haloPaint);

    // Layer 2: Fast & Fluid Organic Background Wave Rings
    final waveSpeeds = [1.0, 1.3, 1.6];
    final waveOffsets = [0.0, 0.33, 0.66];
    final waveAlphas = [0.75, 0.45, 0.25];
    final waveBaseRadii = [0.82, 0.90, 0.96];

    for (int waveIdx = 0; waveIdx < 3; waveIdx++) {
      final waveMorph = (morphValue * waveSpeeds[waveIdx] + waveOffsets[waveIdx]) % 1.0;
      final dynamicOffset = math.sin(waveMorph * 2 * math.pi) * (isListening ? 9.0 : 5.0);
      final waveRadius = (baseRadius * waveBaseRadii[waveIdx]) + dynamicOffset;

      final wavePaint = Paint()
        ..shader = SweepGradient(
          transform: GradientRotation(waveMorph * 2 * math.pi),
          colors: [
            color1.withValues(alpha: waveAlphas[waveIdx]),
            color2.withValues(alpha: waveAlphas[waveIdx] * 0.8),
            color3.withValues(alpha: waveAlphas[waveIdx] * 0.6),
            color1.withValues(alpha: waveAlphas[waveIdx]),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: waveRadius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = isListening ? 3.0 : 2.0;

      canvas.drawCircle(center, waveRadius, wavePaint);
    }

    // Layer 3: Thinking Orbiting Dots
    if (isThinking) {
      final dotPaint = Paint()..style = PaintingStyle.fill;
      for (int i = 0; i < 4; i++) {
        final dotAngle =
            (morphValue * 2 * math.pi * 2) + (i * math.pi / 2);
        final dotR = baseRadius * 0.86;
        final dotX = center.dx + dotR * math.cos(dotAngle);
        final dotY = center.dy + dotR * math.sin(dotAngle);

        dotPaint.color = (i % 2 == 0 ? color1 : color2).withValues(alpha: 0.85);
        canvas.drawCircle(Offset(dotX, dotY), 3.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraGlowPainter oldDelegate) => true;
}

/// Custom Painter rendering the core fluid morphing Aurora sphere
class _AuroraFluidOrbPainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final Color color3;
  final double morphValue;

  _AuroraFluidOrbPainter({
    required this.color1,
    required this.color2,
    required this.color3,
    required this.morphValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Rich Aurora Gradient Core
    final corePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        transform: GradientRotation(morphValue * 2 * math.pi),
        colors: [
          color1,
          color2,
          color3,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    // Draw fluid core shape
    canvas.drawCircle(center, radius, corePaint);

    // Top-left Specular Aurora Highlight
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.50),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
          center: Offset(center.dx - radius * 0.3, center.dy - radius * 0.3),
          radius: radius * 0.45));

    canvas.drawCircle(
        Offset(center.dx - radius * 0.3, center.dy - radius * 0.3),
        radius * 0.45,
        highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _AuroraFluidOrbPainter oldDelegate) => true;
}
