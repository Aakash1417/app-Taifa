import 'package:app_taifa_flutter/views/home_page.dart';
import 'package:app_taifa_flutter/views/signin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taifa Engineering',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            User? user = snapshot.data;
            if (user != null) {
              SignInScreenState.currentUser = user;
              updateSignedInUser(user.email.toString() ?? '');
            }
            return HomePage(onLogout: () => _navigateToSignIn(context));
          } else {
            return SignInScreen(); // User is not logged in
          }
        },
      ),
    );
  }

  void _navigateToSignIn(BuildContext context) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => SignInScreen(),
    ));
  }
}
