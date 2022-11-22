import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:conversation/DataBaseHelpers/CurrentUserDetailsDb.dart';
import 'package:conversation/DataBaseHelpers/UserChatRoomsDb.dart';
import 'package:conversation/DataBaseHelpers/UserChatsDb.dart';
import 'package:conversation/FireBaseHelpClasses/FireBaseFireStoreHelperClass.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserDetailsStream {
  static FirebaseAuth auth = FirebaseAuth.instance;
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;
  static String? uniqueId;
  static String? fireBaseAccessToken;
  static String? name;
  static String? email;
  static bool? isGroup;
  static String? profilePicture;
  static List? roomDetails;
  static QuerySnapshot<Map<String, dynamic>>? currentUserDetails;
  static List? allChatRooms;
  static String? groupName;
  static String? creator;
  static String? groupId;
  static Timestamp? time;
  static List? members;
  static Timestamp? lastMessage;

  static void setUserDetailsInDb() async {
    currentUserDetails =
        await FireBaseFireStoreHelperClass.fetchCurrentUserDetails();
    currentUserDetails?.docs.first.data().forEach((key, value) {
      if (key == 'uniqueId') uniqueId = value;
      if (key == 'fireBaseAccessToken') fireBaseAccessToken = value;
      if (key == 'name') name = value;
      if (key == 'email') email = value;
      if (key == "profilePicture") profilePicture = "empty";
      if (key == 'isGroup') isGroup = value;
      if (key == "roomDetails") roomDetails = value;
    });
    var userChatRooms ='';
    roomDetails?.forEach((element) {
      userChatRooms += element+",";
    });
    var userDetails = await DataBaseHelper.instance.getDetails();
    if (userDetails.isEmpty) {
      DataBaseHelper.instance.add(UserDetailsDb(
          userChatRooms: userChatRooms,
          email: email,
          uniqueId: uniqueId,
          profilePicture: profilePicture,
          name: name,
          fireBaseAccessToken: fireBaseAccessToken,
          isGroup: isGroup.toString()));
    } else {
      DataBaseHelper.instance.update(UserDetailsDb(
          userChatRooms: userChatRooms,
          email: email,
          uniqueId: uniqueId,
          profilePicture: profilePicture,
          name: name,
          fireBaseAccessToken: fireBaseAccessToken,
          isGroup: isGroup.toString()));
    }
    var chatRooms = userChatRooms.split(",");
    var chatRoomsLength = chatRooms.length;
    if (chatRoomsLength > 0) {
      var userDetails = await DataBaseHelper.instance.getDetails();
      if(kDebugMode){
        print("userDetails:::${userDetails.first.userChatRooms}");
      }
      setChatRoomsToDb();
    }
  }

  static setChatRoomsToDb() async {
    var currentUserDetails =
        await FireBaseFireStoreHelperClass.fetchCurrentUserDetails();
    currentUserDetails.docs.first.data().forEach((key, value) {
      if (key == 'roomDetails') {
        roomDetails = value;
      }
    });
    allChatRooms =
        await FireBaseFireStoreHelperClass.fetchCurrentUserChatRooms();
    roomDetails?.forEach((userChatRoomId) {
      allChatRooms?.forEach((element) async {
        if (element['groupId'] == userChatRoomId) {
          creator = element['creator'];
          groupId = element['groupId'];
          isGroup = element['isGroup'];
          lastMessage = Timestamp.fromDate(DateTime.now());
          time = element['time'];
          members = element['members'];
          String memberIds = "";
          members?.forEach((e) => memberIds += e+",");
          var chatRooms = await DBUserChatRooms.instance.getDetails();
          if (chatRooms.isEmpty ||
              (chatRooms.any(
                  (chatRoom) => chatRoom.chatRoomId != element['groupId']))) {
            DBUserChatRooms.instance.add(UserChatRoomsDb(
                lastMessage: lastMessage?.millisecondsSinceEpoch??00,
                chatRoomMembers: memberIds,
                groupName: groupName,
                chatRoomId: groupId,
                isGroup: isGroup.toString(),
                time: time?.toDate().millisecondsSinceEpoch));
          } else {
            DBUserChatRooms.instance.update(UserChatRoomsDb(
                lastMessage: lastMessage?.millisecondsSinceEpoch,
                chatRoomMembers: memberIds,
                groupName: groupName,
                chatRoomId: groupId,
                isGroup: isGroup.toString(),
                time: time?.toDate().millisecondsSinceEpoch));
          }
        }
      });
    });
    var chatRooms = await DBUserChatRooms.instance.getDetails();
    if(kDebugMode){
      print("chatRooms::${chatRooms.length}");
    }
    setChatMessagesToDb();
  }

  static setChatMessagesToDb() async {
    var userChatRooms = await DBUserChatRooms.instance.getDetails();
    print("User chatRooms:: ${userChatRooms.length}");
    List<String>? chatRoomsList = userChatRooms.first.chatRoomId?.split(",");
    chatRoomsList?.forEach((chatRoomId) async {
      await FireBaseFireStoreHelperClass.fetchUserMessagesFromAllChatRooms(
              chatRoomId)
          .then((value) => {
                value.docs.forEach((element) async {
                  var chatMessagesList =
                      await DbUserChats.instance.getDetails();
                  if ((chatMessagesList.isEmpty) ||
                      (chatMessagesList.any((message) =>
                          message.messageId != element.data()['messageId']))) {
                    DbUserChats.instance.add(Chats(
                        type: element.data()['type'],
                        chatRoomId: element.data()['chatRoomId'],
                        time: element.data()['time'].millisecondsSinceEpoch,
                        sendBy: element.data()['sendBy'],
                        message: element.data()['message'],
                        isRead: element.data()['isRead'].toString(),
                        isEdited: element.data()['isEdited'].toString(),
                        messageId: element.data()['messageId']));
                  } else {
                    DbUserChats.instance.updateMessage(Chats(
                        type: element.data()['type'],
                        chatRoomId: element.data()['chatRoomId'],
                        time: element.data()['time'],
                        sendBy: element.data()['sendBy'],
                        message: element.data()['message'],
                        isRead: element.data()['isRead'].toString(),
                        isEdited: element.data()['isEdited'].toString(),
                        messageId: element.data()['messageId']));
                  }
                })
              });
    });
    var chatMessagesList =
    await DbUserChats.instance.getDetails();
    if(kDebugMode){
      print("userChatMessage::${chatMessagesList.length}");
    }
  }

  static removeUserData() {
    DBUserChatRooms.instance.delete();
    DataBaseHelper.instance.delete();
    DbUserChats.instance.deleteAllMessages();
  }
}
