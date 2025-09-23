import 'package:flutter/material.dart';

class AppColors {
  // Main colors based on the Figma design
  static const Color primary = Color(0xFF4880FF);
  static const Color secondary = Color(0xFF568AFF);
  static const Color background = Colors.white;
  static const Color textPrimary = Color(0xFF202224);
  static const Color textSecondary = Color(0xFFA6A6A6);
  static const Color inputBackground = Color(0xFFF1F4F9);
  static const Color inputBorder = Color(0xFFD8D8D8);
  static const Color checkboxBorder = Color(0xFFA3A3A3);
}

class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.bold,
    fontSize: 64,
    letterSpacing: -1.28,
    color: Color(0xFF333333),
  );

  static const TextStyle title = TextStyle(
    fontFamily: 'Nunito Sans',
    fontWeight: FontWeight.bold,
    fontSize: 32,
    letterSpacing: -0.11,
    color: Color(0xFF202224),
  );

  static const TextStyle buttonText = TextStyle(
    fontFamily: 'Nunito Sans',
    fontWeight: FontWeight.bold,
    fontSize: 20,
    letterSpacing: -0.07,
    color: Colors.white,
  );

  static const TextStyle bodyText = TextStyle(
    fontFamily: 'Nunito Sans',
    fontWeight: FontWeight.w600,
    fontSize: 18,
    letterSpacing: -0.06,
    color: Color(0xFF202224),
  );

  static const TextStyle bodyTextLight = TextStyle(
    fontFamily: 'Nunito Sans',
    fontWeight: FontWeight.w600,
    fontSize: 18,
    letterSpacing: -0.06,
    color: Color(0xFFA6A6A6),
  );
}
