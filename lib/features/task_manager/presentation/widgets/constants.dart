library;

abstract class TaskManagerDurations {
  static const Duration minLoadingWait = Duration(milliseconds: 2500);

  static const Duration refreshInterval = Duration(seconds: 5);

  static const Duration stageTransition = Duration(milliseconds: 1200);

  static const Duration switcherTransition = Duration(milliseconds: 800);

  static const Duration livePulse = Duration(seconds: 1);
}

abstract class TaskManagerSizes {
  static const double appIconSize = 40.0;

  static const double iconSizeSmall = 14.0;

  static const double iconSize = 20.0;

  static const double iconSizeLarge = 32.0;

  static const double searchBarHeight = 50.0;

  static const double pidContainerPadding = 8.0;

  static const double liveIndicatorDotSize = 6.0;

  static const double dividerWidth = 1.0;

  static const double dividerHeight = 30.0;

  static const double progressBarHeight = 6.0;
}

abstract class TaskManagerSpacing {
  static const double xs = 2.0;

  static const double sm = 4.0;

  static const double md = 8.0;

  static const double standard = 12.0;

  static const double lg = 16.0;

  static const double xl = 24.0;

  static const double sectionHorizontal = 20.0;

  static const double sectionTop = 24.0;

  static const double userSectionTop = 32.0;

  static const double sectionBottom = 8.0;

  static const double listBottom = 32.0;
}

abstract class TaskManagerBorderRadius {
  static const double sm = 4.0;

  static const double md = 8.0;

  static const double standard = 12.0;

  static const double lg = 16.0;

  static const double xl = 32.0;

  static const double badge = 12.0;
}

abstract class TaskManagerOpacity {
  static const double verySubtle = 0.02;

  static const double subtle = 0.05;

  static const double light = 0.1;

  static const double mediumLight = 0.2;

  static const double standard = 0.3;

  static const double headerLabel = 0.4;

  static const double half = 0.5;

  static const double high = 0.7;

  static const double nearlyOpaque = 0.8;
}

abstract class TaskManagerFontSizes {
  static const double tiny = 8.0;

  static const double xs = 9.0;

  static const double sm = 10.0;

  static const double labelSmall = 11.0;

  static const double body = 13.0;

  static const double standard = 16.0;
}
