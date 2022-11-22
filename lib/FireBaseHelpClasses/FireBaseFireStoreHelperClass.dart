import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:conversation/Constsnts/ConstantValues.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class FireBaseFireStoreHelperClass {
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;
  static FirebaseAuth auth = FirebaseAuth.instance;

  static Future<QuerySnapshot<Map<String, dynamic>>>
  fetchCurrentUserDetails() async {
    return await fireStore
        .collection('users')
        .where("uniqueId", isEqualTo: auth.currentUser?.uid)
        .get();
  }

  static Future<List> fetchCurrentUserChatRooms() async {
    var allChatRooms = [];
    QuerySnapshot<Map<String, dynamic>> chatRooms =
    await fireStore.collection('chatroom').get();
    chatRooms.docs.forEach((element) {
      allChatRooms.add(element.data());
    });
    return allChatRooms;
  }

  static Future<QuerySnapshot<Map<String, dynamic>>> fetchUserMessagesFromAllChatRooms(String chatRoomID) async{

      var chatList  = await fireStore
          .collection('chatroom').doc(chatRoomID).collection('chats').get();
      return chatList;
  }

  static updateLastMessageTime(roomId,messageId,message,type) async {
    await fireStore
        .collection("chatroom")
        .doc(roomId)
        .update({"lastMessage": DateTime.now(), "lastMessageId":messageId,
      "lastMessageContent":message,
      "lastMessageType":type});
  }

  static Future<Map<String, dynamic>> getLastMessageInfo(chatRoomId)  async{

   var data ;
   await FirebaseFirestore.instance
        .collection('chatroom')
        .doc(chatRoomId)
        .collection('chats')
        .orderBy('time', descending: true)
        .limit(1)
        .get().then((value) => data = value.docs.first.data());
   return await data;
  }
  static deleteMessage(String roomId, String messageId) async {
    await fireStore
        .collection('chatroom')
        .doc(roomId)
        .collection('chats')
        .doc(messageId)
        .delete();
  }

  static editMessage(String roomId, String messageId, String message) async {
    await fireStore
        .collection('chatroom')
        .doc(roomId)
        .collection('chats')
        .doc(messageId)
        .update({"message": message, "isEdited": true});
  }

  static Future<int> checkMessages(String chatRoomId) async {
    var response = fireStore
        .collection('chatroom')
        .doc(chatRoomId)
        .get()
        .then((value) => value.id.hashCode);
    return response;
  }

  static uploadUserProfile(croppedImageFile, chatRoomId) async {

    String fileName = const Uuid().v1();
    int status = 1;

    var ref =
    FirebaseStorage.instance.ref().child('userProfiles').child("$fileName.jpg");

    var uploadTask = await ref.putFile(croppedImageFile!).catchError((error) async {
      await fireStore
          .collection('user')
          .doc(auth.currentUser?.uid)
          .update({"profile":""
      });
      status = 0;
    });

    if (status == 1) {
      String imageUrl = await uploadTask.ref.getDownloadURL();
      await fireStore
          .collection('user')
          .doc(auth.currentUser?.uid)
          .update({"profile":imageUrl
      });

      print(imageUrl);
    }
  }

  static updateAccessToken() async {
    FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
    String? accessToken = '';
    await firebaseMessaging.getToken().then((value) => accessToken = value);
    await fireStore
        .collection('users')
        .doc(auth.currentUser?.uid)
        .update({"fireBaseAccessToken": accessToken});
  }

  static deleteAccessToken() async {
    await fireStore
        .collection('users')
        .doc(auth.currentUser?.uid)
        .update({"fireBaseAccessToken": ''});
  }

  static updateChatRoomMessagesCount(userId, userChatRoomId) async {
    await fireStore
        .collection('users')
        .doc(userId)
        .collection('chatRooms')
        .doc(userChatRoomId)
        .update({'unReadMessagesCount': FieldValue.increment(1)});
  }

  static messagesCount(userId, chatRoomId) async {
    await fireStore
        .collection('users')
        .doc(userId)
        .collection('chatRooms')
        .doc(chatRoomId)
        .set({'unReadMessagesCount': 0});
  }

  static Future<int> getUnReadMessageCount(userId, chatRoomId) async {
    int unReadMessagesCount = 0;
    await fireStore
        .collection('users')
        .doc(userId)
        .collection('chatRooms')
        .doc(chatRoomId)
        .get()
        .then((value) => unReadMessagesCount = value['unReadMessagesCount']);
    return unReadMessagesCount;
  }

  static stopNotification(chatRoomId, messageId) async {
    await fireStore
        .collection('chatroom')
        .doc(chatRoomId)
        .collection('chats')
        .doc(messageId)
        .update({"isRead": true});
  }

  static addToActiveMembers(chatRoomId, userId) async {
    List activeMembersList = [];
    getActiveMembers(chatRoomId)
        .then((value) => activeMembersList = value.first['activeMembers']);
    activeMembersList.add(userId);
    await fireStore
        .collection('chatroom')
        .doc(chatRoomId)
        .update({"activeMembers": activeMembersList});
  }

  static removeFromActiveMembers(chatRoomId, userId) async {
    List activeMembersList = [];
    getActiveMembers(chatRoomId)
        .then((value) => activeMembersList = value.
    first['activeMembers']);
    activeMembersList.remove(userId);
    await fireStore
        .collection('chatroom')
        .doc(chatRoomId)
        .update({"activeMembers": activeMembersList});
  }

  static Future<List<dynamic>> getActiveMembers(chatRoomId) async {
    return await fireStore
        .collection('chatroom')
        .doc(chatRoomId)
        .get()
        .then((value) => value['activeMembers']);
  }

  static sendMessageToActiveMembers(chatRoomId, activeMembersList) async {
    await fireStore
        .collection('chatroom')
        .doc(chatRoomId)
        .update({"activeMembers": activeMembersList});
  }

  static sendNotificationMessageToPeerUser(unReadMSGCount, messageType,
      textFromTextField, myName, peerUserToken,String notificationType,[chatRoomId]) async {
    // FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
    try {
      await http.post(
        // 'https://fcm.googleapis.com/fcm/send',
        // 'https://api.rnfirebase.io/messaging/send',
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'key=$fireBaseCloudServerToken',
        },
        body: jsonEncode(
          <String, dynamic>{
            'notification': <String, dynamic>{
              'body': messageType == 'text' ? '$textFromTextField' : '(Photo)',
              'title': '$myName',
              'badge': '$unReadMSGCount', //'$unReadMSGCount'
              "sound": "default",
              // "image": myImageUrl
            },
            // 'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'id': '1',
              'status': 'done',
              'userName': '$myName',
              'message':
              messageType == 'text' ? '$textFromTextField' : '(Photo)',
              'notificationType':notificationType,
              'chatRoomId':chatRoomId
            },
            'to': peerUserToken,
          },
        ),
      );
    } catch (e) {
      print(e);
    }
  }
}
