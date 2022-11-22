import 'package:conversation/UserAuthentication/Authenticate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'LocalNotifications.dart';
import 'ViewModel/ChatMessageViewModel.dart';
import 'ViewModel/ChatRoomsViewModel.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  NotificationServices notificationServices = NotificationServices();
  notificationServices.initialiseNotifications();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    badge: true,
  );

  runApp( const MyApp());
}

class MyApp extends StatefulWidget {
   const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  NotificationServices notificationServices = NotificationServices();

  @override
  Widget build(BuildContext context) {
    notificationServices.initialiseNotifications();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (message.data['notificationType'] == "message") {
        SharedPreferences preferences = await SharedPreferences.getInstance();
        var activeChatroom = preferences.getString('activeRoomId');
        if(activeChatroom != message.data['chatRoomId']){
          notificationServices.sendNotification(message.notification?.title, message.notification?.body);
        }
        var updateChatRooms = [];
        updateChatRooms.add((message.data['chatRoomId']));

        Provider.of<ChatMessageViewModel>(context)
            .getChatMessages(message.data['chatRoomId']);

        Provider.of<ChatRoomsViewModel>(context)
            .getChatRoomsFromServer(context,updateChatRooms);

      }
    });
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (BuildContext context) => ChatRoomsViewModel()),
        ChangeNotifierProvider(
            create: (BuildContext context) => ChatMessageViewModel())
      ],
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SafeArea(
            child: Authenticate(),
          )),
    );
  }
}
//Authenticate
