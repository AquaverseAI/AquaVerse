import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aquaverse_farmer_app/core/providers/shared_preferences_provider.dart';
import 'package:aquaverse_farmer_app/core/services/bhashini_tts_service.dart';
import 'package:aquaverse_farmer_app/shared/widgets/speaker_button.dart';
import 'package:aquaverse_farmer_app/shared/widgets/status_disc.dart';
import 'package:aquaverse_farmer_app/shared/widgets/staleness_badge.dart';
import 'package:aquaverse_farmer_app/shared/widgets/blind_state_banner.dart';
import 'package:aquaverse_farmer_app/features/onboarding/presentation/role_selection_screen.dart';
import 'package:aquaverse_farmer_app/features/onboarding/presentation/language_select_screen.dart';
import 'package:aquaverse_farmer_app/features/onboarding/presentation/phone_entry_screen.dart';

class FakeBhashiniTtsService implements BhashiniTtsService {
  @override
  Future<bool> speakText({required String text, required String langCode}) async => true;

  @override
  Future<void> stop() async {}
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('Shared Widgets Verification', () {
    testWidgets('SpeakerButton renders honest unavailable state and shows text on tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            bhashiniTtsServiceProvider.overrideWithValue(FakeBhashiniTtsService()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SpeakerButton(textToSpeak: 'Test Audio Prompt'),
            ),
          ),
        ),
      );

      expect(find.byType(SpeakerButton), findsOneWidget);
      expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);

      await tester.tap(find.byType(SpeakerButton));
      await tester.pump();

      expect(find.text('Audio not available'), findsOneWidget);
      expect(find.text('Test Audio Prompt'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('StatusDisc renders qualitative level', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusDisc(status: PondStatusLevel.good),
          ),
        ),
      );

      expect(find.text('Good'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('StalenessBadge renders timestamp label', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StalenessBadge(customText: 'Data as of 4h ago'),
          ),
        ),
      );

      expect(find.text('Data as of 4h ago'), findsOneWidget);
    });

    testWidgets('BlindStateBanner renders suppression alert', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BlindStateBanner(
              suppressionReason: 'Data unavailable — no log in 3 days. Alerts paused.',
            ),
          ),
        ),
      );

      expect(find.text('Alert Suppression Active'), findsOneWidget);
      expect(find.textContaining('no log in 3 days'), findsOneWidget);
    });
  });

  group('Onboarding Screens Flow Verification', () {
    testWidgets('LanguageSelectScreen renders English and Tamil cards and Continue button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: LanguageSelectScreen(),
          ),
        ),
      );

      expect(find.text('Select Language'), findsOneWidget);
      expect(find.text('English'), findsWidgets);
      expect(find.text('தமிழ்'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('RoleSelectionScreen renders Farmer and Extension Officer cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: RoleSelectionScreen(),
          ),
        ),
      );

      expect(find.text('Who are you?'), findsOneWidget);
      expect(find.text('Farmer'), findsOneWidget);
      expect(find.text('Extension Officer'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Please select a role to continue'), findsOneWidget);

      // Tap Farmer card -> validation text disappears
      await tester.tap(find.text('Farmer'));
      await tester.pump();
      expect(find.text('Please select a role to continue'), findsNothing);
    });

    testWidgets('PhoneEntryScreen renders fixed +91 prefix and Send OTP button with role summary', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: PhoneEntryScreen(),
          ),
        ),
      );

      expect(find.text('+91'), findsOneWidget);
      expect(find.text('Enter your phone number'), findsOneWidget);
      expect(find.text('Send OTP'), findsOneWidget);
      // Renders selected role summary chip with change option
      expect(find.text('Farmer'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
      // Crucial: full multi-card role selector must NOT be present
      expect(find.text('SELECT ACCOUNT ROLE'), findsNothing);
      expect(find.text('1 Pond Access'), findsNothing);
      expect(find.text('Multi-Pond Access'), findsNothing);
    });
  });
}
