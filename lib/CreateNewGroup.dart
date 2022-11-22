import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

import 'GroupInformationScreen.dart';

class CreateNewGroup extends StatefulWidget {
  const CreateNewGroup({Key? key}) : super(key: key);

  @override
  State<CreateNewGroup> createState() => _CreateNewGroup();
}

class _CreateNewGroup extends State<CreateNewGroup> {
  final auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> memberDetails = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> memberIds = [];
  FirebaseFirestore fireStore = FirebaseFirestore.instance;
  bool clicked = false;
  int? selectedIndex;
  late String? currentUserUid;
  late String memberUid;
  List selected = [];
  List groupMembers = [];

  @override
  initState() {
    super.initState();
    retrieveUsers();
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
        .then((value) =>
    {
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
    return Scaffold(
        appBar: AppBar(title: const Text('Create Group')),
        floatingActionButton: groupMembers.length > 1
            ? FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                  PageTransition(child: GroupInformationScreen(
                    groupMembers: groupMembers,),
                      type: PageTransitionType.fade));
            }, child: const Icon(Icons.navigate_next))
            : const SizedBox(),
        body: ListView.builder(
            itemCount: memberDetails.length,
            itemBuilder: (context, index) {
              return Container(
                color:
                selected.contains(index) ? Colors.black26 : Colors.white,
                child: ListTile(
                  onTap: () {
                    setState(() {
                      if (selected.contains(index)) {
                        selected.remove(index);
                        groupMembers.remove(memberDetails[index]);
                        for (var element in groupMembers) {
                          print(
                              "Members Email After removing::${element["email"]}");
                        }
                      } else {
                        groupMembers.add(memberDetails[index]);
                        selected.add(index);
                        for (var element in groupMembers) {
                          print(
                              "Members Email after adding::${element["email"]}");
                        }
                      }
                      for (var element in groupMembers) {
                        print("Total members::${element["email"]}");
                      }
                    });
                  },
                  leading: const Icon(Icons.person),
                  title: Text(memberDetails[index]['email']),
                  subtitle: Text(memberDetails[index]['name']),
                ),
              );
            }));
  }
}
