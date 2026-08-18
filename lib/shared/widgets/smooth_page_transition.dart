import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Smooth Fade-Through Page Transition (ideal for BottomNav & primary tab screens)
CustomTransitionPage<T> buildSmoothFadeThroughPage<T>({
  required LocalKey key,
  required Widget child,
  Duration duration = const Duration(milliseconds: 240),
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    opaque: true,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      final scaleAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      );

      return FadeTransition(
        opacity: fadeAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: child,
        ),
      );
    },
  );
}

/// Smooth Slide-Up Page Transition (ideal for action forms & logs)
CustomTransitionPage<T> buildSmoothSlideUpPage<T>({
  required LocalKey key,
  required Widget child,
  Duration duration = const Duration(milliseconds: 260),
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    opaque: true,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0.0, 0.06),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn));

      final fadeAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      );

      return SlideTransition(
        position: slideAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: child,
        ),
      );
    },
  );
}

/// Smooth Horizontal Push Page Transition (ideal for detail drill-downs & profiles)
CustomTransitionPage<T> buildSmoothPushPage<T>({
  required LocalKey key,
  required Widget child,
  Duration duration = const Duration(milliseconds: 240),
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    opaque: true,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0.04, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      final fadeAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      );

      return SlideTransition(
        position: slideAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: child,
        ),
      );
    },
  );
}
