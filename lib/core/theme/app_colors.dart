import 'package:flutter/material.dart';

/// Locked theme color tokens for AquaVerse AI.
/// Full palette per AquaVerse_AI_Design_System.md visual design system.
abstract class AppColors {
  // ── Brand Primary (Aqua/Teal) ──────────────────────────────────────────────
  static const Color primary900 = Color(0xFF124C73);
  static const Color primary800 = Color(0xFF075B86);
  static const Color primary700 = Color(0xFF08749A);
  static const Color primary600 = Color(0xFF1495AE);
  static const Color primary500 = Color(0xFF27AFC0); // Primary CTA
  static const Color primary400 = Color(0xFF55C4C8);
  static const Color primary300 = Color(0xFF8DD9DB);
  static const Color primary200 = Color(0xFFB9E8EA);
  static const Color primary100 = Color(0xFFDDF3F4);

  // ── Brand Mountain (Deep Blue) ─────────────────────────────────────────────
  static const Color mountain900 = Color(0xFF123F68);
  static const Color mountain700 = Color(0xFF176F9C);
  static const Color mountain500 = Color(0xFF4BA8C1);
  static const Color mountain200 = Color(0xFFCBEAF0);

  // ── Natural Green Accent ───────────────────────────────────────────────────
  static const Color green700 = Color(0xFF24866F);
  static const Color green600 = Color(0xFF35A58A); // Success
  static const Color green200 = Color(0xFFCDEEE3);
  static const Color green100 = Color(0xFFEAF8F3);

  // ── Surface / Background ───────────────────────────────────────────────────
  static const Color background = Color(0xFFF7FBFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFD8E8ED);
  static const Color borderStrong = Color(0xFFB9D6DF);
  
  static const Color surfaceSoft = Color(0xFFF5FAFB);
  static const Color surfaceAqua = Color(0xFFEDF8FA);
  static const Color surfaceGreen = Color(0xFFEFF9F5);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF153B56);
  static const Color textSecondary = Color(0xFF557384);
  static const Color textMuted = Color(0xFF7D949F);
  static const Color textDisabled = Color(0xFFA9B9BF);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color warning = Color(0xFFE8A33A);
  static const Color critical = Color(0xFFE45D67);
  static const Color info = Color(0xFF3189D2);
  
  static const Color criticalSurface = Color(0xFFFFF0F1);
  static const Color criticalBorder = Color(0xFFF2C0C5);
  
  static const Color warningSurface = Color(0xFFFFF7E8);
  static const Color warningBorder = Color(0xFFF2D7A5);
  
  static const Color infoSurface = Color(0xFFEEF7FF);
  static const Color infoBorder = Color(0xFFC6E0F5);

  // ===========================================================================
  // LEGACY ALIASES (Do not use for new UI, mapped to prevent compilation errors)
  // ===========================================================================
  static const Color deepNavy = mountain900;
  static const Color midBlue = primary700;
  static const Color seaGreen = green600;
  static const Color brightMint = primary400;
  static const Color aqua = primary500;
  static const Color lightCyan = primary300;
  static const Color paleSky = mountain200;
  static const Color scaffoldBg = background;
  static const Color cardBg = surface;
  static const Color paleSkyBg = surfaceAqua;
  static const Color success = green600;
  static const Color divider = border;
}
