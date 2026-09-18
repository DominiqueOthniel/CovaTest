import 'package:flutter/material.dart';

class CovaColors {
  static const bg = Color(0xFF0F1C17);
  static const bgDeep = Color(0xFF0D1814);
  static const bgMid = Color(0xFF12231C);
  static const elevated = Color(0xFF172820);
  static const soft = Color(0xFF1E342A);
  static const hover = Color(0xFF243F33);
  static const line = Color(0xFF2D4A3C);
  static const text = Color(0xFFE8F2EC);
  static const muted = Color(0xFF9BB5A8);
  static const accent = Color(0xFF3ECF8E);
  static const accentStrong = Color(0xFF2AA86F);
  static const accentInk = Color(0xFF082216);
  static const danger = Color(0xFFEF6B6B);
  static const dangerSoft = Color(0x1FEF6B6B);
  static const info = Color(0xFF5BB8E8);
  static const glowGreen = Color(0x293ECF8E);
  static const glowBlue = Color(0x1F5BB8E8);
}

ThemeData buildCovaTheme() {
  final base = ColorScheme.fromSeed(
    seedColor: CovaColors.accent,
    brightness: Brightness.dark,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: base.copyWith(
      surface: CovaColors.elevated,
      primary: CovaColors.accent,
      onPrimary: CovaColors.accentInk,
      error: CovaColors.danger,
    ),
    scaffoldBackgroundColor: CovaColors.bg,
    splashFactory: InkRipple.splashFactory,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(
        color: CovaColors.text,
        height: 1.5,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      titleLarge: TextStyle(
        color: CovaColors.text,
        fontWeight: FontWeight.w700,
        fontSize: 26,
        height: 1.2,
        letterSpacing: -0.4,
      ),
      titleMedium: TextStyle(
        color: CovaColors.text,
        fontWeight: FontWeight.w700,
        fontSize: 18,
        height: 1.25,
        letterSpacing: -0.2,
      ),
      labelSmall: TextStyle(
        color: CovaColors.accent,
        letterSpacing: 2.6,
        fontWeight: FontWeight.w700,
        fontSize: 11,
      ),
      bodySmall: TextStyle(
        color: CovaColors.muted,
        fontSize: 13.5,
        height: 1.45,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CovaColors.soft,
      hintStyle: TextStyle(color: CovaColors.muted.withValues(alpha: 0.85)),
      labelStyle: const TextStyle(color: CovaColors.muted, fontSize: 13),
      floatingLabelStyle: const TextStyle(color: CovaColors.accent),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: CovaColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: CovaColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: CovaColors.accent, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: CovaColors.accent,
        foregroundColor: CovaColors.accentInk,
        disabledBackgroundColor: CovaColors.accent.withValues(alpha: 0.45),
        elevation: 0,
        shadowColor: CovaColors.accent.withValues(alpha: 0.35),
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: 0.1,
        ),
      ).copyWith(
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return 0;
          return 6;
        }),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: CovaColors.text,
        backgroundColor: Colors.transparent,
        side: const BorderSide(color: CovaColors.line),
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: CovaColors.soft,
      contentTextStyle: const TextStyle(color: CovaColors.text, fontWeight: FontWeight.w500),
      behavior: SnackBarBehavior.floating,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
