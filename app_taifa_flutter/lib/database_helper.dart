import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../objects/Client.dart';
import '../objects/Pins.dart';

final CollectionReference pinsRef =
    FirebaseFirestore.instance.collection("allPins");
final CollectionReference clientRef =
    FirebaseFirestore.instance.collection("clients");

Future<List<Client>?> loadClients() async {
  List<Client> tempList = [];

  try {
    await clientRef.get().then((QuerySnapshot querySnapshot) {
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
    await pinsRef.get().then((QuerySnapshot querySnapshot) {
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

// Future<List<Pins>?> loadPinsFromFirestore() {
//
//
//
//
//   return FirebaseFirestore.instance.collection('allPins').get().then(
//     (QuerySnapshot querySnapshot) {
//       List<Pins> allPins = [];
//       for (var doc in querySnapshot.docs) {
//         Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//         final String name = data['name'] ?? '';
//         final double latitude = data['latitude'] ?? 0.0;
//         final double longitude = data['longitude'] ?? 0.0;
//         final String client = data['client'] ?? '';
//
//         allPins.add(Pins(
//           name: name,
//           client: client,
//           latitude: latitude,
//           longitude: longitude,
//         ));
//       }
//       return allPins;
//     },
//     onError: (e) {
//       print("Error loading pins: $e");
//       return null;
//     },
//   );
// }

// Future<List<Client>?> loadClients() {
//   return FirebaseFirestore.instance.collection('clients').get().then(
//     (QuerySnapshot querySnapshot) {
//       List<Client> tempList = [];
//       for (var doc in querySnapshot.docs) {
//         Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//         String name = data['name'];
//         int colorValue = data['color'];
//         print(name);
//         print(colorValue);
//         print("______________");
//         tempList.add(Client(name: name, color: Color(colorValue)));
//       }
//       return tempList;
//     },
//     onError: (e) {
//       print("Error loading clients: $e");
//       return null;
//     },
//   );
// }

Future<void> addClientToFirestore(String clientName, int clientColor) async{
  clientRef.add({
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
  pinsRef.add({
    'name': pinName,
    'latitude': latitude,
    'longitude': longitude,
    'client': selectedClient,
  });
}

double colorToHue(Color color) {
  HSLColor hsl = HSLColor.fromColor(color);
  return hsl.hue;
}
