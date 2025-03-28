import 'dart:async';
import 'package:flutter/material.dart';
import 'package:untitled1/global/global.dart';
import 'package:untitled1/screens/sign_in_screen.dart';
import 'package:untitled1/tab_pages/home_tab.dart';

import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  startTimer() {
    Timer(const Duration(seconds: 3), () async {
      if (firebaseAuth.currentUser != null) {
        Navigator.push(
            context, MaterialPageRoute(builder: (c) => const MainScreen()));
      } else {
        // Navigate to login/welcome screen if not logged in
        // For now, we'll just stay on splash screen
        Navigator.push(
            context, MaterialPageRoute(builder: (c) => const SignInScreen()));
      }
    });
  }

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "images/logo.png", 
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 10),
            const Text(
              "Trippo Driver App",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}