import 'dart:async';

import 'package:app_taifa_flutter/views/signin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'objects/Client.dart';
import 'objects/Pins.dart';
import 'objects/roles.dart';

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
        int colorValue = data['color'];
        final String date = data['lastUpdatedDate'] ?? '';

        tempList.add(Client(
            name: name,
            color: Color(colorValue),
            updatedDate: DateTime.parse(date)));
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
        final String date = data['lastUpdatedDate'] ?? '';

        allPins.add(Pins(
          name: name,
          client: client,
          latitude: latitude,
          longitude: longitude,
          updatedDate: DateTime.parse(date),
        ));
      });
    });

    return allPins;
  } catch (e) {
    print("Error loading pins: $e");
    return null;
  }
}

Future<void> updateSignedInUser(String email) async {
  // checks if the user has already logged in to app, if the user already exists then update their last signed in date. if they don't already exist then create their info with this email and set intial role to be employee. create a enum for roles, for employee and admin
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  String role = '';
  try {
    DocumentSnapshot userSnapshot = await usersCollection.doc(email).get();
    if (userSnapshot.exists) {
      // User already exists, update last signed in date
      await usersCollection.doc(email).update({
        'lastSignIn': FieldValue.serverTimestamp(),
      });
      Map<String, dynamic> doc = userSnapshot.data() as Map<String, dynamic>;
      role = doc['role'] ?? '';
      if (role != '') {
        SignInScreenState.role =
            UserRole.values.firstWhere((e) => e.name == role);
      }
    } else {
      // User doesn't exist, create new user with initial role of employee
      await usersCollection.doc(email).set({
        'email': email,
        'role': UserRole.employee.name,
        'lastSignIn': FieldValue.serverTimestamp(),
      });
    }
  } catch (error) {
    print('Error checking user: $error');
  }
}

Future<void> addClientToFirestore(String clientName, int clientColor) async {
  FirebaseFirestore.instance.collection("clients").add({
    'name': clientName,
    'color': clientColor,
    'createdTime': DateTime.now().toIso8601String(),
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
    'lastUpdatedDate': DateTime.now().toIso8601String(),
  });
}
