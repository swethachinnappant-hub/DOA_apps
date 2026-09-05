import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, desktop }

class Responsive {
  static const double mobileMax = 600;
  static const double tabletMax = 1200;

  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobileMax) return DeviceType.mobile;
    if (width < tabletMax) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  static bool isMobile(BuildContext context) => getDeviceType(context) == DeviceType.mobile;
  static bool isTablet(BuildContext context) => getDeviceType(context) == DeviceType.tablet;
  static bool isDesktop(BuildContext context) => getDeviceType(context) == DeviceType.desktop;

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;
  static double height(BuildContext context) => MediaQuery.sizeOf(context).height;

  static double fontSize(BuildContext context, {required double mobile, double? tablet, double? desktop}) {
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

  static double spacing(BuildContext context, {required double mobile, double? tablet, double? desktop}) {
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

  static int gridColumns(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.desktop:
        return 4;
      case DeviceType.tablet:
        return 3;
      case DeviceType.mobile:
        return 2;
    }
  }

  static double cardAspectRatio(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.desktop:
        return 1.4;
      case DeviceType.tablet:
        return 1.2;
      case DeviceType.mobile:
        return 1.0;
    }
  }

  static double iconSize(BuildContext context, {double mobile = 20, double? tablet, double? desktop}) {
    return fontSize(context, mobile: mobile, tablet: tablet, desktop: desktop);
  }

  static EdgeInsets padding(BuildContext context, {double mobile = 16, double? tablet, double? desktop}) {
    final value = spacing(context, mobile: mobile, tablet: tablet, desktop: desktop);
    return EdgeInsets.all(value);
  }

  static EdgeInsets horizontalPadding(BuildContext context, {double mobile = 16, double? tablet, double? desktop}) {
    final value = spacing(context, mobile: mobile, tablet: tablet, desktop: desktop);
    return EdgeInsets.symmetric(horizontal: value);
  }

  static BorderRadius borderRadius(BuildContext context, {double mobile = 12, double? tablet, double? desktop}) {
    final value = spacing(context, mobile: mobile, tablet: tablet, desktop: desktop);
    return BorderRadius.circular(value);
  }

  static int crossAxisCount(BuildContext context) => gridColumns(context);

  static double childAspectRatio(BuildContext context) => cardAspectRatio(context);

  static bool shouldShowSideNav(BuildContext context) => !isMobile(context);

  static double sideNavWidth(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.desktop:
        return 260;
      case DeviceType.tablet:
        return 72;
      case DeviceType.mobile:
        return 0;
    }
  }

  static double maxValue(BuildContext context, {double mobile = 400, double? tablet, double? desktop}) {
    return spacing(context, mobile: mobile, tablet: tablet, desktop: desktop);
  }
}
