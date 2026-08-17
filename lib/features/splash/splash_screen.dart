import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'splash_controller.dart';
import 'package:aquaverse_farmer_app/core/theme/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  String? _targetRoute;
  
  // Elegant reveal animation for the logo
  late AnimationController _revealController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Pulsing animation for the loader
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _determineRoute();
    
    // 1. Logo Reveal (slow fade and rise)
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08), // Start slightly lower
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOutCubic,
    ));

    // 2. Ripple/Pulse Loader
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _revealController.forward();

    // Hold splash screen for at least 3.5 seconds
    Future.delayed(const Duration(milliseconds: 3500), () {
      _navigateWhenReady();
    });
  }

  Future<void> _determineRoute() async {
    _targetRoute = await ref.read(splashControllerProvider).determineNextRoute();
  }

  void _navigateWhenReady() {
    if (!mounted) return;
    if (_targetRoute != null) {
      context.go(_targetRoute!);
    } else {
      Future.delayed(const Duration(milliseconds: 100), _navigateWhenReady);
    }
  }

  @override
  void dispose() {
    _revealController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image (contains the wordmark and slogan already!)
          Image.asset(
            'assets/splash/SPlash screen Background.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) => Container(color: AppColors.scaffoldBg),
          ),
          
          // Elegant Logo Reveal
          Positioned(
            top: screenHeight * 0.14,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  'assets/splash/logo.png',
                  height: 190, 
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.set_meal_rounded, 
                    size: 80, 
                    color: AppColors.deepNavy
                  ),
                ),
              ),
            ),
          ),
          
          // Custom Pulsing Loader and Text at the bottom
          Positioned(
            bottom: screenHeight * 0.08,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pulsing Water Loader
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseController.value * 0.15); // Scale up to 1.15x
                    final opacity = 1.0 - (_pulseController.value * 0.5); // Fade to 0.5 opacity
                    
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.lightCyan.withValues(alpha: 0.15 * opacity),
                          border: Border.all(
                            color: AppColors.lightCyan.withValues(alpha: 0.8 * opacity),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.aqua.withValues(alpha: 0.4 * opacity),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.waves_rounded,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 28,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                
                // Loading Text
                const Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                
                // Subtext
                Text(
                  'Preparing your intelligent insights',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
