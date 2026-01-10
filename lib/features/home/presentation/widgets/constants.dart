library;

import 'package:flutter/material.dart';

abstract final class HomeAnimationDurations {
  static const Duration standard = Duration(milliseconds: 300);

  static const Duration fast = Duration(milliseconds: 200);

  static const Duration extended = Duration(milliseconds: 400);

  static const Duration shimmer = Duration(milliseconds: 1500);

  static const Duration themeSwitcher = Duration(milliseconds: 250);
}

abstract final class HomeSpacing {
  static const double xs = 4.0;

  static const double sm = 8.0;

  static const double md = 12.0;

  static const double standard = 16.0;

  static const double lg = 20.0;

  static const double xl = 24.0;

  static const double xxl = 32.0;

  static const double contentHorizontal = 20.0;

  static const double contentVertical = 12.0;
}

abstract final class HomeBorderRadius {
  static const double sm = 8.0;

  static const double md = 12.0;

  static const double standard = 14.0;

  static const double lg = 16.0;

  static const double xl = 20.0;

  static const double xxl = 24.0;

  static const double circular = 30.0;

  static const double drawer = 24.0;
}

abstract final class HomeIconSizes {
  static const double sm = 14.0;

  static const double md = 18.0;

  static const double standard = 20.0;

  static const double lg = 22.0;

  static const double xl = 24.0;

  static const double xxl = 28.0;

  static const double fabIcon = 32.0;
}

abstract final class HomeShimmerColors {
  static const Color darkBase = Color(0xFF303030);

  static const Color darkHighlight = Color(0xFF424242);

  static const Color lightBase = Color(0xFFE0E0E0);

  static const Color lightHighlight = Color(0xFFFAFAFA);
}

abstract final class HomeDimensions {
  static const double toolbarHeight = 56.0;

  static const double searchBarHeight = 50.0;

  static const double themeSwitcherHeight = 46.0;

  static const double drawerWidthWide = 400.0;

  static const double drawerWidthFactor = 0.85;

  static const double fabSize = 56.0;

  static const double backToTopThreshold = 300.0;

  static const double navTileIconSize = 34.0;

  static const double badgeSize = 10.0;

  static const double updateBadgeSize = 12.0;
}

abstract final class HomeOpacity {
  static const double verySubtle = 0.05;

  static const double subtle = 0.1;

  static const double low = 0.2;

  static const double mediumLow = 0.3;

  static const double medium = 0.4;

  static const double mediumHigh = 0.5;

  static const double high = 0.6;

  static const double veryHigh = 0.8;
}

abstract final class HomeBlurSigma {
  static const double standard = 10.0;

  static const double strong = 15.0;

  static const double permission = 8.0;
}
