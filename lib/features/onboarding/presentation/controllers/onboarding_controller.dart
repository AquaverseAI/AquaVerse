import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/auth_api_service.dart';
import '../../../../core/storage/onboarding_flag_store.dart';

class OnboardingState {
  final String selectedLanguage;
  final String mobileNumber;
  final String otpCode;
  final String selectedRole;
  final String? verifiedRole;
  final bool isLoading;
  final String? errorMessage;
  final int resendCountdown;
  final bool isOtpInvalid;

  /// True when the user has explicitly tapped a role card on RoleSelectionScreen.
  /// False on fresh app launch (before role is chosen).
  final bool isRoleExplicitlySet;

  const OnboardingState({
    this.selectedLanguage = 'ta',
    this.mobileNumber = '',
    this.otpCode = '',
    this.selectedRole = 'farmer',
    this.verifiedRole,
    this.isLoading = false,
    this.errorMessage,
    this.resendCountdown = 30,
    this.isOtpInvalid = false,
    this.isRoleExplicitlySet = false,
  });

  static const _sentinel = Object();

  OnboardingState copyWith({
    String? selectedLanguage,
    String? mobileNumber,
    String? otpCode,
    String? selectedRole,
    String? verifiedRole,
    bool? isLoading,
    Object? errorMessage = _sentinel,
    int? resendCountdown,
    bool? isOtpInvalid,
    bool? isRoleExplicitlySet,
  }) {
    return OnboardingState(
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      otpCode: otpCode ?? this.otpCode,
      selectedRole: selectedRole ?? this.selectedRole,
      verifiedRole: verifiedRole ?? this.verifiedRole,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == _sentinel ? this.errorMessage : errorMessage as String?,
      resendCountdown: resendCountdown ?? this.resendCountdown,
      isOtpInvalid: isOtpInvalid ?? this.isOtpInvalid,
      isRoleExplicitlySet: isRoleExplicitlySet ?? this.isRoleExplicitlySet,
    );
  }

  bool get isMobileValid => mobileNumber.replaceAll(RegExp(r'\D'), '').length == 10;
  bool get isOtpValid => otpCode.trim().length == 6;

  /// True when Continue can be tapped on the Role Selection screen.
  bool get canContinueFromRoleSelection => isRoleExplicitlySet;
}


class OnboardingController extends StateNotifier<OnboardingState> {
  final AuthApiService _authApiService;
  Timer? _resendTimer;

  OnboardingController(this._authApiService) : super(const OnboardingState());

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  void selectLanguage(String languageCode) {
    state = state.copyWith(selectedLanguage: languageCode);
  }

  void setMobileNumber(String mobile) {
    final cleanMobile = mobile.replaceAll(RegExp(r'\D'), '');
    state = state.copyWith(mobileNumber: cleanMobile, errorMessage: null);
  }

  void setOtpCode(String code) {
    state = state.copyWith(
      otpCode: code,
      errorMessage: null,
      isOtpInvalid: false,
    );
  }

  /// Marks the role as explicitly selected by the user on RoleSelectionScreen.
  /// This enables the Continue button. selectedRole is user intent only —
  /// never use it for authorization after authentication.
  void selectRole(String role) async {
    state = state.copyWith(selectedRole: role, isRoleExplicitlySet: true);
    final flagStore = await OnboardingFlagStore.create();
    await flagStore.setSelectedRole(role);
  }

  /// Clears session state on logout.
  /// Preserves: selectedLanguage, mobileNumber (for UX convenience).
  /// Clears: verifiedRole, isRoleExplicitlySet, otpCode, errorMessage.
  /// The next login must go through RoleSelectionScreen to re-select a role.
  void clearOnLogout() {
    state = state.copyWith(
      verifiedRole: null,
      otpCode: '',
      errorMessage: null,
      isOtpInvalid: false,
      isRoleExplicitlySet: false,
    );
  }

  Future<bool> sendOtp() async {
    if (!state.isMobileValid) {
      state = state.copyWith(errorMessage: 'Please enter a valid 10-digit mobile number');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _authApiService.requestOtp(state.mobileNumber);
      state = state.copyWith(isLoading: false);

      if (response.success) {
        startResendTimer();
        return true;
      } else {
        state = state.copyWith(errorMessage: response.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to send OTP. Please try again.',
      );
      return false;
    }
  }

  void startResendTimer() {
    _resendTimer?.cancel();
    state = state.copyWith(resendCountdown: 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.resendCountdown <= 1) {
        timer.cancel();
        state = state.copyWith(resendCountdown: 0);
      } else {
        state = state.copyWith(resendCountdown: state.resendCountdown - 1);
      }
    });
  }

  Future<bool> verifyOtp() async {
    if (!state.isOtpValid) {
      state = state.copyWith(
        errorMessage: 'Please enter a 6-digit OTP code',
        isOtpInvalid: true,
      );
      return false;
    }
    state = state.copyWith(isLoading: true, errorMessage: null, isOtpInvalid: false);
    try {
      final response = await _authApiService.verifyOtp(
        state.mobileNumber,
        state.otpCode,
        role: state.selectedRole,
      );
      state = state.copyWith(isLoading: false);

      if (response.success) {
        if (response.role == null || response.role!.isEmpty) {
          state = state.copyWith(
            errorMessage: 'Authentication failed: No verified role assigned by server.',
            isOtpInvalid: true,
          );
          return false;
        }

        final verifiedRole = response.role!;
        state = state.copyWith(
          verifiedRole: verifiedRole,
          selectedRole: verifiedRole,
        );
        final flagStore = await OnboardingFlagStore.create();
        await flagStore.setSelectedRole(verifiedRole);
        return true;
      } else {
        state = state.copyWith(
          errorMessage: response.message,
          isOtpInvalid: true,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Verification failed. Please check your connection and try again.',
        isOtpInvalid: true,
      );
      return false;
    }
  }

  Future<String> completeOnboarding() async {
    final flagStore = await OnboardingFlagStore.create();
    await flagStore.setSelectedLanguage(state.selectedLanguage);
    final role = state.verifiedRole;
    if (role != null) {
      await flagStore.setSelectedRole(role);
    }
    await flagStore.setMobileNumber(state.mobileNumber);
    await flagStore.setHasOnboarded(true);

    if (role == 'officer') {
      return '/officer/dashboard';
    } else if (role == 'farmer') {
      return '/today';
    } else {
      // Missing or unrecognized verified role → role selection for safe re-login.
      return '/onboarding/role';
    }
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>((ref) {
  final authService = ref.watch(authApiServiceProvider);
  return OnboardingController(authService);
});
