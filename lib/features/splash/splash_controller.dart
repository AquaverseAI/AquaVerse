import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/onboarding_flag_store.dart';
import '../../core/network/auth_api_service.dart';

final splashControllerProvider = Provider((ref) => SplashController());

class SplashController {
  final AuthApiService _authApiService = AuthApiService();

  Future<String> determineNextRoute() async {
    try {
      final flagStore = await OnboardingFlagStore.create();
      final hasOnboarded = flagStore.hasOnboarded;

      // RULE: First-Launch Navigation — Mandatory
      // If not onboarded, go to Full Onboarding (Language Select)
      if (!hasOnboarded) {
        return '/onboarding/language';
      }

      // If onboarded, check Auth token independently
      try {
        final authResponse = await _authApiService.refreshToken().timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('Token refresh timed out'),
        );
        
        if (authResponse.success && authResponse.token != null) {
          // Token valid -> go directly to Home
          return '/today';
        } else {
          // Token invalid/missing -> go to Login (Phone Entry)
          return '/onboarding/mobile';
        }
      } catch (e) {
        // If refresh fails or times out, default to Login
        return '/onboarding/mobile';
      }
    } catch (e) {
      // On any flag read error, default to false (first-launch)
      return '/onboarding/language';
    }
  }
}
