import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class Fcm extends StatefulWidget{
  @override
  State<StatefulWidget> createState()=> _Fcm();
}
class _Fcm extends State<Fcm>{
   FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
   return Scaffold();
  }

}