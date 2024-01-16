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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isAuthenticated = false;

  @override
  void initState() {
    super.initState();

    // Call updateSignedInUser here to ensure it's only called once
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        SignInScreenState.currentUser = user;
        updateSignedInUser(user.email.toString() ?? '');
        isAuthenticated = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taifa Engineering',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: isAuthenticated
          ? HomePage(onLogout: () => _navigateToSignIn(context))
          : SignInScreen(),
    );
  }

  void _navigateToSignIn(BuildContext context) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => SignInScreen(),
    ));
  }
}
