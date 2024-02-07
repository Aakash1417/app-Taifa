import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

List<Color> getAllColors() {
  return [
    convertHueToColor(BitmapDescriptor.hueAzure),
    convertHueToColor(BitmapDescriptor.hueBlue),
    convertHueToColor(BitmapDescriptor.hueCyan),
    convertHueToColor(BitmapDescriptor.hueGreen),
    convertHueToColor(BitmapDescriptor.hueMagenta),
    convertHueToColor(BitmapDescriptor.hueOrange),
    convertHueToColor(BitmapDescriptor.hueRed),
    convertHueToColor(BitmapDescriptor.hueRose),
    convertHueToColor(BitmapDescriptor.hueViolet),
    convertHueToColor(BitmapDescriptor.hueYellow),
  ];
}

Color convertHueToColor(double hue) {
  final hsvColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0);
  return hsvColor.toColor();
}
