import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:conversation/UserDetailsStream.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';

import '../UserAuthentication/SignInScreen.dart';

Future<User?> createAccount(
    String firstName, String lastName, String email, String password) async {
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore fireBase = FirebaseFirestore.instance;

  try {
    User? user = (await auth.createUserWithEmailAndPassword(
            email: email, password: password))
        .user;
    if (user != null) {
      if (kDebugMode) {
        print("Account created successfully");
      }
      user.updateDisplayName(firstName);

      await fireBase.collection('users').doc(auth.currentUser?.uid).set({
        "fireBaseAccessToken":"",
        "name":firstName,
        "email":email,
        "status":"Unavailable",
        "roomDetails":[],
        "profile":"",
        "isGroup":false,
        "uniqueId":auth.currentUser?.uid
      }).catchError((onError){
        print("error adding document$onError");
      });
      print('user data  created in firebaseCloud');
      return user;
    } else {
      if (kDebugMode) {
        print("Account creation failed");
      }
      return user!;
    }
  } catch (e) {
    if (kDebugMode) {
      print("error Message:$e");
    }
    return null;
  }
}

Future<User?> login(String email, String password) async {
  FirebaseAuth auth = FirebaseAuth.instance;
  try {
    User? user = (await auth.signInWithEmailAndPassword(
            email: email, password: password))
        .user;
    if (user != null) {
      if (kDebugMode) {
        print("Login successful");
      }
      return user;
    } else {
      if (kDebugMode) {
        print("Login un-successful");
      }
      return user;
    }
  } catch (e) {
    if (kDebugMode) {
      print(e);
    }
    return null;
  }
}

Future logOut(BuildContext context) async {
  FirebaseAuth auth = FirebaseAuth.instance;
  try {
    await auth.signOut().then((value) => Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),));
    UserDetailsStream.removeUserData();
    if(kDebugMode){
      print('Logout Successfully');
    }
  } catch (e) {
    if(kDebugMode){
      print(e);
    }
  }
}
