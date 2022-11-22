import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:conversation/FireBaseHelpClasses/FireBaseFireStoreHelperClass.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

import 'ChatRoomScreen.dart';
import 'CreateNewGroup.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({Key? key}) : super(key: key);

  @override
  State<NewChatScreen> createState() => _NewChatScreen();
}

class _NewChatScreen extends State<NewChatScreen> {
  final auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> memberDetails = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> memberIds = [];
  FirebaseFirestore fireStore = FirebaseFirestore.instance;
  bool clicked = false;
  int? selectedIndex;
  late String? currentUserUid;
  late String memberUid;
  late String roomId;

  @override
  initState() {
    super.initState();
    retrieveUsers();
  }

  void createChatRoom(BuildContext context, Map<String, dynamic> map) async {
    List groupMemberIds = [];
    groupMemberIds.add(map['uniqueId']);
    groupMemberIds.add(auth.currentUser?.uid);
    fireStore.collection("chatroom").doc(roomId).set({
      "isGroup": false,
      "GroupName": map['name'],
      "creator": auth.currentUser?.displayName,
      "members": groupMemberIds,
      "time": FieldValue.serverTimestamp(),
      "groupId": roomId,
      "lastMessage": "",
      "activeMembers": [],
      "lastMessageId":"",
      "lastMessageContent":"",
      "lastMessageType":''
    });
    var rooms = [];
    await fireStore
        .collection('users')
        .doc(auth.currentUser?.uid)
        .get()
        .then((value) {
      rooms.addAll(value['roomDetails']);
      if (!rooms.contains(roomId)) {
        rooms.add(roomId);
        fireStore
            .collection('users')
            .doc(auth.currentUser?.uid)
            .update({'roomDetails': rooms});
        FireBaseFireStoreHelperClass.messagesCount(
            auth.currentUser?.uid, roomId);
      }
    });

    rooms.clear();
    await fireStore
        .collection('users')
        .doc(map['uniqueId'])
        .get()
        .then((value) {
      rooms.addAll(value['roomDetails']);
      if (!rooms.contains(roomId)) {
        rooms.add(roomId);
        fireStore
            .collection('users')
            .doc(map['uniqueId'])
            .update({'roomDetails': rooms});
        FireBaseFireStoreHelperClass.messagesCount(map['uniqueId'], roomId);
      }
    });
  }

  String chatRoomId() {
    var userAscii = currentUserUid?.codeUnits;
    int user1 = userAscii!.fold(0, (previous, current) => previous + current);
    var memberAscii = memberUid.codeUnits;
    int user2 = memberAscii.fold(
        0, (previousValue, element) => previousValue + element);
    if (user1 > user2) {
      return "$currentUserUid-$memberUid";
    } else {
      return "$memberUid-$currentUserUid";
    }
  }

  void retrieveUsers() async {
    currentUserUid = auth.currentUser?.uid;
    await fireStore
        .collection('users')
        .where("email", isNotEqualTo: auth.currentUser?.email)
        .get()
        .then((value) => {
              value.docs.forEach((element) {
                memberIds.add(element);
                memberDetails.add(element.data());
                print('element data:${element["email"]}');
                print(memberIds[0]['email']);
              }),
            });
    setState(() {
      memberDetails;
    });
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
        appBar: AppBar(title: const Text('New chat')),
        body: SizedBox(
          width: size.width,
          height: size.height,
          child: SingleChildScrollView(
            child: Column(children: [
              ListTile(
                  title: const Text("Create new Group"),
                  leading: const Icon(Icons.group_add_outlined),
                  onTap: () {
                    Navigator.of(context).push(PageTransition(
                      child: const CreateNewGroup(),
                      type: PageTransitionType.fade,
                      alignment: Alignment.centerLeft,
                      duration: const Duration(milliseconds: 200),
                    ));
                  }),
              ListView.builder(
                  shrinkWrap: true,
                  itemCount: memberDetails.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: () {
                        memberUid = memberIds[index].id;
                        roomId = chatRoomId();
                        createChatRoom(context, memberDetails[index]);
                        Navigator.of(context).pushAndRemoveUntil(
                          PageTransition(
                              child: ChatRoomScreen(
                                memberId: memberUid,
                                chatRoomId: roomId,
                                chatRoomName: memberDetails[index]['name'],
                              ),
                              type: PageTransitionType.bottomToTop),
                          (route) => route.isFirst,
                        );
                      },
                      leading: const Icon(Icons.person),
                      trailing: const Icon(Icons.message_outlined),
                      title: Text(memberDetails[index]['email']),
                      subtitle: Text(memberDetails[index]['name']),
                    );
                  }),
            ]),
          ),
        ));
  }
}
