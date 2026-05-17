import 'package:flutter/material.dart';

class AppColors {
  static const Color seed = Color(0xFF5B4BD8);

  static const Color primary = Color(0xFF6A57E6);
  static const Color primaryLight = Color(0xFF8A75F0);

  static const Color scaffoldTop = Color(0xFFF2EEFF);
  static const Color scaffoldBottom = Color(0xFFF8FAFF);
  static const Color surfaceSoft = Color(0xFFF1F4FB);
  static const Color surfaceMuted = Color(0xFFF7F8FA);
  static const Color surfaceMutedAlt = Color(0xFFEDEFF5);
  static const Color overlay = Color(0xFF000000);

  static const Color textPrimary = Color(0xFF32363D);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLabel = Color(0xFF666A70);
  static const Color textMuted = Color(0xFF777777);
  static const Color iconMuted = Color(0xFFADB3BE);
  static const Color chipBackground = Color(0xFFF3F4FF);

  static const Color white = Colors.white;
  static const Color transparent = Colors.transparent;

  static const Color loginShadow = Color(0x336A57E6);
  static const Color cardShadow = Color(0x12000000);
  static const Color softShadow = Color(0x14000000);
  static const Color bottomSheetShadow = Color(0x0A000000);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient appBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [scaffoldTop, scaffoldBottom],
  );

  static const LinearGradient mascotInnerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceMuted, surfaceMutedAlt],
  );
}
