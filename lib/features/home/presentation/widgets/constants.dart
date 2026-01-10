/// Constants for the Home feature presentation layer.
///
/// This file centralizes all magic numbers, dimensions, durations, and other
/// constants used throughout the Home feature widgets. This improves
/// maintainability by providing a single source of truth for these values.
library;

import 'package:flutter/material.dart';

/// Animation durations used across home widgets.
abstract final class HomeAnimationDurations {
  /// Standard transition duration for most animations.
  static const Duration standard = Duration(milliseconds: 300);

  /// Fast transition for subtle UI feedback.
  static const Duration fast = Duration(milliseconds: 200);

  /// Extended duration for more prominent animations.
  static const Duration extended = Duration(milliseconds: 400);

  /// Shimmer effect duration for skeleton loaders.
  static const Duration shimmer = Duration(milliseconds: 1500);

  /// Theme switcher slide animation.
  static const Duration themeSwitcher = Duration(milliseconds: 250);
}

/// Standard spacing values used in home widgets.
abstract final class HomeSpacing {
  /// Extra small spacing (4.0).
  static const double xs = 4.0;

  /// Small spacing (8.0).
  static const double sm = 8.0;

  /// Medium spacing (12.0).
  static const double md = 12.0;

  /// Standard spacing (16.0).
  static const double standard = 16.0;

  /// Large spacing (20.0).
  static const double lg = 20.0;

  /// Extra large spacing (24.0).
  static const double xl = 24.0;

  /// XX large spacing (32.0).
  static const double xxl = 32.0;

  /// Content horizontal padding.
  static const double contentHorizontal = 20.0;

  /// Content vertical padding.
  static const double contentVertical = 12.0;
}

/// Border radius values used in home widgets.
abstract final class HomeBorderRadius {
  /// Small radius (8.0).
  static const double sm = 8.0;

  /// Medium radius (12.0).
  static const double md = 12.0;

  /// Standard radius (14.0).
  static const double standard = 14.0;

  /// Large radius (16.0).
  static const double lg = 16.0;

  /// Extra large radius (20.0).
  static const double xl = 20.0;

  /// XX large radius (24.0).
  static const double xxl = 24.0;

  /// Circular/pill radius (30.0).
  static const double circular = 30.0;

  /// Drawer corner radius.
  static const double drawer = 24.0;
}

/// Icon sizes used in home widgets.
abstract final class HomeIconSizes {
  /// Small icon size (14.0).
  static const double sm = 14.0;

  /// Medium icon size (18.0).
  static const double md = 18.0;

  /// Standard icon size (20.0).
  static const double standard = 20.0;

  /// Large icon size (22.0).
  static const double lg = 22.0;

  /// Extra large icon size (24.0).
  static const double xl = 24.0;

  /// XX large icon size (28.0).
  static const double xxl = 28.0;

  /// Back to top FAB icon size.
  static const double fabIcon = 32.0;
}

/// Shimmer effect colors for skeleton loading states.
abstract final class HomeShimmerColors {
  /// Base color for dark mode shimmer.
  static const Color darkBase = Color(0xFF303030);

  /// Highlight color for dark mode shimmer.
  static const Color darkHighlight = Color(0xFF424242);

  /// Base color for light mode shimmer.
  static const Color lightBase = Color(0xFFE0E0E0);

  /// Highlight color for light mode shimmer.
  static const Color lightHighlight = Color(0xFFFAFAFA);
}

/// Dimension values for specific home widgets.
abstract final class HomeDimensions {
  /// Standard toolbar height.
  static const double toolbarHeight = 56.0;

  /// Search bar height.
  static const double searchBarHeight = 50.0;

  /// Theme switcher height.
  static const double themeSwitcherHeight = 46.0;

  /// Drawer width for wide screens.
  static const double drawerWidthWide = 400.0;

  /// Drawer width factor for narrow screens.
  static const double drawerWidthFactor = 0.85;

  /// Back to top FAB size.
  static const double fabSize = 56.0;

  /// Scroll offset threshold to show back-to-top FAB.
  static const double backToTopThreshold = 300.0;

  /// Nav tile icon container size.
  static const double navTileIconSize = 34.0;

  /// Badge size for notification indicators.
  static const double badgeSize = 10.0;

  /// Badge size for update indicators.
  static const double updateBadgeSize = 12.0;
}

/// Opacity values used throughout home widgets.
abstract final class HomeOpacity {
  /// Very subtle opacity (0.05).
  static const double verySubtle = 0.05;

  /// Subtle opacity (0.1).
  static const double subtle = 0.1;

  /// Low opacity (0.2).
  static const double low = 0.2;

  /// Medium-low opacity (0.3).
  static const double mediumLow = 0.3;

  /// Medium opacity (0.4).
  static const double medium = 0.4;

  /// Medium-high opacity (0.5).
  static const double mediumHigh = 0.5;

  /// High opacity (0.6).
  static const double high = 0.6;

  /// Very high opacity (0.8).
  static const double veryHigh = 0.8;
}

/// Blur sigma values for backdrop filters.
abstract final class HomeBlurSigma {
  /// Standard blur intensity.
  static const double standard = 10.0;

  /// Strong blur intensity.
  static const double strong = 15.0;

  /// Subtle blur for permission dialog.
  static const double permission = 8.0;
}
