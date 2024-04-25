import 'package:app_taifa_flutter/views/admin_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

import '../objects/Constants.dart';
import '../objects/appUser.dart';
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
    AppUser.onRoleChange = _onRoleChange;
  }

  void _onRoleChange() {
    setState(() {});
  }

  List<Widget> _buildIcons(function) {
    return [
      function('assets/images/maps.png', () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => MapsPage()));
      }, 'Maps'),
      function('assets/images/equipment_logo.png', () {
        // Navigator push for CalibratorPage
      }, 'Calibrator'),
      function('assets/images/QR.png', () {}, 'QR Code'),
      function('assets/images/feedbackIcon.png', () async {
        final Uri feedbackFormUrl = Uri.parse('https://flutter.dev');
        if (!await launchUrl(feedbackFormUrl)) {
          throw Exception('Could not launch $feedbackFormUrl');
        }
      }, 'Report Bug'),
      if (AppUser.role == Roles.admin.name)
        function('assets/images/admin_icon.png', () async {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => AdminPage()));
        }, 'Admin'),
    ];
  }

  Widget _mobileIconButton(
      String assetPath, VoidCallback onPressed, String label) {
    return Column(
      children: [
        Expanded(
          child: IconButton(
            icon: Image.asset(
              assetPath,
              height: 90,
              fit: BoxFit.contain,
            ),
            onPressed: onPressed,
          ),
        ),
        Text(label),
      ],
    );
  }

  Widget _webIconButton(
      String assetPath, VoidCallback onPressed, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Image.asset(
            assetPath,
            width: 90,
            height: 90,
            fit: BoxFit.contain,
          ),
          onPressed: onPressed,
        ),
        Text(label),
      ],
    );
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
        body: kIsWeb
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _buildIcons(_webIconButton))
            : GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 70.0,
                mainAxisSpacing: 30.0,
                padding: const EdgeInsets.only(left: 50, right: 50),
                children: _buildIcons(_mobileIconButton)));
  }
}
