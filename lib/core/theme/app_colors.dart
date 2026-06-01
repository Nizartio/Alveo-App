import 'package:flutter/material.dart';

class AppColors {
  static const Color seed = Color(0xFF5B4BD8);

  static const Color primary = Color(0xFF6A57E6);
  static const Color primaryLight = Color(0xFF8A75F0);
  static const Color primaryDeep = Color(0xFF4834DF);
  static const Color brandBlue = Color(0xFF6B5CE7);
  static const Color brandBlueAlt = Color(0xFF4361EE);
  static const Color brandPurple = Color(0xFF7B66FF);
  static const Color brandPurpleLight = Color(0xFFA594FF);
  static const Color background = Color(0xFFF5F3FF);
  static const Color scaffoldNeutral = Color(0xFFF8F9FE);

  static const Color scaffoldTop = Color(0xFFF2EEFF);
  static const Color scaffoldBottom = Color(0xFFF8FAFF);
  static const Color surfaceSoft = Color(0xFFF1F4FB);
  static const Color surfaceMuted = Color(0xFFF7F8FA);
  static const Color surfaceMutedAlt = Color(0xFFEDEFF5);
  static const Color surfaceTint = Color(0xFFF5F3FF);
  static const Color surfaceBlueTint = Color(0xFFD7E3FF);
  static const Color surfaceWarm = Color(0xFFE6E6E6);
  static const Color overlay = Color(0xFF000000);

  static const Color textHeading = Color(0xFF2D2D2D);
  static const Color textTitleDark = Color(0xFF1A1640);
  static const Color textPrimary = Color(0xFF32363D);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textBody = Color(0xFF6B6B6B);
  static const Color textSubtle = Color(0xFF9E9AB8);
  static const Color textLabel = Color(0xFF666A70);
  static const Color textMuted = Color(0xFF777777);
  static const Color textMutedSoft = Color(0xFF94A3B8);
  static const Color textNavy = Color(0xFF374151);
  static const Color iconMuted = Color(0xFFADB3BE);
  static const Color chipBackground = Color(0xFFF3F4FF);
  static const Color progressTrack = Color(0xFFE5E7EB);
  static const Color progressAccent = Color(0xFF14B8A6);
  static const Color danger = Color(0xFFE06565);
  static const Color dangerSoft = Color(0xFFFF6B6B);
  static const Color bubbleMuted = Color(0xFFE7E0FF);
  static const Color bubbleMutedAlt = Color(0xFFF7F3FF);
  static const Color bubbleCool = Color(0xFFEAF0FF);
  static const Color bubbleCoolAlt = Color(0xFFF7FBFF);
  static const Color bubbleSoft = Color(0xFFF6F3FF);
  static const Color bubbleSky = Color(0xFFB39DFF);
  static const Color bubbleMint = Color(0xFF78FFD9);
  static const Color bubbleBlue = Color(0xFF8FB8FF);
  static const Color bubbleBlueAlt = Color(0xFFD9EEFF);
  static const Color mutedDivider = Color(0xFFE6E6E6);

  static const Color white = Colors.white;
  static const Color transparent = Colors.transparent;
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color white85 = Color(0xD9FFFFFF);
  static const Color white88 = Color(0xE0FFFFFF);
  static const Color white90 = Color(0xE6FFFFFF);
  static const Color white20 = Color(0x33FFFFFF);
  static const Color white15 = Color(0x26FFFFFF);
  static const Color white10 = Color(0x1AFFFFFF);
  static const Color black03 = Color(0x08000000);
  static const Color black04 = Color(0x0A000000);
  static const Color black12 = Color(0x1F000000);
  static const Color black14 = Color(0x24000000);
  static const Color black16 = Color(0x29000000);
  static const Color black54 = Color(0x8A000000);

  static const Color loginShadow = Color(0x336A57E6);
  static const Color cardShadow = Color(0x12000000);
  static const Color softShadow = Color(0x14000000);
  static const Color bottomSheetShadow = Color(0x0A000000);
  static const Color headerShadow = Color(0x08000000);
  static const Color navShadow = Color(0x2E6B5CE7);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandGradient = LinearGradient(
    colors: [brandBlue, brandBlueAlt],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient streakGradient = LinearGradient(
    colors: [brandPurple, brandPurpleLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient appBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [scaffoldTop, scaffoldBottom],
  );

  static const LinearGradient softSurfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bubbleSoft, scaffoldBottom],
  );

  static const LinearGradient loginBlobGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bubbleMuted, bubbleMutedAlt],
  );

  static const LinearGradient loginBlobCoolGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bubbleCool, bubbleCoolAlt],
  );

  static const LinearGradient splashBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bubbleSoft, scaffoldBottom],
  );

  static const LinearGradient splashBadgeGradient = LinearGradient(
    colors: [bubbleSky, bubbleMint],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashAccentGradient = LinearGradient(
    colors: [bubbleBlue, bubbleBlueAlt],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mascotInnerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceMuted, surfaceMutedAlt],
  );
}
