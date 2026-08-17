import 'package:flutter/material.dart';
import 'floating_icons_overlay.dart';

/// Standard scaffold wrapper for all Onboarding screens.
/// Displays the custom aquaculture background image (`assets/images/onboarding_bg.png`)
/// with high-contrast icon overlays and crisp gradient scrim.
class OnboardingScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final bool resizeToAvoidBottomInset;

  const OnboardingScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: Colors.transparent,
      appBar: appBar,
      body: Stack(
        children: [
          // 1. Background Image with Contrast Boost
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                0.85, 0,    0,    0, -15, // Red: slightly darkened & deepened
                0,    0.88, 0,    0, -10, // Green
                0,    0,    0.88, 0, -10, // Blue
                0,    0,    0,    1,   0, // Alpha
              ]),
              child: Image.asset(
                'assets/images/onboarding_bg.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),

          // 2. High-contrast Dark Outline Floating Icons Overlay
          const Positioned.fill(
            child: FloatingIconsOverlay(
              iconColor: Color(0xFF042738), // Dark Navy/Teal outline for 100% visibility
            ),
          ),

          // 2. Multi-stop directional gradient scrim for high contrast (Section 2.2 spec)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08), // Top: lightest scrim
                    Colors.black.withValues(alpha: 0.22), // Mid-upper
                    Colors.black.withValues(alpha: 0.32), // Mid-lower: icon cluster band
                    Colors.black.withValues(alpha: 0.58), // Bottom: darkest for CTA / subtext
                  ],
                  stops: const [0.0, 0.30, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // 3. Screen Body Content
          Positioned.fill(
            child: body,
          ),
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
