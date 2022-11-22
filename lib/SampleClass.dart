import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:conversation/FireBaseHelpClasses/FireBaseFireStoreHelperClass.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'DataBaseHelpers/UserChatsDb.dart';
import 'LocalNotifications.dart';

class Sample extends StatefulWidget{
  const Sample({Key? key}) : super(key: key);

  @override
  State<Sample> createState() => _SampleState();
}

class _SampleState extends State<Sample> {

  NotificationServices notificationServices = NotificationServices();
  @override
  void initState() {
   super.initState();
   getAccessToken();
  }
  getAccessToken()async{
    FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
    String? accessToken = '';
    await firebaseMessaging.getToken().then((value) => accessToken = value);
    print("accessTokenForTheDevice:$accessToken");
  }
  @override
  Widget build(BuildContext context) {
   return Scaffold(
     body: Center(child: IconButton(onPressed: (){
       notificationServices.sendNotification('Hello', "sample");
     },icon: Icon(Icons.ads_click),))
   );
  }
}