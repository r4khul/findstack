library;

import 'package:flutter/material.dart';

abstract final class AnalyticsAnimationDurations {
  static const Duration standard = Duration(milliseconds: 300);

  static const Duration fast = Duration(milliseconds: 200);

  static const Duration chart = Duration(milliseconds: 400);

  static const Duration progressBar = Duration(milliseconds: 500);
}

abstract final class ChartConfig {
  static const double centerSpaceRadius = 70.0;

  static const double sectionRadius = 55.0;

  static const double sectionRadiusTouched = 65.0;

  static const double badgePositionOffset = 0.98;

  static const double sectionsSpace = 2.0;

  static const double chartHeight = 300.0;
}

abstract final class AnalyticsSpacing {
  static const double xs = 4.0;

  static const double sm = 8.0;

  static const double md = 12.0;

  static const double standard = 16.0;

  static const double lg = 20.0;

  static const double xl = 24.0;

  static const double xxl = 32.0;

  static const double contentHorizontal = 20.0;
}

abstract final class AnalyticsBorderRadius {
  static const double sm = 8.0;

  static const double md = 12.0;

  static const double standard = 16.0;

  static const double lg = 20.0;

  static const double xl = 24.0;

  static const double card = 32.0;
}

abstract final class AnalyticsIconSizes {
  static const double badgeSm = 20.0;

  static const double badgeMd = 28.0;

  static const double badgeLg = 36.0;

  static const double appIcon = 48.0;
}

abstract final class StorageColors {
  static const Color appCode = Colors.blue;

  static const Color userData = Colors.green;

  static const Color cache = Colors.orange;
}
