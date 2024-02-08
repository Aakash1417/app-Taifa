import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../api/sheets/equipmentSheets.dart';
import 'map_view.dart';

class HomePage extends StatefulWidget {
  late final VoidCallback onLogout;

  HomePage({super.key, required this.onLogout});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final GoogleSignIn _googleSignIn;

  @override
  void initState() {
    super.initState();
    _googleSignIn = GoogleSignIn();
    EquipmentSheetsApi.init().then((value) {
      print("asd");
    }).catchError((onError) {
      print(onError);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Main Page',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromRGBO(132, 17, 17, 1),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.white,
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              await _googleSignIn.signOut();
              widget.onLogout();
            },
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 70.0,
        mainAxisSpacing: 30.0,
        padding: const EdgeInsets.only(left: 50, right: 50),
        children: [
          Column(
            children: [
              Expanded(
                child: IconButton(
                  icon: Image.asset('assets/images/maps.png', height: 90),
                  onPressed: () async {
                    // Navigate to MapsPage when the button is pressed
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MapsPage()),
                    );
                  },
                ),
              ),
              const Text(
                'Maps',
              ),
            ],
          ),
          Column(
            children: [
              Expanded(
                child: IconButton(
                  icon: Image.asset('assets/images/QR.png', height: 90),
                  onPressed: () {
                    // go to QR view
                  },
                ),
              ),
              const Text('QR Code'),
            ],
          ),
          Column(
            children: [
              Expanded(
                child: IconButton(
                  icon: Image.asset('assets/images/equipment_logo.png', height: 90),
                  onPressed: () {
                    // go to sheets
                  },
                ),
              ),
              const Text(
                'Calibrator',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
