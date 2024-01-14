import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../objects/Client.dart';
import '../objects/Pins.dart';

Future<List<Client>?> loadClients() async {
  List<Client> tempList = [];
  try {
    await FirebaseFirestore.instance
        .collection("clients")
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((DocumentSnapshot doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String name = data['name'];
        int colorValue = data['color']; // Assuming color is stored as int
        tempList.add(Client(name: name, color: Color(colorValue)));
      });
    });
    return tempList;
  } catch (e) {
    print("Error loading clients: $e");
    return null;
  }
}

Future<List<Pins>?> loadPinsFromFirestore() async {
  List<Pins> allPins = [];
  try {
    await FirebaseFirestore.instance
        .collection("allPins")
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((DocumentSnapshot doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        final String name = data['name'] ?? '';
        final double latitude = data['latitude'] ?? 0.0;
        final double longitude = data['longitude'] ?? 0.0;
        final String client = data['client'] ?? '';
        allPins.add(Pins(
          name: name,
          client: client,
          latitude: latitude,
          longitude: longitude,
        ));
      });
    });

    return allPins;
  } catch (e) {
    print("Error loading pins: $e");
    return null;
  }
}

Future<String?> getRoleFromFirestore(String email) async {
  String role = '';
  try {
    await FirebaseFirestore.instance
        .collection("users")
        .where('email', isEqualTo: email)
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((DocumentSnapshot doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        role = data['role'] ?? '';
      });
    });
    if (role != '') {
      return role;
    }
    return null;
  } catch (e) {
    print("Error loading pins: $e");
    return null;
  }
}

Future<String?> checkUserInFirestore(String email) async {
  // checks if the user has already logged in to app
  // SignInScreenState.currentUser?.email
}

Future<String?> addUserToFirestore(String email) async {
  // adds user to firestore with role of Employee
  // create enum for roles

}


Future<void> addClientToFirestore(String clientName, int clientColor) async {
  FirebaseFirestore.instance.collection("clients").add({
    'name': clientName,
    'color': clientColor,
  }).then((_) {
    // Handle successful addition
  }).catchError((error) {
    // Handle errors
  });
}

void addPinToFirestore(
  String pinName,
  String? selectedClient,
  double latitude,
  double longitude,
) {
  FirebaseFirestore.instance.collection("allPins").add({
    'name': pinName,
    'latitude': latitude,
    'longitude': longitude,
    'client': selectedClient,
  });
}
