import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aquaverse_farmer_app/core/network/auth_api_service.dart';
import 'package:aquaverse_farmer_app/features/onboarding/presentation/controllers/onboarding_controller.dart';

class MockVerifyAuthService implements AuthApiService {
  final bool success;
  final String? returnedRole;
  final String? message;

  MockVerifyAuthService({
    required this.success,
    this.returnedRole,
    this.message,
  });

  @override
  Future<AuthResponse> verifyOtp(String mobileNumber, String otpCode, {String? role}) async {
    return AuthResponse(
      success: success,
      message: message ?? (success ? 'Verified' : 'Invalid OTP'),
      token: success ? 'mock-verified-token' : null,
      role: returnedRole,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OnboardingController Role Authority Verification', () {
    test('TEST A: User selects farmer, backend returns officer -> verifiedRole is officer and routes to /officer/dashboard', () async {
      final authService = MockVerifyAuthService(success: true, returnedRole: 'officer');
      final controller = OnboardingController(authService);

      controller.setMobileNumber('9876543210');
      controller.setOtpCode('123456');
      controller.selectRole('farmer'); // User intent = farmer

      expect(controller.state.selectedRole, 'farmer');
      expect(controller.state.verifiedRole, isNull);

      final success = await controller.verifyOtp();
      expect(success, isTrue);
      // Authority check: verified role MUST override user intent
      expect(controller.state.verifiedRole, 'officer');
      expect(controller.state.selectedRole, 'officer');

      final destination = await controller.completeOnboarding();
      expect(destination, '/officer/dashboard');
    });

    test('TEST B: User selects officer, backend returns farmer -> verifiedRole is farmer and routes to /today', () async {
      final authService = MockVerifyAuthService(success: true, returnedRole: 'farmer');
      final controller = OnboardingController(authService);

      controller.setMobileNumber('9876543210');
      controller.setOtpCode('123456');
      controller.selectRole('officer'); // User intent = officer

      expect(controller.state.selectedRole, 'officer');
      expect(controller.state.verifiedRole, isNull);

      final success = await controller.verifyOtp();
      expect(success, isTrue);
      // Authority check: verified role MUST override user intent
      expect(controller.state.verifiedRole, 'farmer');
      expect(controller.state.selectedRole, 'farmer');

      final destination = await controller.completeOnboarding();
      expect(destination, '/today');
    });

    test('TEST C: Backend returns no verified role (null/empty) -> authentication fails, no role guessing', () async {
      final authService = MockVerifyAuthService(success: true, returnedRole: null);
      final controller = OnboardingController(authService);

      controller.setMobileNumber('9876543210');
      controller.setOtpCode('123456');
      controller.selectRole('officer');

      final success = await controller.verifyOtp();
      // Authority check: missing role must be rejected as an unverified session
      expect(success, isFalse);
      expect(controller.state.verifiedRole, isNull);
      expect(controller.state.isOtpInvalid, isTrue);
      expect(controller.state.errorMessage, contains('No verified role'));

      // If somehow completeOnboarding was called without verified role:
      final destination = await controller.completeOnboarding();
      expect(destination, '/onboarding/role'); // Safe re-login → role selection, does NOT guess officer/today
    });
  });
}

