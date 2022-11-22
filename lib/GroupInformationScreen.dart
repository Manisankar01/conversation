import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:conversation/GroupChatScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:uuid/uuid.dart';

class GroupInformationScreen extends StatefulWidget {
  final List groupMembers;

  const GroupInformationScreen({Key? key, required this.groupMembers})
      : super(key: key);

  @override
  State<GroupInformationScreen> createState() => _GroupInformationScreen();
}

class _GroupInformationScreen extends State<GroupInformationScreen> {
  var groupNameText = TextEditingController();
  final fireStore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  void createGroup(BuildContext context) async {
    List groupMemberIds = [];
    for (var i = 0; i < widget.groupMembers.length; i++) {
      groupMemberIds.add(widget.groupMembers[i]['uniqueId']);
    }
    groupMemberIds.add(auth.currentUser?.uid);
    String groupId = const Uuid().v1();
    fireStore.collection("chatroom").doc(groupId).set({
      "isGroup": true,
      "GroupName": groupNameText.text,
      "creator": auth.currentUser?.displayName,
      "members": groupMemberIds,
      "time": FieldValue.serverTimestamp(),
      "groupId": groupId,
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
      rooms.add(groupId);
      fireStore
          .collection('users')
          .doc(auth.currentUser?.uid)
          .update({'roomDetails': rooms});
    });

    for (int i = 0; i < widget.groupMembers.length; i++) {
      rooms.clear();
      await fireStore
          .collection('users')
          .doc(widget.groupMembers[i]['uniqueId'])
          .get()
          .then((value) {
        rooms.addAll(value['roomDetails']);
        rooms.add(groupId);
        fireStore
            .collection('users')
            .doc(widget.groupMembers[i]['uniqueId'])
            .update({'roomDetails': rooms});
      });
    }

    Navigator.of(context).pushAndRemoveUntil(
      PageTransition(
          child: GroupChatScreen(
            groupName: groupNameText.text,
            chatRoomId: groupId,
            memberIds: groupMemberIds,
          ),
          type: PageTransitionType.rightToLeft),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupMembers = widget.groupMembers;
    var size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(title: const Text("Group Information")),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (groupNameText.text.isNotEmpty) {
              createGroup(context);
            }
          },
          child: const Icon(Icons.check)),
      body: SizedBox(
          height: size.height,
          width: size.width,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Align(
                alignment: Alignment.topLeft,
                child: Column(children: [
                  Container(
                      width: size.width,
                      color: Colors.black26,
                      child: const Padding(
                        padding: EdgeInsetsDirectional.only(
                            bottom: 10, top: 10, start: 5),
                        child:
                            Text("GroupName", style: TextStyle(fontSize: 15)),
                      )),
                  TextField(
                    controller: groupNameText,
                    decoration:
                        const InputDecoration(hintText: 'Enter Group Name'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Container(
                      padding: const EdgeInsetsDirectional.only(
                          top: 10, bottom: 10, start: 5),
                      width: size.width,
                      color: Colors.black26,
                      child: const Text("Group Members"),
                    ),
                  ),
                  Container(
                    color: Colors.white60,
                    child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: groupMembers.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(groupMembers[index]['name']),
                            leading: const Icon(Icons.person),
                            subtitle: Text(groupMembers[index]['email']),
                          );
                        }),
                  )
                ]),
              ))),
    );
  }
}
