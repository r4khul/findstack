/// Centralized constants for the update feature.
///
/// This file contains all UI-related constants used across update widgets
/// to ensure consistency and maintainability. Magic numbers are eliminated
/// in favor of named constants.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

// =============================================================================
// ANIMATION DURATIONS
// =============================================================================

/// Standard animation durations used throughout the update feature.
abstract class UpdateAnimationDurations {
  /// Default animation duration for transitions.
  static const Duration standard = Duration(milliseconds: 300);

  /// Slower animation for more prominent transitions.
  static const Duration slow = Duration(milliseconds: 600);

  /// Slide in animation duration for banners.
  static const Duration slideIn = Duration(milliseconds: 800);

  /// Pulse animation duration for loading states.
  static const Duration pulse = Duration(milliseconds: 1500);

  /// Delay before showing soft update banner.
  static const Duration bannerDelay = Duration(seconds: 2);

  /// Delay after manual check before resetting state.
  static const Duration checkAgainDelay = Duration(milliseconds: 500);
}

// =============================================================================
// SIZING & DIMENSIONS
// =============================================================================

/// Standard sizes for UI elements in the update feature.
abstract class UpdateSizes {
  /// Hero icon size for main status display.
  static const double heroIconSize = 64.0;

  /// Standard icon size for buttons and indicators.
  static const double iconSize = 20.0;

  /// Small icon size for secondary elements.
  static const double iconSizeSmall = 18.0;

  /// Large icon size for error/status states.
  static const double iconSizeLarge = 56.0;

  /// Progress indicator size in loading state.
  static const double progressIndicatorSize = 32.0;

  /// Animated pulse circle size.
  static const double pulseCircleSize = 80.0;

  /// Version comparison arrow icon size.
  static const double versionArrowSize = 16.0;

  /// Button heights.
  static const double buttonHeight = 56.0;
  static const double buttonHeightCompact = 48.0;

  /// Changelog icon container size.
  static const double changelogIconContainerSize = 14.0;
}

// =============================================================================
// SPACING & PADDING
// =============================================================================

/// Spacing values used throughout the update feature.
abstract class UpdateSpacing {
  /// Extra small spacing (4dp).
  static const double xs = 4.0;

  /// Small spacing (8dp).
  static const double sm = 8.0;

  /// Medium spacing (12dp).
  static const double md = 12.0;

  /// Standard spacing (16dp).
  static const double standard = 16.0;

  /// Large spacing (20dp).
  static const double lg = 20.0;

  /// Extra large spacing (24dp).
  static const double xl = 24.0;

  /// XXL spacing (28dp).
  static const double xxl = 28.0;

  /// Hero spacing (32dp).
  static const double hero = 32.0;

  /// Section spacing (40dp).
  static const double section = 40.0;

  /// Large section spacing (48dp).
  static const double sectionLarge = 48.0;

  /// Bottom safe area spacing (80dp).
  static const double bottomSafeArea = 80.0;

  /// Bottom content padding for navbar clearance (120dp).
  static const double bottomNavClearance = 120.0;
}

// =============================================================================
// BORDER RADII
// =============================================================================

/// Border radius values for the update feature.
abstract class UpdateBorderRadius {
  /// Small radius for badges and small elements.
  static const double sm = 6.0;

  /// Medium radius for icon containers.
  static const double md = 12.0;

  /// Standard radius for cards.
  static const double standard = 16.0;

  /// Large radius for dialogs and prominent cards.
  static const double lg = 20.0;

  /// XL radius for modals and bottom bars.
  static const double xl = 24.0;

  /// Dialog radius.
  static const double dialog = 28.0;
}

// =============================================================================
// BLUR VALUES
// =============================================================================

/// Blur values for glassmorphism effects.
abstract class UpdateBlur {
  /// Standard blur for glassmorphism.
  static const double standard = 10.0;

  /// Large blur for ambient glow effects.
  static const double large = 80.0;

  /// Shadow blur radius.
  static const double shadow = 20.0;

  /// Large shadow blur radius.
  static const double shadowLarge = 30.0;

  /// Extra large shadow blur for hero elements.
  static const double shadowXL = 40.0;
}

// =============================================================================
// OPACITY VALUES
// =============================================================================

/// Opacity values for consistent transparency.
abstract class UpdateOpacity {
  /// Very subtle opacity.
  static const double verySubtle = 0.02;

  /// Subtle opacity for backgrounds.
  static const double subtle = 0.05;

  /// Light opacity for secondary elements.
  static const double light = 0.1;

  /// Medium opacity.
  static const double medium = 0.2;

  /// Standard opacity for overlays.
  static const double standard = 0.3;

  /// High opacity for semi-transparent elements.
  static const double high = 0.5;

  /// Very high opacity.
  static const double veryHigh = 0.8;

  /// Nearly opaque.
  static const double nearlyOpaque = 0.9;
}

// =============================================================================
// COLORS
// =============================================================================

/// Brand and semantic colors for the update feature.
abstract class UpdateColors {
  /// Success/install green color.
  static const Color installGreen = Color(0xFF00BB2D);

  /// Feature changelog color.
  static const Color featureGreen = Color(0xFF4CAF50);

  /// Fix changelog color.
  static const Color fixBlue = Color(0xFF2196F3);

  /// Dark card background.
  static const Color darkCardBackground = Color(0xFF1A1A1A);

  /// Light snackbar background.
  static const Color lightSnackbarBackground = Color(0xFFF0F0F0);
}

// =============================================================================
// IMAGE FILTER HELPERS
// =============================================================================

/// Helper method to create standard blur filter.
ImageFilter get standardBlurFilter =>
    ImageFilter.blur(sigmaX: UpdateBlur.standard, sigmaY: UpdateBlur.standard);

/// Helper method to create large blur filter for ambient effects.
ImageFilter get largeBlurFilter =>
    ImageFilter.blur(sigmaX: UpdateBlur.large, sigmaY: UpdateBlur.large);
