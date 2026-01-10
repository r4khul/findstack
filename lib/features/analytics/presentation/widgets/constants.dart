/// Constants for the Analytics feature presentation layer.
///
/// This file centralizes all magic numbers, dimensions, durations, and other
/// constants used throughout the Analytics feature widgets.
library;

import 'package:flutter/material.dart';

/// Animation durations used across analytics widgets.
abstract final class AnalyticsAnimationDurations {
  /// Standard transition duration for most animations.
  static const Duration standard = Duration(milliseconds: 300);

  /// Fast transition for chart interactions.
  static const Duration fast = Duration(milliseconds: 200);

  /// Chart pie section animation.
  static const Duration chart = Duration(milliseconds: 400);

  /// Progress bar animation.
  static const Duration progressBar = Duration(milliseconds: 500);
}

/// Chart configuration constants.
abstract final class ChartConfig {
  /// Default center space radius for pie charts.
  static const double centerSpaceRadius = 70.0;

  /// Pie section radius when not touched.
  static const double sectionRadius = 55.0;

  /// Pie section radius when touched.
  static const double sectionRadiusTouched = 65.0;

  /// Badge position offset percentage.
  static const double badgePositionOffset = 0.98;

  /// Spacing between pie sections.
  static const double sectionsSpace = 2.0;

  /// Chart height.
  static const double chartHeight = 300.0;
}

/// Standard spacing values.
abstract final class AnalyticsSpacing {
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
}

/// Border radius values.
abstract final class AnalyticsBorderRadius {
  /// Small radius (8.0).
  static const double sm = 8.0;

  /// Medium radius (12.0).
  static const double md = 12.0;

  /// Standard radius (16.0).
  static const double standard = 16.0;

  /// Large radius (20.0).
  static const double lg = 20.0;

  /// Extra large radius (24.0).
  static const double xl = 24.0;

  /// Card radius (32.0).
  static const double card = 32.0;
}

/// Badge/icon sizes.
abstract final class AnalyticsIconSizes {
  /// Small badge size (20.0).
  static const double badgeSm = 20.0;

  /// Medium badge size (28.0).
  static const double badgeMd = 28.0;

  /// Large badge size (36.0).
  static const double badgeLg = 36.0;

  /// App icon size (48.0).
  static const double appIcon = 48.0;
}

/// Colors for storage breakdown charts.
abstract final class StorageColors {
  /// App/code storage color.
  static const Color appCode = Colors.blue;

  /// User data storage color.
  static const Color userData = Colors.green;

  /// Cache storage color.
  static const Color cache = Colors.orange;
}
