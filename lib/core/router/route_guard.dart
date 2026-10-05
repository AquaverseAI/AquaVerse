import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/secure_token_storage.dart';
import '../storage/onboarding_flag_store.dart';

/// Role-authoritative Route Guard for AquaVerse AI.
///
/// Implements AGENTS.md and PRD-AV-04 authorization rules:
/// - Unauthenticated users cannot access protected routes.
/// - Farmers cannot access Officer routes.
/// - Officers cannot access Farmer-only routes.
/// - Authorization is derived SOLELY from backend-verified role (verifiedRole),
///   NEVER from client-selected role (selectedRole).
class RouteGuard {
  static const Set<String> publicRoutes = {
    '/',
    '/login',
    '/onboarding/language',
    '/onboarding/role',
    '/onboarding/mobile',
    '/onboarding/otp',
  };

  static const Set<String> officerRoutes = {
    '/officer/dashboard',
    '/officer/visit-log',
    '/officer/profile',
  };

  static const Set<String> farmerOnlyRoutes = {
    '/today',
    '/log',
    '/ask',
    '/alerts',
    '/crop',
    '/ponds',
    '/pond-details',
  };

  final Future<bool> Function() _hasSession;
  final Future<String?> Function() _getVerifiedRole;
  final Future<bool> Function() _hasOnboarded;

  static RouteGuard? _instance;

  /// Sets or clears test override instance.
  @visibleForTesting
  static void setMockInstance(RouteGuard? mockGuard) {
    _instance = mockGuard;
  }

  RouteGuard({
    required Future<bool> Function() hasSession,
    required Future<String?> Function() getVerifiedRole,
    required Future<bool> Function() hasOnboarded,
  })  : _hasSession = hasSession,
        _getVerifiedRole = getVerifiedRole,
        _hasOnboarded = hasOnboarded;

  /// Factory creating RouteGuard with real storage backends.
  factory RouteGuard.fromStorage(
    SecureTokenStorage tokenStorage,
    OnboardingFlagStore flagStore,
  ) {
    return RouteGuard(
      hasSession: () => tokenStorage.hasTokens(),
      getVerifiedRole: () => tokenStorage.getUserRole(),
      hasOnboarded: () async => flagStore.hasOnboarded,
    );
  }

  /// Retrieves the active singleton or instantiates it from storage.
  static Future<RouteGuard> getInstance() async {
    if (_instance != null) return _instance!;
    final flagStore = await OnboardingFlagStore.create();
    final prefs = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage();
    final tokenStorage = SecureTokenStorage(
      secureStorage: secureStorage,
      preferences: prefs,
    );
    _instance = RouteGuard.fromStorage(tokenStorage, flagStore);
    return _instance!;
  }


  /// Determines if a navigation attempt should be allowed, or redirected.
  /// Returns `null` if navigation is allowed, or the target route string if blocked.
  Future<String?> redirect(String location) async {
    // 1. Splash is always unrestricted
    if (location == '/') return null;

    final isPublic = publicRoutes.contains(location);

    // 2. Check active authentication session
    final hasActiveSession = await _hasSession();

    if (!hasActiveSession) {
      if (isPublic) {
        // Allowed to navigate among onboarding/login screens
        return null;
      }
      // Attempting to access protected screen without active session -> Block
      final onboarded = await _hasOnboarded();
      return onboarded ? '/onboarding/role' : '/onboarding/language';
    }

    // 3. User is authenticated. Determine backend-verified authority.
    final verifiedRole = await _getVerifiedRole();

    // Invalid or missing verified role -> Safe re-login (never guess)
    if (verifiedRole != 'farmer' && verifiedRole != 'officer') {
      if (isPublic) return null;
      return '/onboarding/role';
    }

    // 4. Role Authorization Checks:
    // Case A: Farmer attempting to access Officer route -> Redirect to Farmer Today
    if (verifiedRole == 'farmer' && (officerRoutes.contains(location) || location.startsWith('/officer'))) {
      debugPrint('[RouteGuard] Blocked Farmer from Officer route: $location -> /today');
      return '/today';
    }

    // Case B: Officer attempting to access Farmer-only route -> Redirect to Officer Dashboard
    if (verifiedRole == 'officer' && farmerOnlyRoutes.contains(location)) {
      debugPrint('[RouteGuard] Blocked Officer from Farmer route: $location -> /officer/dashboard');
      return '/officer/dashboard';
    }

    // Allowed
    return null;
  }
}
