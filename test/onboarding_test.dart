import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aquaverse_farmer_app/shared/widgets/speaker_button.dart';
import 'package:aquaverse_farmer_app/shared/widgets/status_disc.dart';
import 'package:aquaverse_farmer_app/shared/widgets/staleness_badge.dart';
import 'package:aquaverse_farmer_app/shared/widgets/blind_state_banner.dart';
import 'package:aquaverse_farmer_app/features/onboarding/presentation/language_select_screen.dart';
import 'package:aquaverse_farmer_app/features/onboarding/presentation/phone_entry_screen.dart';
import 'package:aquaverse_farmer_app/features/onboarding/presentation/role_selection_screen.dart';

void main() {
  group('Shared Widgets Verification', () {
    testWidgets('SpeakerButton renders and handles tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpeakerButton(textToSpeak: 'Test Audio Prompt'),
          ),
        ),
      );

      expect(find.byType(SpeakerButton), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_outlined), findsOneWidget);

      await tester.tap(find.byType(SpeakerButton));
      await tester.pump();

      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
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
    testWidgets('LanguageSelectScreen renders 4 languages and Next button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LanguageSelectScreen(),
          ),
        ),
      );

      expect(find.text('Select Language'), findsOneWidget);
      expect(find.text('தமிழ்'), findsOneWidget);
      expect(find.text('हिंदी'), findsOneWidget);
      expect(find.text('తెలుగు'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('PhoneEntryScreen renders fixed +91 prefix and Send OTP button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PhoneEntryScreen(),
          ),
        ),
      );

      expect(find.text('+91'), findsOneWidget);
      expect(find.text('Enter Mobile Number'), findsOneWidget);
      expect(find.text('Send OTP'), findsOneWidget);
    });

    testWidgets('RoleSelectionScreen renders Farmer and Extension Officer roles', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RoleSelectionScreen(),
          ),
        ),
      );

      expect(find.text('Select Your Role'), findsOneWidget);
      expect(find.text('Farmer'), findsOneWidget);
      expect(find.text('Extension Officer'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });
  });
}
