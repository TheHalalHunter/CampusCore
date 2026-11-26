import 'package:flutter/material.dart';

/// Responsive helper class for adaptive UI across different screen sizes
class Responsive {
  static const double mobileWidth = 600;
  static const double tabletWidth = 1100;

  /// Check if screen is mobile size
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileWidth;
  }

  /// Check if screen is tablet size
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileWidth && width < tabletWidth;
  }

  /// Check if screen is desktop size
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletWidth;
  }

  /// Get responsive padding as double
  static double getPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileWidth) return 12;
    if (width < tabletWidth) return 16;
    return 24;
  }

  /// Get responsive padding as EdgeInsets (for Scaffold/Container)
  static EdgeInsets getPaddingEdgeInsets(BuildContext context) {
    final pad = getPadding(context);
    return EdgeInsets.all(pad);
  }

  /// Get responsive spacing based on screen size
  static double getSpacing(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileWidth) return 8;
    if (width < tabletWidth) return 12;
    return 16;
  }

  /// Get responsive font size
  static double getFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileWidth) return baseSize * 0.85;
    if (width < tabletWidth) return baseSize * 0.95;
    return baseSize;
  }

  /// Get grid columns based on screen size
  static double getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileWidth) return 1;
    if (width < tabletWidth) return 2;
    return 3;
  }

  /// Get responsive height
  static double getResponsiveHeight(BuildContext context, double baseHeight) {
    final height = MediaQuery.of(context).size.height;
    return baseHeight * (height / 800);
  }

  /// Get responsive width
  static double getResponsiveWidth(BuildContext context, double baseWidth) {
    final width = MediaQuery.of(context).size.width;
    return baseWidth * (width / 1200);
  }
}
