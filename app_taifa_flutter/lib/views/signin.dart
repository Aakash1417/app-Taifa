import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../database_helper.dart';
import '../objects/appUser.dart';
import 'home_page.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn googleSignIn;

  @override
  void initState() {
    super.initState();
    if (!Platform.isIOS) {
      googleSignIn = GoogleSignIn(
          clientId:
              "95581424221-knrsei9i3lkm0ahpvd3rkqijsp1s67ad.apps.googleusercontent.com");
    } else {
      googleSignIn = GoogleSignIn();
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();
      if (googleSignInAccount != null) {
        if (googleSignInAccount.email.endsWith('@taifaengineering.com')) {
          final GoogleSignInAuthentication googleSignInAuthentication =
              await googleSignInAccount.authentication;
          final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleSignInAuthentication.accessToken,
            idToken: googleSignInAuthentication.idToken,
          );

          final UserCredential authResult =
              await _auth.signInWithCredential(credential);
          final User? user = authResult.user;

          if (user != null && user.email!.endsWith('@taifaengineering.com')) {
            if (!mounted) return; // Check if the widget is still in the tree
            AppUser.thisUser = user;
            updateSignedInUser(user.email.toString());
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      HomePage(onLogout: () => _navigateToSignIn(context))),
            );
          } else {
            await _auth.signOut(); // Sign out from Firebase
            await googleSignIn.signOut(); // Sign out from Google

            if (!mounted) return;
            _showInvalidDomainDialog(); // Show error dialog
          }
        } else {
          await googleSignIn.signOut(); // Sign out from Google
          _showInvalidDomainDialog(); // Show error dialog
        }
      }
    } catch (e) {
      print(e);
      // Handle other errors here
    }
  }

  void _navigateToSignIn(BuildContext context) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => SignInScreen(),
    ));
  }

  void _showInvalidDomainDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invalid Domain'),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(); // Dismiss the dialog
            },
          ),
        ],
      ),
    );
  }

  void _handleInvalidDomain() {
    // Logic for handling invalid domain
    print("ok");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/images/logoTaifa.png',
              height: 100,
            ),
            // const SizedBox(height: 20),
            // TextFormField(
            //   decoration: const InputDecoration(
            //     labelText: 'Username',
            //   ),
            // ),
            // const SizedBox(height: 20),
            // TextFormField(
            //   obscureText: true,
            //   decoration: const InputDecoration(
            //     labelText: 'Password',
            //   ),
            // ),
            // const SizedBox(height: 20),
            // ElevatedButton(
            //   onPressed: () {
            //     // Add your sign-in logic here
            //   },
            //   child: const Text('Sign In'),
            // ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: signInWithGoogle,
              child: const Text('Single Sign-On'),
            ),
          ],
        ),
      ),
    );
  }
}
