import 'package:flutter/material.dart';

class Responsive  {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late Orientation orientation;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    orientation = _mediaQueryData.orientation;
  }

  // Returns height as a % of screen height
  static double h(double percentage) {
    return screenHeight * (percentage / 100);
  }

  // Returns width as a % of screen width
  static double w(double percentage) {
    return screenWidth * (percentage / 100);
  }

  // Returns scalable font size based on screen width
  static double sp(double percentage) {
    return screenWidth * (percentage / 100);
  }
}
