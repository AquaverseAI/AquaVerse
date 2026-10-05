import 'package:go_router/go_router.dart';

import '../../shared/widgets/iris_transition.dart';
import '../../shared/widgets/smooth_page_transition.dart';

// Splash
import '../../features/splash/splash_screen.dart';

// Onboarding
import '../../features/onboarding/presentation/language_select_screen.dart';
import '../../features/onboarding/presentation/role_selection_screen.dart';
import '../../features/onboarding/presentation/phone_entry_screen.dart';
import '../../features/onboarding/presentation/otp_verify_screen.dart';

// Farmer Main
import '../../features/today/presentation/today_screen.dart';
import '../../features/log/presentation/log_entry_screen.dart';
import '../../features/ask/presentation/ask_screen.dart';
import '../../features/alerts/presentation/alerts_screen.dart';
import '../../features/crop/presentation/crop_screen.dart';

// Secondary
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/ponds/presentation/my_ponds_screen.dart';
import '../../features/ponds/presentation/pond_details_screen.dart';
import '../../features/help/presentation/help_center_screen.dart';

// Extension Officer
import '../../features/officer/presentation/officer_dashboard_screen.dart';
import '../../features/officer/presentation/officer_visit_log_screen.dart';
import '../../features/officer/presentation/officer_profile_screen.dart';

import 'route_guard.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    if (state.matchedLocation == '/') return null;
    final guard = await RouteGuard.getInstance();
    return guard.redirect(state.matchedLocation);
  },
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
        child: const RoleSelectionScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding/language',
      pageBuilder: (context, state) => buildIrisTransitionPage(
        key: state.pageKey,
        child: const LanguageSelectScreen(),
      ),
    ),
    // ── NEW: Role Selection — Step 1 of 2-screen auth flow ────────────────────
    GoRoute(
      path: '/onboarding/role',
      pageBuilder: (context, state) => buildSmoothPushPage(
        key: state.pageKey,
        child: const RoleSelectionScreen(),
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
  ],
);
