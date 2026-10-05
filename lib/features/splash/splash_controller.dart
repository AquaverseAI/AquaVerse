import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/onboarding_flag_store.dart';
import '../../core/network/auth_api_service.dart';

final splashControllerProvider = Provider<SplashController>((ref) {
  final authApiService = ref.watch(authApiServiceProvider);
  return SplashController(authApiService);
});

/// Controller managing splash resolution adhering to PRD-AV-04 §7 Rule 2:
///
/// | `has_onboarded` | Valid/refreshable token? | Route destination |
/// |---|---|---|
/// | false | — | Full Onboarding (`/onboarding/language`) |
/// | true | Yes | Today Dashboard (`/today` or `/officer/dashboard`) |
/// | true | No | Re-login (`/onboarding/role` → `/onboarding/mobile`) |
class SplashController {
  final AuthApiService _authApiService;

  SplashController(this._authApiService);

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
          // BRANCH 2: Valid Token -> Home (Backend verified role is authoritative)
          final verifiedRole = authResponse.role;
          if (verifiedRole == 'officer') {
            return '/officer/dashboard';
          } else if (verifiedRole == 'farmer') {
            return '/today';
          } else {
            // Unverified or missing role -> safe re-login via role selection
            // (never guess the role — user must re-select explicitly)
            return '/onboarding/role';
          }
        } else {
          // BRANCH 3: Invalid/Expired Token -> Re-login from role selection
          return '/onboarding/role';
        }
      } catch (e) {
        // Token check failed/network error -> Re-login from role selection
        return '/onboarding/role';
      }
    } catch (e) {
      // Storage read error -> Default to Full Onboarding
      return '/onboarding/language';
    }
  }
}
