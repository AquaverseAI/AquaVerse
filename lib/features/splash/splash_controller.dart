import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/onboarding_flag_store.dart';
import '../../core/network/auth_api_service.dart';

final splashControllerProvider = Provider((ref) => SplashController());

/// Controller managing splash resolution adhering to PRD-AV-04 §7 Rule 2:
///
/// | `has_onboarded` | Valid/refreshable token? | Route destination |
/// |---|---|---|
/// | false | — | Full Onboarding (`/onboarding/language`) |
/// | true | Yes | Today Dashboard (`/today` or `/officer/dashboard`) |
/// | true | No | Re-login (`/onboarding/mobile` — OTP only) |
class SplashController {
  final AuthApiService _authApiService;

  SplashController({AuthApiService? authApiService})
      : _authApiService = authApiService ?? AuthApiService();

  Future<String> determineNextRoute() async {
    try {
      final flagStore = await OnboardingFlagStore.create();
      final hasOnboarded = flagStore.hasOnboarded;

      // BRANCH 1: Not Onboarded -> Full Onboarding
      if (!hasOnboarded) {
        return '/onboarding/language';
      }

      // BRANCH 2 & 3: Onboarded -> Check token validity
      try {
        final authResponse = await _authApiService.refreshToken().timeout(
          const Duration(seconds: 4),
          onTimeout: () => throw TimeoutException('Token refresh timed out'),
        );

        if (authResponse.success && authResponse.token != null) {
          // BRANCH 2: Valid Token -> Home (Role dependent)
          final userRole = flagStore.selectedRole;
          if (userRole == 'officer') {
            return '/officer/dashboard';
          }
          return '/today';
        } else {
          // BRANCH 3: Invalid/Expired Token -> Re-login (Mobile OTP)
          return '/onboarding/mobile';
        }
      } catch (e) {
        // Token check failed/network error -> Re-login (Mobile OTP)
        return '/onboarding/mobile';
      }
    } catch (e) {
      // Storage read error -> Default to Full Onboarding
      return '/onboarding/language';
    }
  }
}
