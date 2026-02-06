import 'package:bank_app/firebase_options.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'auth_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 1. APP ENTRY POINT
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Banking App UI',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      debugShowCheckedModeBanner: false,

      home: const AuthWrapper(),
    );
  }
}

// Wrapper to headle authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        //if user is loagged in, show home scrren
        if (snapshot.hasData && snapshot.data != null) {
          return const MyHomePage();
        }

        // if user is not logged in, show auth screen
        return const AuthScreen();
      },
    );
  }
}
