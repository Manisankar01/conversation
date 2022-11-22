import 'package:conversation/HomeScreen.dart';
import 'package:conversation/SampleHomeScreen.dart';
import 'package:conversation/UserAuthentication/SignInScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../MainScreen.dart';

class Authenticate extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

   Authenticate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (_auth.currentUser != null) {
      return const SampleHomeScreen();
    } else {
      return const SignInScreen();
    }
  }
}
