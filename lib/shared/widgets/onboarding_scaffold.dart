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

          // 2. Light gradient overlay for text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.25),
                    Colors.white.withValues(alpha: 0.10),
                    Colors.white.withValues(alpha: 0.30),
                  ],
                  stops: const [0.0, 0.5, 1.0],
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
