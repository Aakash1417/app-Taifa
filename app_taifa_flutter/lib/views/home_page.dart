import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'map_view.dart';

class HomePage extends StatelessWidget {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final VoidCallback onLogout;

  // Modify the constructor to require the onLogout parameter
  HomePage({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Page'),
        backgroundColor: const Color.fromRGBO(132, 17, 17, 1),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              await _googleSignIn.signOut();
              onLogout();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Row 1
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    IconButton(
                      icon: Image.asset('assets/images/maps.png', height: 80),
                      onPressed: () async {
                        // Navigate to MapsPage when the button is pressed
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MapsPage()),
                        );
                      },
                    ),
                    const Text('Maps'),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    IconButton(
                      icon: Image.asset('assets/images/QR.png', height: 80),
                      onPressed: () async {
                        // go to QR view
                      },
                    ),
                    const Text('QR Code'),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    IconButton(
                      icon: Image.asset('assets/images/QR.png', height: 80),
                      onPressed: () async {
                        await DefaultCacheManager().emptyCache(); // not working
                        exit(0);
                      },
                    ),
                    const Text('Clear cache and restart'),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(), // Add spacing between rows
          // Row 2 (you can add more rows as needed)
          Row(
            children: [
              Expanded(
                child: IconButton(
                  icon: const Icon(Icons.home, size: 40),
                  onPressed: () async {
                    // add logic for the third button
                  },
                ),
              ),
              Expanded(
                child: IconButton(
                  icon: const Icon(Icons.account_box, size: 40),
                  onPressed: () async {
                    // add logic for the fourth button
                  },
                ),
              ),
              Expanded(
                child: IconButton(
                  icon: const Icon(Icons.settings, size: 40),
                  onPressed: () async {
                    // add logic for the fourth button
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
