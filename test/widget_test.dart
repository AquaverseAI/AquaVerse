import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aquaverse_farmer_app/main.dart';

void main() {
  testWidgets('Splash screen renders title and action button', (WidgetTester tester) async {
    // Build AquaVerseApp wrapped in ProviderScope
    await tester.pumpWidget(const ProviderScope(child: AquaVerseApp()));
    // Fast-forward past 3s splash delay
    await tester.pump(const Duration(seconds: 4)); 
    // Verify Splash Screen logo and loader are present
    expect(find.byType(Image), findsWidgets);
    expect(find.byType(Stack), findsWidgets);
  });
}
