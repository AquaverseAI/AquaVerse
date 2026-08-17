import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aquaverse_farmer_app/main.dart';

void main() {
  testWidgets('AquaVerseApp initializes and renders initial screen', (WidgetTester tester) async {
    // Build AquaVerseApp wrapped in ProviderScope
    await tester.pumpWidget(const ProviderScope(child: AquaVerseApp()));
    await tester.pumpAndSettle();
    
    // Verify app renders scaffold and interactive widgets
    expect(find.byType(Scaffold), findsWidgets);
  });
}
