import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // or import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AppUser {
  static late User thisUser;
  static MapType mapPreference = MapType.normal;
  static String? role;
  static List<String>? perms;

  static VoidCallback? onRoleChange;

  static void setRole(String? newRole) {
    role = newRole;
    if (onRoleChange != null) {
      onRoleChange!();
    }
  }
}
