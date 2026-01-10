/// Centralized constants for the Task Manager feature.
///
/// This file contains all UI-related constants used across task manager
/// widgets to ensure consistency and maintainability.
library;

// =============================================================================
// ANIMATION DURATIONS
// =============================================================================

/// Standard animation durations used in the task manager.
abstract class TaskManagerDurations {
  /// Minimum wait time for system stats loading.
  static const Duration minLoadingWait = Duration(milliseconds: 2500);

  /// Refresh interval for system stats.
  static const Duration refreshInterval = Duration(seconds: 5);

  /// Status message stage transition.
  static const Duration stageTransition = Duration(milliseconds: 1200);

  /// Animated switcher transition.
  static const Duration switcherTransition = Duration(milliseconds: 800);

  /// Live indicator pulse.
  static const Duration livePulse = Duration(seconds: 1);
}

// =============================================================================
// SIZING & DIMENSIONS
// =============================================================================

/// Standard sizes for UI elements.
abstract class TaskManagerSizes {
  /// App icon size.
  static const double appIconSize = 40.0;

  /// Small icon size.
  static const double iconSizeSmall = 14.0;

  /// Standard icon size.
  static const double iconSize = 20.0;

  /// Large icon size.
  static const double iconSizeLarge = 32.0;

  /// Search bar height.
  static const double searchBarHeight = 50.0;

  /// Process item PID container size.
  static const double pidContainerPadding = 8.0;

  /// Live indicator dot size.
  static const double liveIndicatorDotSize = 6.0;

  /// Divider width.
  static const double dividerWidth = 1.0;

  /// Divider height.
  static const double dividerHeight = 30.0;

  /// Progress bar height.
  static const double progressBarHeight = 6.0;
}

// =============================================================================
// SPACING & PADDING
// =============================================================================

/// Spacing values used in the task manager.
abstract class TaskManagerSpacing {
  /// Extra small spacing (2dp).
  static const double xs = 2.0;

  /// Small spacing (4dp).
  static const double sm = 4.0;

  /// Medium spacing (8dp).
  static const double md = 8.0;

  /// Standard spacing (12dp).
  static const double standard = 12.0;

  /// Large spacing (16dp).
  static const double lg = 16.0;

  /// Extra large spacing (24dp).
  static const double xl = 24.0;

  /// Section header horizontal padding.
  static const double sectionHorizontal = 20.0;

  /// Section header top padding.
  static const double sectionTop = 24.0;

  /// User space section top padding.
  static const double userSectionTop = 32.0;

  /// Section header bottom padding.
  static const double sectionBottom = 8.0;

  /// Bottom padding for list.
  static const double listBottom = 32.0;
}

// =============================================================================
// BORDER RADII
// =============================================================================

/// Border radius values for the task manager.
abstract class TaskManagerBorderRadius {
  /// Small radius for badges and small elements.
  static const double sm = 4.0;

  /// Medium radius for icon containers.
  static const double md = 8.0;

  /// Standard radius for cards.
  static const double standard = 12.0;

  /// Large radius for prominent cards.
  static const double lg = 16.0;

  /// XL radius for main cards.
  static const double xl = 32.0;

  /// Live indicator badge radius.
  static const double badge = 12.0;
}

// =============================================================================
// OPACITY VALUES
// =============================================================================

/// Opacity values for consistent transparency.
abstract class TaskManagerOpacity {
  /// Very subtle opacity.
  static const double verySubtle = 0.02;

  /// Subtle opacity for backgrounds.
  static const double subtle = 0.05;

  /// Light opacity.
  static const double light = 0.1;

  /// Medium-light opacity.
  static const double mediumLight = 0.2;

  /// Standard opacity.
  static const double standard = 0.3;

  /// Header label opacity.
  static const double headerLabel = 0.4;

  /// Half opacity.
  static const double half = 0.5;

  /// High opacity.
  static const double high = 0.7;

  /// Nearly opaque.
  static const double nearlyOpaque = 0.8;
}

// =============================================================================
// TEXT STYLES
// =============================================================================

/// Font size constants.
abstract class TaskManagerFontSizes {
  /// Very small text (8dp).
  static const double tiny = 8.0;

  /// Extra small text (9dp).
  static const double xs = 9.0;

  /// Small text (10dp).
  static const double sm = 10.0;

  /// Label small font size (11dp).
  static const double labelSmall = 11.0;

  /// Standard body text (13dp).
  static const double body = 13.0;

  /// Standard text (16dp).
  static const double standard = 16.0;
}
