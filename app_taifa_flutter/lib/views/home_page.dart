import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // The user will be automatically redirected to the SignInScreen
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Welcome to the Main Page!'),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
//
// void main() {
//   runApp(MainMenuApp());
// }
//
// class MainMenuApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       theme: ThemeData(
//         primaryColor: Colors.red, // Set your primary color here
//         secondaryHeaderColor: Colors.red, // Set your secondary color here
//         // You can customize more aspects of the theme here, such as text styles, fonts, etc.
//       ),
//       home: MainMenuView(),
//     );
//   }
// }
//
// class MainMenuView extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Main Menu'),
//       ),
//       body: Column(
//         children: <Widget>[
//           Align(
//             alignment: Alignment.topLeft,
//             child: ExpandedButton('Site Locations'),
//           ),
//           Align(
//             alignment: Alignment.topLeft,
//             child: ExpandedButton('Site Locations - Admin'),
//           ),
//           Align(
//             alignment: Alignment.topLeft,
//             child: ExpandedButton('Equipment Tracking'),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class ExpandedButton extends StatelessWidget {
//   final String label;
//
//   ExpandedButton(this.label);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.all(16.0),
//       child: ElevatedButton(
//         onPressed: () {
//           // Add code to navigate to a different screen or perform an action.
//         },
//         child: Text(label),
//       ),
//     );
//   }
// }
