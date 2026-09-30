import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/localization/app_translations.dart';
import 'core/providers/shared_preferences_provider.dart';
import 'core/router/app_router.dart';
import 'core/sync/connectivity_service.dart';
import 'core/sync/outbox_processor.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const AquaVerseApp(),
    ),
  );
}

class AquaVerseApp extends ConsumerWidget {
  const AquaVerseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(appLanguageProvider);

    // Listen to real-time connectivity
    ref.listen<AsyncValue<bool>>(connectivityProvider, (prev, next) {
      final isOnline = next.valueOrNull ?? true;
      ref.read(isOfflineProvider.notifier).state = !isOnline;

      // When transitioning to online, trigger outbox processor
      final wasOffline = prev?.valueOrNull == false;
      if (wasOffline && isOnline) {
        ref.read(outboxProcessorProvider).syncOutbox();
      }
    });

    return MaterialApp.router(
      title: 'AquaVerse AI',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: AppTheme.light,
      locale: Locale(currentLang),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Ensure text scale doesn't exceed 1.3 to prevent layout breaks
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.85, 1.3),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}

// ── App-wide connectivity state ──────────────────────────────────────────────
final isOfflineProvider = StateProvider<bool>((ref) => false);
final syncStatusProvider = StateProvider<String?>((ref) => null);
// 'null' = idle | '2/3 syncing' | 'Synced' | 'Failed'

