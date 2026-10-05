import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aquaverse_farmer_app/core/network/auth_api_service.dart';
import 'package:aquaverse_farmer_app/features/splash/splash_controller.dart';

class MockAuthApiService implements AuthApiService {
  final bool shouldSucceed;
  final String? token;
  final String? role;

  MockAuthApiService({
    required this.shouldSucceed,
    this.token,
    this.role,
  });

  @override
  Future<AuthResponse> refreshToken() async {
    if (shouldSucceed) {
      return AuthResponse(
        success: true,
        message: 'Token refreshed',
        token: token ?? 'valid-jwt-token',
        role: role,
      );
    }
    return AuthResponse(
      success: false,
      message: 'Token expired',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Splash Routing Decision Table (AGENTS.md Rule 2)', () {
    test('Row 1: !hasOnboarded -> routes to /onboarding/language', () async {
      SharedPreferences.setMockInitialValues({
        'has_onboarded': false,
      });

      final mockAuth = MockAuthApiService(shouldSucceed: true, role: 'farmer');
      final controller = SplashController(mockAuth);

      final route = await controller.determineNextRoute();
      expect(route, '/onboarding/language');
    });

    test('Row 2 (Farmer): hasOnboarded && valid token -> routes to /today', () async {
      SharedPreferences.setMockInitialValues({
        'has_onboarded': true,
        'selected_role': 'farmer',
      });

      final mockAuth = MockAuthApiService(shouldSucceed: true, token: 'mock-valid-token', role: 'farmer');
      final controller = SplashController(mockAuth);

      final route = await controller.determineNextRoute();
      expect(route, '/today');
    });

    test('Row 2 (Officer): hasOnboarded && valid token -> routes to /officer/dashboard', () async {
      SharedPreferences.setMockInitialValues({
        'has_onboarded': true,
        'selected_role': 'officer',
      });

      final mockAuth = MockAuthApiService(shouldSucceed: true, token: 'mock-valid-token', role: 'officer');
      final controller = SplashController(mockAuth);

      final route = await controller.determineNextRoute();
      expect(route, '/officer/dashboard');
    });

    test('Row 3: hasOnboarded && !validToken -> routes to /onboarding/role (Re-login: select role first)', () async {
      SharedPreferences.setMockInitialValues({
        'has_onboarded': true,
        'selected_role': 'farmer',
      });

      final mockAuth = MockAuthApiService(shouldSucceed: false);
      final controller = SplashController(mockAuth);

      final route = await controller.determineNextRoute();
      // New two-screen flow: expired/invalid token → role selection first
      expect(route, '/onboarding/role');
    });
  });

  group('Backend-Authoritative Role Routing (Negative Tests)', () {
    test('TEST A: User selected farmer, backend returns officer -> routes to /officer/dashboard', () async {
      SharedPreferences.setMockInitialValues({
        'has_onboarded': true,
        'selected_role': 'farmer', // Client selection intent
      });

      // Backend returns verified role: officer
      final mockAuth = MockAuthApiService(shouldSucceed: true, token: 'mock-valid-token', role: 'officer');
      final controller = SplashController(mockAuth);

      final route = await controller.determineNextRoute();
      expect(route, '/officer/dashboard'); // Authority is backend, NOT client SharedPreferences
    });

    test('TEST B: User selected officer, backend returns farmer -> routes to /today', () async {
      SharedPreferences.setMockInitialValues({
        'has_onboarded': true,
        'selected_role': 'officer', // Client selection intent
      });

      // Backend returns verified role: farmer
      final mockAuth = MockAuthApiService(shouldSucceed: true, token: 'mock-valid-token', role: 'farmer');
      final controller = SplashController(mockAuth);

      final route = await controller.determineNextRoute();
      expect(route, '/today'); // Authority is backend, NOT client SharedPreferences
    });

    test('TEST C: No verified role returned by backend -> routes to /onboarding/role (safe re-login with role selection)', () async {
      SharedPreferences.setMockInitialValues({
        'has_onboarded': true,
        'selected_role': 'officer', // Client selection intent
      });

      // Backend returns null role
      final mockAuth = MockAuthApiService(shouldSucceed: true, token: 'mock-valid-token', role: null);
      final controller = SplashController(mockAuth);

      final route = await controller.determineNextRoute();
      // New behavior: unknown role → role selection (never guess), not /onboarding/mobile
      expect(route, '/onboarding/role');
    });
  });
}
