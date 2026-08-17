import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(
    const ProviderScope(
      child: AquaVerseApp(),
    ),
  );
}

class AquaVerseApp extends StatelessWidget {
  const AquaVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AquaVerse AI',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: AppTheme.light,
      locale: const Locale('ta'),
      supportedLocales: const [
        Locale('ta'),
        Locale('en'),
        Locale('hi'),
        Locale('te'),
      ],
      localizationsDelegates: const [
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
