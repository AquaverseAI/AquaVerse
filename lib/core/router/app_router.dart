import 'package:go_router/go_router.dart';

import '../../shared/widgets/iris_transition.dart';
import '../../shared/widgets/smooth_page_transition.dart';

// Splash
import '../../features/splash/splash_screen.dart';

// Onboarding
import '../../features/onboarding/presentation/language_select_screen.dart';
import '../../features/onboarding/presentation/phone_entry_screen.dart';
import '../../features/onboarding/presentation/otp_verify_screen.dart';
import '../../features/onboarding/presentation/role_selection_screen.dart';
import '../../features/onboarding/presentation/ai_intro_screen.dart';

// Farmer Main
import '../../features/today/presentation/today_screen.dart';
import '../../features/log/presentation/log_entry_screen.dart';
import '../../features/ask/presentation/ask_screen.dart';
import '../../features/alerts/presentation/alerts_screen.dart';
import '../../features/crop/presentation/crop_screen.dart';

// Secondary
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/ponds/presentation/my_ponds_screen.dart';
import '../../features/ponds/presentation/pond_details_screen.dart';
import '../../features/help/presentation/help_center_screen.dart';

// Extension Officer
import '../../features/officer/presentation/officer_dashboard_screen.dart';
import '../../features/officer/presentation/officer_visit_log_screen.dart';
import '../../features/officer/presentation/officer_profile_screen.dart';
import '../../features/officer/presentation/officer_send_advice_screen.dart';
import '../../features/officer/presentation/officer_reports_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // ── Splash ──────────────────────────────────────────────────────────────
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),

    // ── Onboarding ───────────────────────────────────────────────────────────
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => buildIrisTransitionPage(
        key: state.pageKey,
        child: const PhoneEntryScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/language',
      pageBuilder: (context, state) => buildIrisTransitionPage(
        key: state.pageKey,
        child: const LanguageSelectScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/mobile',
      pageBuilder: (context, state) => buildSmoothPushPage(
        key: state.pageKey,
        child: const PhoneEntryScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/otp',
      pageBuilder: (context, state) => buildSmoothPushPage(
        key: state.pageKey,
        child: const OtpVerifyScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/role',
      pageBuilder: (context, state) => buildSmoothPushPage(
        key: state.pageKey,
        child: const RoleSelectionScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/intro',
      pageBuilder: (context, state) => buildSmoothPushPage(
        key: state.pageKey,
        child: const AiIntroScreen(),
      ),
    ),

    // ── Farmer Main Screens (Smooth Fade-Through Tab Transitions) ─────────────
    GoRoute(
      path: '/today',
      pageBuilder: (context, state) => buildSmoothFadeThroughPage(
        key: state.pageKey,
        child: const TodayScreen(),
      ),
    ),
    GoRoute(
      path: '/log',
      pageBuilder: (context, state) => buildSmoothSlideUpPage(
        key: state.pageKey,
        child: const LogEntryScreen(),
      ),
    ),
    GoRoute(
      path: '/ask',
      pageBuilder: (context, state) => buildSmoothFadeThroughPage(
        key: state.pageKey,
        child: const AskScreen(),
      ),
    ),
    GoRoute(
      path: '/alerts',
      pageBuilder: (context, state) => buildSmoothFadeThroughPage(
        key: state.pageKey,
        child: const AlertsScreen(),
      ),
    ),
    GoRoute(
      path: '/crop',
      pageBuilder: (context, state) => buildSmoothFadeThroughPage(
        key: state.pageKey,
        child: const CropScreen(),
      ),
    ),

    // ── Secondary Screens (Smooth Push & Slide Transitions) ───────────────────
    GoRoute(
      path: '/notifications',
      pageBuilder: (context, state) => buildSmoothPushPage(
        key: state.pageKey,
        child: const NotificationsScreen(),
      ),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => buildSmoothPushPage(
        key: state.pageKey,
        child: const SettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) => buildSmoothPushPage(
        key: state.pageKey,
        child: const ProfileScreen(),
      ),
    ),
    GoRoute(
      path: '/ponds',
      pageBuilder: (context, state) => buildSmoothPushPage(
        key: state.pageKey,
        child: const MyPondsScreen(),
      ),
    ),
    GoRoute(
      path: '/pond-details',
      pageBuilder: (context, state) => buildSmoothPushPage(
        key: state.pageKey,
        child: const PondDetailsScreen(),
      ),
    ),
    GoRoute(
      path: '/help',
      pageBuilder: (context, state) => buildSmoothSlideUpPage(
        key: state.pageKey,
        child: const HelpCenterScreen(),
      ),
    ),

    // ── Extension Officer Suite (Smooth Push & Slide Transitions) ────────────
    GoRoute(
      path: '/officer/dashboard',
      pageBuilder: (context, state) => buildSmoothFadeThroughPage(
        key: state.pageKey,
        child: const OfficerDashboardScreen(),
      ),
    ),
    GoRoute(
      path: '/officer/visit-log',
      pageBuilder: (context, state) => buildSmoothSlideUpPage(
        key: state.pageKey,
        child: const OfficerVisitLogScreen(),
      ),
    ),
    GoRoute(
      path: '/officer/profile',
      pageBuilder: (context, state) => buildSmoothPushPage(
        key: state.pageKey,
        child: const OfficerProfileScreen(),
      ),
    ),
    GoRoute(
      path: '/officer/send-advice',
      pageBuilder: (context, state) => buildSmoothSlideUpPage(
        key: state.pageKey,
        child: const OfficerSendAdviceScreen(),
      ),
    ),
    GoRoute(
      path: '/officer/reports',
      pageBuilder: (context, state) => buildSmoothPushPage(
        key: state.pageKey,
        child: const OfficerReportsScreen(),
      ),
    ),
  ],
);
