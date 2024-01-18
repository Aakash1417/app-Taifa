import 'dart:async';

import 'package:app_taifa_flutter/views/signin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'objects/Client.dart';
import 'objects/Pins.dart';

Future<List<Client>?> loadClients() async {
  List<Client> tempList = [];
  try {
    await FirebaseFirestore.instance
        .collection("clients")
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((DocumentSnapshot doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String name = doc.id;
        int colorValue = data['color'];
        final String date = data['lastUpdated'] ?? '';

        tempList.add(Client(
            name: name,
            color: Color(colorValue),
            lastUpdated: DateTime.parse(date)));
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

        final String name = doc.id;
        final double latitude = data['latitude'] ?? 0.0;
        final double longitude = data['longitude'] ?? 0.0;
        final String client = data['client'] ?? '';
        final String date = data['lastUpdated'] ?? '';
        final String createdBy = data['createdBy'] ?? '';

        allPins.add(Pins(
          name: name,
          client: client,
          latitude: latitude,
          longitude: longitude,
          lastUpdated: DateTime.parse(date),
          createdBy: createdBy,
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
        'lastSignIn': DateTime.now().toIso8601String(),
      });
      Map<String, dynamic> doc = userSnapshot.data() as Map<String, dynamic>;
      role = doc['role'] ?? '';
      if (role != '') {
        SignInScreenState.role = role;
        // getting current user permissions
        var documentSnapshot = await FirebaseFirestore.instance
            .collection('roles')
            .doc(role)
            .get();
        if (documentSnapshot.exists) {
          List<dynamic>? dynamicArray = documentSnapshot.data()?['perms'];
          if (dynamicArray != null && dynamicArray.isNotEmpty) {
            List<String>? stringArray =
                dynamicArray.cast<String>(); // Explicit cast
            SignInScreenState.perms = stringArray;
          }
        }
      }
    } else {
      // User doesn't exist, create new user with initial role of employee
      await usersCollection.doc(email).set({
        'email': email,
        'role': 'employee',
        'lastSignIn': DateTime.now().toIso8601String(),
      });
    }
  } catch (error) {
    print('Error checking user: $error');
  }
}

Future<void> addClientToFirestore(String clientName, int clientColor) async {
  FirebaseFirestore.instance.collection("clients").doc(clientName).set({
    'color': clientColor,
    'lastUpdated': DateTime.now().toIso8601String(),
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
  FirebaseFirestore.instance.collection("allPins").doc(pinName).set({
    'latitude': latitude,
    'longitude': longitude,
    'client': selectedClient,
    'lastUpdated': DateTime.now().toIso8601String(),
    'createdBy': SignInScreenState.currentUser?.email
  });
}
