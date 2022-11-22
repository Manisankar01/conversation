import 'package:conversation/LocalNotifications.dart';
import 'package:flutter/material.dart';

import 'FireBaseHelpClasses/FireBaseFireStoreHelperClass.dart';

class DummyClass extends StatefulWidget {
  const DummyClass({Key? key}) : super(key: key);

  @override
  State<DummyClass> createState() => _DummyClassState();
}

class _DummyClassState extends State<DummyClass> {
  NotificationServices notificationServices = NotificationServices();
  var accessToken =
      "fgUqBgOYRNKiXg--haypsG:APA91bEOHrePLulsky3cjpbFonZsjj14sGoNmm4OnMGcphGcwEJZ6ko8AzNwB4GQv-FtbrexVJks-Js-GyZCgW6D60ygmK3y6FZVNm1sj3hNT_obUoLFFj040uOs57MPbT3qyUwI8NEt";

  @override
  void initState() {
    super.initState();
    notificationServices.initialiseNotifications();
  }

  void getAccessToken() async {
    // FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
    // var accessToken =await  firebaseMessaging.getToken();
    // print("Device accessToken ::${accessToken}::");
    await FireBaseFireStoreHelperClass.sendNotificationMessageToPeerUser(
      1,
      'text',
      'newNotification',
      'mani',
     accessToken ,"message");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: GestureDetector(
        onTap: () {
          getAccessToken();
        },
        child: const Text("ClickHere"),
      )),
    );
  }
}
