import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AppUser {
  static late User thisUser;
  static MapType mapPreference = MapType.normal;
  static String? role;
  static List<String>? perms;
}
