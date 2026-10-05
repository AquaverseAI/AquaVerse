import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A custom circular reveal ("Iris-In") transition for route navigation.
///
/// **Implementation Details & Reuse Guide:**
/// This transition clips the incoming page with a rapidly expanding circular mask.
/// It uses a custom [CustomClipper<Path>] that calculates the distance to the farthest
/// screen corner so that `fraction = 1.0` guarantees full-screen coverage.
///
/// **Performance & Timing:**
/// - Target duration: 400ms (kept strictly under 500ms for snappiness).
/// - Curve: [Curves.fastOutSlowIn] or [Curves.easeOutCubic] for a smooth acceleration curve.
/// - Does not block main thread state or perform layout recalculations during clipping.
///
/// **How to reuse across GoRouter routes:**
/// ```dart
/// GoRoute(
///   path: '/onboarding/language',
///   pageBuilder: (context, state) => buildIrisTransitionPage(
///     key: state.pageKey,
///     child: const OnboardingLanguageScreen(),
///   ),
/// );
/// ```
class CircularRevealClipper extends CustomClipper<Path> {
  /// Fraction of transition completion (0.0 = zero radius circle, 1.0 = full screen reveal)
  final double fraction;

  /// Center point of the circular reveal relative to screen size (default 0.5, 0.5 = center)
  final Offset centerFraction;

  CircularRevealClipper({
    required this.fraction,
    this.centerFraction = const Offset(0.5, 0.5),
  });

  @override
  Path getClip(Size size) {
    final center = Offset(
      size.width * centerFraction.dx,
      size.height * centerFraction.dy,
    );

    // Calculate maximum radius required to cover the farthest corner of the viewport
    final double maxRadius = math.sqrt(
      math.pow(math.max(center.dx, size.width - center.dx), 2) +
          math.pow(math.max(center.dy, size.height - center.dy), 2),
    );

    final double currentRadius = maxRadius * fraction;

    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: currentRadius));
    return path;
  }

  @override
  bool shouldReclip(covariant CircularRevealClipper oldClipper) {
    return oldClipper.fraction != fraction ||
        oldClipper.centerFraction != centerFraction;
  }
}

/// Helper function to construct a [CustomTransitionPage] using the Iris reveal effect for GoRouter.
CustomTransitionPage<void> buildIrisTransitionPage({
  required LocalKey key,
  required Widget child,
  Duration duration = const Duration(milliseconds: 400),
  Offset centerFraction = const Offset(0.5, 0.8), // Starts near the lower button position
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.fastOutSlowIn,
        reverseCurve: Curves.fastOutSlowIn.flipped,
      );

      return AnimatedBuilder(
        animation: curvedAnimation,
        builder: (context, child) {
          return ClipPath(
            clipper: CircularRevealClipper(
              fraction: curvedAnimation.value,
              centerFraction: centerFraction,
            ),
            child: child,
          );
        },
        child: child,
      );
    },
  );
}
