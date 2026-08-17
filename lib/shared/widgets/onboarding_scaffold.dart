import 'package:flutter/material.dart';

/// Standard scaffold wrapper for all Onboarding screens.
/// Displays the custom aquaculture background image (`assets/images/onboarding_bg.png`)
/// with a subtle contrast-enhancing overlay for crisp text readability.
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
          // 1. Background Image (Full coverage)
          Positioned.fill(
            child: Image.asset(
              'assets/images/onboarding_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
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
