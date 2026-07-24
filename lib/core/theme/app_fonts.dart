import 'package:flutter/material.dart';

class AppFonts {
  static TextStyle jua({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    Paint? foreground,
    List<Shadow>? shadows,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'sans-serif',
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color,
      foreground: foreground,
      shadows: shadows,
      height: height,
    );
  }
}
