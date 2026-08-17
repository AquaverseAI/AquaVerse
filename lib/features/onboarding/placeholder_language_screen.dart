import 'package:flutter/material.dart';
import 'presentation/language_select_screen.dart';

/// Legacy placeholder class delegating directly to the full LanguageSelectScreen.
class PlaceholderLanguageScreen extends StatelessWidget {
  const PlaceholderLanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LanguageSelectScreen();
  }
}
