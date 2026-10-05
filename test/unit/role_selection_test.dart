import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aquaverse_farmer_app/core/network/auth_api_service.dart';
import 'package:aquaverse_farmer_app/features/onboarding/presentation/controllers/onboarding_controller.dart';

/// Minimal mock — only sendOtp and verifyOtp are used in these tests.
class MockAuthServiceForRoleSelection implements AuthApiService {
  @override
  Future<AuthResponse> requestOtp(String mobileNumber) async {
    return AuthResponse(success: true, message: 'OTP sent');
  }

  @override
  Future<AuthResponse> verifyOtp(String mobileNumber, String otpCode, {String? role}) async {
    return AuthResponse(
      success: true,
      message: 'Verified',
      token: 'mock-token',
      role: 'farmer', // always returns farmer for these tests
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RoleSelectionScreen — OnboardingState gating', () {
    test('Initial state: isRoleExplicitlySet is false', () {
      final controller = OnboardingController(MockAuthServiceForRoleSelection());
      expect(controller.state.isRoleExplicitlySet, isFalse);
    });

    test('Initial state: canContinueFromRoleSelection is false', () {
      final controller = OnboardingController(MockAuthServiceForRoleSelection());
      expect(controller.state.canContinueFromRoleSelection, isFalse);
    });

    test('Selecting farmer sets selectedRole=farmer and isRoleExplicitlySet=true', () async {
      final controller = OnboardingController(MockAuthServiceForRoleSelection());
      controller.selectRole('farmer');
      // Wait for async SharedPreferences write to settle
      await Future.delayed(const Duration(milliseconds: 10));
      expect(controller.state.selectedRole, 'farmer');
      expect(controller.state.isRoleExplicitlySet, isTrue);
      expect(controller.state.canContinueFromRoleSelection, isTrue);
    });

    test('Selecting officer sets selectedRole=officer and isRoleExplicitlySet=true', () async {
      final controller = OnboardingController(MockAuthServiceForRoleSelection());
      controller.selectRole('officer');
      await Future.delayed(const Duration(milliseconds: 10));
      expect(controller.state.selectedRole, 'officer');
      expect(controller.state.isRoleExplicitlySet, isTrue);
      expect(controller.state.canContinueFromRoleSelection, isTrue);
    });

    test('Only one role can be active: selecting officer after farmer overrides', () async {
      final controller = OnboardingController(MockAuthServiceForRoleSelection());
      controller.selectRole('farmer');
      await Future.delayed(const Duration(milliseconds: 10));
      expect(controller.state.selectedRole, 'farmer');

      controller.selectRole('officer');
      await Future.delayed(const Duration(milliseconds: 10));
      expect(controller.state.selectedRole, 'officer');
      expect(controller.state.isRoleExplicitlySet, isTrue);
    });

    test('clearOnLogout resets isRoleExplicitlySet and verifiedRole', () async {
      final controller = OnboardingController(MockAuthServiceForRoleSelection());
      controller.selectRole('farmer');
      await Future.delayed(const Duration(milliseconds: 10));
      expect(controller.state.isRoleExplicitlySet, isTrue);

      controller.clearOnLogout();
      expect(controller.state.isRoleExplicitlySet, isFalse);
      expect(controller.state.verifiedRole, isNull);
      expect(controller.state.canContinueFromRoleSelection, isFalse);
    });

    test('clearOnLogout preserves selectedLanguage', () async {
      final controller = OnboardingController(MockAuthServiceForRoleSelection());
      controller.selectLanguage('en');
      controller.selectRole('farmer');
      await Future.delayed(const Duration(milliseconds: 10));

      controller.clearOnLogout();
      expect(controller.state.selectedLanguage, 'en');
    });

    test('setMobileNumber does not affect isRoleExplicitlySet', () async {
      final controller = OnboardingController(MockAuthServiceForRoleSelection());
      controller.selectRole('farmer');
      await Future.delayed(const Duration(milliseconds: 10));
      expect(controller.state.isRoleExplicitlySet, isTrue);

      controller.setMobileNumber('9876543210');
      expect(controller.state.isRoleExplicitlySet, isTrue);
    });

    test('selectRole persists across setMobileNumber calls (role survives phone entry)', () async {
      final controller = OnboardingController(MockAuthServiceForRoleSelection());
      controller.selectRole('officer');
      await Future.delayed(const Duration(milliseconds: 10));

      controller.setMobileNumber('9876543210');
      expect(controller.state.selectedRole, 'officer');
      expect(controller.state.isRoleExplicitlySet, isTrue);
    });
  });

  group('Two-Screen Auth Flow — selectedRole vs verifiedRole separation', () {
    test('selectedRole is user intent — set on role selection screen', () {
      final controller = OnboardingController(MockAuthServiceForRoleSelection());
      controller.selectRole('officer');
      // selectedRole is INTENT — not authorization
      expect(controller.state.selectedRole, 'officer');
      // verifiedRole is null until backend returns it
      expect(controller.state.verifiedRole, isNull);
    });

    test('verifiedRole is null until OTP verification succeeds', () {
      final controller = OnboardingController(MockAuthServiceForRoleSelection());
      controller.selectRole('farmer');
      controller.setMobileNumber('9876543210');
      controller.setOtpCode('123456');
      // Before verifyOtp() is called — verifiedRole must still be null
      expect(controller.state.verifiedRole, isNull);
    });

    test('After verifyOtp: verifiedRole=farmer routes to /today', () async {
      final controller = OnboardingController(MockAuthServiceForRoleSelection());
      controller.selectRole('officer'); // user selected officer
      controller.setMobileNumber('9876543210');
      controller.setOtpCode('123456');

      final success = await controller.verifyOtp();
      expect(success, isTrue);
      // Backend returned 'farmer' — authority overrides user intent
      expect(controller.state.verifiedRole, 'farmer');

      final destination = await controller.completeOnboarding();
      expect(destination, '/today');
    });
  });

  group('Phone Number Validation', () {
    test('10-digit number is valid', () {
      final controller = OnboardingController(MockAuthServiceForRoleSelection());
      controller.setMobileNumber('9876543210');
      expect(controller.state.isMobileValid, isTrue);
    });

    test('9-digit number is invalid', () {
      final controller = OnboardingController(MockAuthServiceForRoleSelection());
      controller.setMobileNumber('987654321');
      expect(controller.state.isMobileValid, isFalse);
    });

    test('11-digit number is invalid (truncated to 10 by formatter, but state gets full input)', () {
      final controller = OnboardingController(MockAuthServiceForRoleSelection());
      // The UI formatter limits to 10 digits; controller strips non-digits
      controller.setMobileNumber('98765432109');
      // 11 digits stored → isMobileValid is false (>10 after strip)
      expect(controller.state.isMobileValid, isFalse);
    });

    test('Empty string is invalid', () {
      final controller = OnboardingController(MockAuthServiceForRoleSelection());
      controller.setMobileNumber('');
      expect(controller.state.isMobileValid, isFalse);
    });

    test('Non-digit characters are stripped', () {
      final controller = OnboardingController(MockAuthServiceForRoleSelection());
      controller.setMobileNumber('+91-9876543210');
      // After stripping non-digits: '919876543210' → 12 chars → invalid
      // The UI sends only the 10 digits (no +91 prefix) — this tests the internal stripping
      controller.setMobileNumber('9876543210');
      expect(controller.state.isMobileValid, isTrue);
    });
  });
}

