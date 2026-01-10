library;

import 'dart:ui';

import 'package:flutter/material.dart';

abstract class UpdateAnimationDurations {
  static const Duration standard = Duration(milliseconds: 300);

  static const Duration slow = Duration(milliseconds: 600);

  static const Duration slideIn = Duration(milliseconds: 800);

  static const Duration pulse = Duration(milliseconds: 1500);

  static const Duration bannerDelay = Duration(seconds: 2);

  static const Duration checkAgainDelay = Duration(milliseconds: 500);
}

abstract class UpdateSizes {
  static const double heroIconSize = 64.0;

  static const double iconSize = 20.0;

  static const double iconSizeSmall = 18.0;

  static const double iconSizeLarge = 56.0;

  static const double progressIndicatorSize = 32.0;

  static const double pulseCircleSize = 80.0;

  static const double versionArrowSize = 16.0;

  static const double buttonHeight = 56.0;
  static const double buttonHeightCompact = 48.0;

  static const double changelogIconContainerSize = 14.0;
}

abstract class UpdateSpacing {
  static const double xs = 4.0;

  static const double sm = 8.0;

  static const double md = 12.0;

  static const double standard = 16.0;

  static const double lg = 20.0;

  static const double xl = 24.0;

  static const double xxl = 28.0;

  static const double hero = 32.0;

  static const double section = 40.0;

  static const double sectionLarge = 48.0;

  static const double bottomSafeArea = 80.0;

  static const double bottomNavClearance = 120.0;
}

abstract class UpdateBorderRadius {
  static const double sm = 6.0;

  static const double md = 12.0;

  static const double standard = 16.0;

  static const double lg = 20.0;

  static const double xl = 24.0;

  static const double dialog = 28.0;
}

abstract class UpdateBlur {
  static const double standard = 10.0;

  static const double large = 80.0;

  static const double shadow = 20.0;

  static const double shadowLarge = 30.0;

  static const double shadowXL = 40.0;
}

abstract class UpdateOpacity {
  static const double verySubtle = 0.02;

  static const double subtle = 0.05;

  static const double light = 0.1;

  static const double medium = 0.2;

  static const double standard = 0.3;

  static const double high = 0.5;

  static const double veryHigh = 0.8;

  static const double nearlyOpaque = 0.9;
}

abstract class UpdateColors {
  static const Color installGreen = Color(0xFF00BB2D);

  static const Color featureGreen = Color(0xFF4CAF50);

  static const Color fixBlue = Color(0xFF2196F3);

  static const Color darkCardBackground = Color(0xFF1A1A1A);

  static const Color lightSnackbarBackground = Color(0xFFF0F0F0);
}

ImageFilter get standardBlurFilter =>
    ImageFilter.blur(sigmaX: UpdateBlur.standard, sigmaY: UpdateBlur.standard);

ImageFilter get largeBlurFilter =>
    ImageFilter.blur(sigmaX: UpdateBlur.large, sigmaY: UpdateBlur.large);
