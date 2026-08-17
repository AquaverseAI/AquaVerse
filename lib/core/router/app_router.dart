import 'package:go_router/go_router.dart';

import '../../shared/widgets/iris_transition.dart';

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

// Officer
import '../../features/officer/presentation/officer_dashboard_screen.dart';
import '../../features/officer/presentation/officer_visit_log_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // ── Initial Route ────────────────────────────────────────────────────────
    GoRoute(
      path: '/',
      builder: (context, state) => const LanguageSelectScreen(),
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
      builder: (context, state) => const PhoneEntryScreen(),
    ),
    GoRoute(
      path: '/onboarding/otp',
      builder: (context, state) => const OtpVerifyScreen(),
    ),
    GoRoute(
      path: '/onboarding/role',
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/onboarding/intro',
      builder: (context, state) => const AiIntroScreen(),
    ),

    // ── Farmer Main Screens ──────────────────────────────────────────────────
    GoRoute(
      path: '/today',
      builder: (context, state) => const TodayScreen(),
    ),
    GoRoute(
      path: '/log',
      builder: (context, state) => const LogEntryScreen(),
    ),
    GoRoute(
      path: '/ask',
      builder: (context, state) => const AskScreen(),
    ),
    GoRoute(
      path: '/alerts',
      builder: (context, state) => const AlertsScreen(),
    ),
    GoRoute(
      path: '/crop',
      builder: (context, state) => const CropScreen(),
    ),

    // ── Secondary Screens ────────────────────────────────────────────────────
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/ponds',
      builder: (context, state) => const MyPondsScreen(),
    ),
    GoRoute(
      path: '/pond-details',
      builder: (context, state) => const PondDetailsScreen(),
    ),
    GoRoute(
      path: '/help',
      builder: (context, state) => const HelpCenterScreen(),
    ),

    // ── Extension Officer ────────────────────────────────────────────────────
    GoRoute(
      path: '/officer/dashboard',
      builder: (context, state) => const OfficerDashboardScreen(),
    ),
    GoRoute(
      path: '/officer/visit-log',
      builder: (context, state) => const OfficerVisitLogScreen(),
    ),
  ],
);
