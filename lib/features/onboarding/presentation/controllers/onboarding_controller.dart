import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/auth_api_service.dart';
import '../../../../core/storage/onboarding_flag_store.dart';

class OnboardingState {
  final String selectedLanguage;
  final String mobileNumber;
  final String otpCode;
  final String selectedRole;
  final bool isLoading;
  final String? errorMessage;
  final int resendCountdown;
  final bool isOtpInvalid;

  const OnboardingState({
    this.selectedLanguage = 'ta',
    this.mobileNumber = '',
    this.otpCode = '',
    this.selectedRole = 'farmer',
    this.isLoading = false,
    this.errorMessage,
    this.resendCountdown = 30,
    this.isOtpInvalid = false,
  });

  OnboardingState copyWith({
    String? selectedLanguage,
    String? mobileNumber,
    String? otpCode,
    String? selectedRole,
    bool? isLoading,
    String? errorMessage,
    int? resendCountdown,
    bool? isOtpInvalid,
  }) {
    return OnboardingState(
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      otpCode: otpCode ?? this.otpCode,
      selectedRole: selectedRole ?? this.selectedRole,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      resendCountdown: resendCountdown ?? this.resendCountdown,
      isOtpInvalid: isOtpInvalid ?? this.isOtpInvalid,
    );
  }

  bool get isMobileValid => mobileNumber.replaceAll(RegExp(r'\D'), '').length == 10;
  bool get isOtpValid => otpCode.trim().length == 6;
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

  void selectRole(String role) {
    state = state.copyWith(selectedRole: role);
  }

  Future<bool> sendOtp() async {
    if (!state.isMobileValid) {
      state = state.copyWith(errorMessage: 'Please enter a valid 10-digit mobile number');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    final response = await _authApiService.requestOtp(state.mobileNumber);
    state = state.copyWith(isLoading: false);

    if (response.success) {
      startResendTimer();
      return true;
    } else {
      state = state.copyWith(errorMessage: response.message);
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
    final response = await _authApiService.verifyOtp(state.mobileNumber, state.otpCode);
    state = state.copyWith(isLoading: false);

    if (response.success) {
      return true;
    } else {
      state = state.copyWith(
        errorMessage: response.message,
        isOtpInvalid: true,
      );
      return false;
    }
  }

  Future<String> completeOnboarding() async {
    final flagStore = await OnboardingFlagStore.create();
    await flagStore.setSelectedLanguage(state.selectedLanguage);
    await flagStore.setSelectedRole(state.selectedRole);
    await flagStore.setMobileNumber(state.mobileNumber);
    await flagStore.setHasOnboarded(true);

    return state.selectedRole == 'officer' ? '/officer/dashboard' : '/today';
  }
}

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService();
});

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>((ref) {
  final authService = ref.watch(authApiServiceProvider);
  return OnboardingController(authService);
});
