import 'package:flutter/material.dart';

import 'design_tokens.dart';

enum DeviceType { mobile, tablet, desktop }

/// The four layout classes of the storefront architecture (§1.1 / §3.1).
///
/// `DeviceType` stays three-valued so existing callers keep their meaning;
/// use [Responsive.uiClass] where the four-class grid/cap system matters.
enum UiClass { compact, medium, expanded, wide }

class Responsive {
  static const double mobileMax = 600;
  static const double tabletMax = 1200;
  static const double wideMax = 1600;

  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobileMax) return DeviceType.mobile;
    if (width < tabletMax) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Four-class layout: compact < 600 ≤ medium < 1200 ≤ expanded < 1600 ≤ wide.
  static UiClass uiClass(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobileMax) return UiClass.compact;
    if (width < tabletMax) return UiClass.medium;
    if (width < wideMax) return UiClass.expanded;
    return UiClass.wide;
  }

  static bool isMobile(BuildContext context) =>
      getDeviceType(context) == DeviceType.mobile;
  static bool isTablet(BuildContext context) =>
      getDeviceType(context) == DeviceType.tablet;
  static bool isDesktop(BuildContext context) =>
      getDeviceType(context) == DeviceType.desktop;

  /// ≥ 1200: full header with horizontal nav (expanded or wide).
  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletMax;

  /// ≥ 1600: capped content, 5-column grids (§3.1).
  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wideMax;

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;
  static double height(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  /// Page content cap per class (§3.1): 1320 expanded, 1480 wide.
  static double contentCap(BuildContext context) {
    switch (uiClass(context)) {
      case UiClass.wide:
        return 1480;
      case UiClass.expanded:
        return 1320;
      case UiClass.medium:
      case UiClass.compact:
        return double.infinity;
    }
  }

  /// Horizontal page padding per class (§3.1): 16 / 24 / 32 / 40.
  static double pageInset(BuildContext context) {
    switch (uiClass(context)) {
      case UiClass.wide:
        return 40;
      case UiClass.expanded:
        return 32;
      case UiClass.medium:
        return 24;
      case UiClass.compact:
        return AppSpacing.screenH;
    }
  }

  /// Section vertical rhythm per class (§2.3): 32 / 40 / 56.
  static double sectionGap(BuildContext context) {
    switch (uiClass(context)) {
      case UiClass.wide:
      case UiClass.expanded:
        return AppSpacing.sectionGapExpanded;
      case UiClass.medium:
        return AppSpacing.sectionGapMedium;
      case UiClass.compact:
        return AppSpacing.sectionGapCompact;
    }
  }

  /// Grid gutter per class (§3.1): 12 / 16 / 24.
  static double gridGutter(BuildContext context) {
    switch (uiClass(context)) {
      case UiClass.wide:
      case UiClass.expanded:
        return AppSpacing.gutterExpanded;
      case UiClass.medium:
        return AppSpacing.gutterMedium;
      case UiClass.compact:
        return AppSpacing.gutterCompact;
    }
  }

  static double fontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }

  static double spacing(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }

  /// Product grid columns per class (§3.1): 2 / 3 / 4 / 5.
  static int gridColumns(BuildContext context) {
    switch (uiClass(context)) {
      case UiClass.wide:
        return 5;
      case UiClass.expanded:
        return 4;
      case UiClass.medium:
        return 3;
      case UiClass.compact:
        return 2;
    }
  }

  static double cardAspectRatio(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.desktop:
        // Taller cards → the photo takes the lion's share of the tile.
        return 0.74;
      case DeviceType.tablet:
        return 0.66;
      case DeviceType.mobile:
        return 0.56;
    }
  }

  static double iconSize(
    BuildContext context, {
    double mobile = 20,
    double? tablet,
    double? desktop,
  }) {
    return fontSize(context, mobile: mobile, tablet: tablet, desktop: desktop);
  }

  static EdgeInsets padding(
    BuildContext context, {
    double mobile = 16,
    double? tablet,
    double? desktop,
  }) {
    final value = spacing(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
    return EdgeInsets.all(value);
  }

  static EdgeInsets horizontalPadding(
    BuildContext context, {
    double mobile = 16,
    double? tablet,
    double? desktop,
  }) {
    final value = spacing(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
    return EdgeInsets.symmetric(horizontal: value);
  }

  static BorderRadius borderRadius(
    BuildContext context, {
    double mobile = 12,
    double? tablet,
    double? desktop,
  }) {
    final value = spacing(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
    return BorderRadius.circular(value);
  }

  static int crossAxisCount(BuildContext context) => gridColumns(context);

  static double childAspectRatio(BuildContext context) =>
      cardAspectRatio(context);

  static bool shouldShowSideNav(BuildContext context) => !isMobile(context);

  static double sideNavWidth(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.desktop:
        return 260;
      case DeviceType.tablet:
        // The seller workspace uses a labeled menu rather than an icon rail.
        return 232;
      case DeviceType.mobile:
        return 0;
    }
  }

  static double maxValue(
    BuildContext context, {
    double mobile = 400,
    double? tablet,
    double? desktop,
  }) {
    return spacing(context, mobile: mobile, tablet: tablet, desktop: desktop);
  }
}
