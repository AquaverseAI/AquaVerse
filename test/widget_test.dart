import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aquaverse_farmer_app/main.dart';
import 'package:aquaverse_farmer_app/shared/widgets/orbit_dots_loader.dart';

void main() {
  testWidgets('AquaVerseApp initializes and renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AquaVerseApp()));
    expect(find.byType(Scaffold), findsWidgets);
  });

  testWidgets('OrbitDotsLoader renders successfully with 2 orbiting dots', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OrbitDotsLoader(size: 48, dotSize: 12),
        ),
      ),
    );

    expect(find.byType(OrbitDotsLoader), findsOneWidget);
    expect(find.byType(Stack), findsWidgets);
  });
}
