import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KidsTheme {
  // Playful Color Palette
  static const Color red = Color(0xFFFF5964);
  static const Color orange = Color(0xFFFF9F1C);
  static const Color yellow = Color(0xFFFFD166);
  static const Color green = Color(0xFF06D6A0);
  static const Color blue = Color(0xFF118AB2);
  static const Color purple = Color(0xFF8338EC);
  static const Color pink = Color(0xFFFF007F);

  static const Color background = Color(0xFFFFFDF9);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2B2D42);
  static const Color textLight = Color(0xFF8D99AE);
  static const Color borderDark = Color(0xFF2B2D42);

  // Soft gradient color pairs per game tile
  static const Map<String, List<Color>> gameGradients = {
    'pink':   [Color(0xFFFF6EB4), Color(0xFFFF9AD5)],
    'yellow': [Color(0xFFFFB347), Color(0xFFFFD700)],
    'blue':   [Color(0xFF4FC3F7), Color(0xFF0288D1)],
    'purple': [Color(0xFFCE93D8), Color(0xFF8338EC)],
    'orange': [Color(0xFFFF9F1C), Color(0xFFFF6B35)],
    'red':    [Color(0xFFFF5964), Color(0xFFE84393)],
    'green':  [Color(0xFF43E97B), Color(0xFF06D6A0)],
    'brown':  [Color(0xFFA1887F), Color(0xFF795548)],
    'teal':   [Color(0xFF26C6DA), Color(0xFF00897B)],
    'indigo': [Color(0xFF7986CB), Color(0xFF3F51B5)],
    'lime':   [Color(0xFFAED581), Color(0xFF8BC34A)],
    'amber':  [Color(0xFFFFCA28), Color(0xFFFFA000)],
  };

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.nunitoTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: orange,
      colorScheme: const ColorScheme.light(
        primary: orange,
        secondary: yellow,
        tertiary: green,
        error: red,
        surface: cardBg,
        onPrimary: Colors.white,
        onSecondary: textDark,
        onSurface: textDark,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: textDark,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: textDark,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 16,
          color: textDark,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: borderDark, width: 4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: borderDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: borderDark, width: 4),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Soft shadow (no harsh outline)
  static List<BoxShadow> get softShadows => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          offset: const Offset(0, 4),
          blurRadius: 16,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.8),
          offset: const Offset(0, -1),
          blurRadius: 4,
        ),
      ];

  // Legacy hard shadows (for compatibility)
  static List<BoxShadow> get kidShadows => [
        const BoxShadow(
          color: borderDark,
          offset: Offset(4, 4),
          blurRadius: 0,
        ),
      ];

  // Gradient-based tile decoration
  static BoxDecoration gradientDecoration({
    required List<Color> colors,
    double borderRadius = 28,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: colors.last.withValues(alpha: 0.4),
          offset: const Offset(0, 6),
          blurRadius: 16,
          spreadRadius: 0,
        ),
      ],
    );
  }

  // Toy-like container decoration helper (legacy)
  static BoxDecoration toyDecoration({
    required Color color,
    double borderRadius = 24,
    double borderWidth = 4,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderDark, width: borderWidth),
      boxShadow: kidShadows,
    );
  }

  // Soft card decoration (no border)
  static BoxDecoration softDecoration({
    required Color color,
    double borderRadius = 24,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: softShadows,
    );
  }

  static final Random _random = Random();
  static Color getRandomColor() {
    final colors = [red, orange, yellow, green, blue, purple, pink];
    return colors[_random.nextInt(colors.length)];
  }
}
