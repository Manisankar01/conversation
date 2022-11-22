import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:conversation/Constsnts/ConstantValues.dart';
import 'package:conversation/FireBaseHelpClasses/FireBaseFireStoreHelperClass.dart';
import 'package:conversation/FireBaseHelpClasses/Method.dart';
import 'package:conversation/SampleChatRoomScreen.dart';
import 'package:conversation/SampleGroupChatScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';

import 'NewChatScreen.dart';
import 'UpdateLastMessageTime/LastMessageTime.dart';
import 'ViewModel/ChatRoomsViewModel.dart';

class SampleHomeScreen extends StatefulWidget {
  const SampleHomeScreen({Key? key}) : super(key: key);

  @override
  State<SampleHomeScreen> createState() => _SampleHomeScreenState();
}

class _SampleHomeScreenState extends State<SampleHomeScreen> {
  List sample = ChatRoomsViewModel().chatRooms;
  FirebaseAuth auth = FirebaseAuth.instance;
  File? croppedImageFile;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print("--widget--");
    Provider.of<ChatRoomsViewModel>(context, listen: false)
        .getChatRoomsCount(auth.currentUser?.uid, context);
    //This method needs to call when new chatRoom Is Created
    return Scaffold(
        appBar: AppBar(title: const Text("Conversation")),
        floatingActionButton: FloatingActionButton(
            onPressed: () =>
                Navigator.push(
                    context,
                    PageTransition(
                        alignment: Alignment.bottomCenter,
                        curve: Curves.easeInOut,
                        duration: const Duration(milliseconds: 600),
                        reverseDuration: const Duration(milliseconds: 600),
                        child: const NewChatScreen(),
                        childCurrent: widget,
                        type: PageTransitionType.rightToLeftJoined)),
            child: const Icon(Icons.person_add_alt_1_outlined)),
        drawer: Drawer(
            shape: Border.all(
              color: Colors.black,
              width: 2,
            ),
            backgroundColor: Colors.black,
            child: Padding(
                padding: const EdgeInsets.only(left: 10, top: 10),
                child: ListView(
                  children: [
                    DrawerHeader(
                        child: Center(
                            child: GestureDetector(
                              onTap: () {
                                _showAlert();
                              },
                              child: CircleAvatar(
                                backgroundImage: croppedImageFile != null
                                    ? FileImage(croppedImageFile!)
                                    : null,
                                radius: 60,
                                child: croppedImageFile == null
                                    ? const Icon(Icons.person, size: 60)
                                    : null,
                              ),
                            ))),
                    GestureDetector(
                        onTap: () {},
                        child: Row(children: [
                          const Icon(Icons.map, color: Colors.blue),
                          const SizedBox(
                            width: 10,
                          ),
                          Text('${auth.currentUser?.email}',
                              style: const TextStyle(color: Colors.white54)),
                        ])),
                    const SizedBox(
                      height: 10,
                    ),
                    const Divider(color: Colors.white70),
                    GestureDetector(
                      onTap: () {
                        FireBaseFireStoreHelperClass.deleteAccessToken();
                        logOut(context);
                        snackBar(context, 'log out successfully');
                      },
                      child: Row(children: const [
                        Icon(Icons.logout, color: Colors.blue),
                        SizedBox(
                          width: 10,
                        ),
                        Text('Logout',
                            style: TextStyle(fontSize: 20, color: Colors.blue))
                      ]),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const Divider(color: Colors.white70)
                  ],
                ))),
        body: Consumer<ChatRoomsViewModel>(
          builder: ((context, value, child) {
            return ListView.builder(
                itemCount: value.chatRooms.length,
                itemBuilder: (context, index) {
                  var currentIndex = value.chatRooms[index];
                  if (currentIndex['lastMessage'] != "") {
                    List chatMembers = currentIndex['members'];
                    chatMembers.remove(auth.currentUser?.uid);
                    int message =
                        currentIndex['lastMessage'].millisecondsSinceEpoch;
                    var lastMessageTime =
                    MessageTime.updateMessageTimeOnChatRoom(message);

                    bool isGroup = currentIndex["isGroup"];
                    var chatRoomName = isGroup == true
                        ? currentIndex["GroupName"]
                        : auth.currentUser?.displayName ==
                        currentIndex['GroupName']
                        ? currentIndex['creator']
                        : currentIndex['GroupName'];
                    return ListTile(
                      onTap: () =>{
                          Navigator.push(
                              context, PageTransition(
                              child: isGroup ? SampleGroupChatScreen(
                                  chatRoomId: currentIndex['groupId'],
                                  groupName: chatRoomName,
                                  memberIds: currentIndex['members']) : SampleChatRoomScreen(
                                  chatRoomId:currentIndex['groupId'], chatRoomName:chatRoomName, memberId:chatMembers.first),
                              type: PageTransitionType.rightToLeft))},
                      leading: isGroup
                          ? const Icon(Icons.groups)
                          : const Icon(Icons.person),
                      title: Text("$chatRoomName"),
                      trailing: Text('$lastMessageTime'),
                      subtitle: currentIndex['lastMessageType'] == 'img'
                          ? Row(children: const [
                        Icon(Icons.photo),
                        SizedBox(),
                        Text("Photo")
                      ])
                          : Text('${currentIndex['lastMessageContent']}'),
                    );
                  } else {
                    return const SizedBox();
                  }
                });
          }),
        ));
  }

  void _showAlert() {
    showDialog(
        context: context,
        builder: (context) {
          return (AlertDialog(
            title: const Text('Choose One'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(
                onTap: () => {openCamera(), closePop()},
                child: Row(children: const [
                  Icon(
                    Icons.camera,
                  ),
                  Text('Camera')
                ]),
              ),
              const SizedBox(
                height: 10,
              ),
              GestureDetector(
                onTap: () =>
                {
                  openGallery(),
                  closePop(),
                },
                child: Row(children: const [
                  Icon(
                    Icons.photo,
                  ),
                  Text('Gallery')
                ]),
              ),
            ]),
          ));
        });
  }

  void openCamera() async {
    File? imageFile;
    await ImagePicker().pickImage(source: ImageSource.camera).then((xFile) {
      if (xFile != null) {
        imageFile = File(xFile.path);
        cropImage(imageFile!);
      }
    });
  }

  void openGallery() async {
    File? imageFile;
    await ImagePicker().pickImage(source: ImageSource.gallery).then((xFile) =>
    {
      if (xFile != null)
        {
          imageFile = File(xFile.path),
          cropImage(imageFile!),
        }
    });
  }

  void cropImage(File imageFile) async {
    await ImageCropper()
        .cropImage(sourcePath: imageFile.path, aspectRatioPresets: [
      CropAspectRatioPreset.original,
      CropAspectRatioPreset.square,
      CropAspectRatioPreset.ratio3x2,
      CropAspectRatioPreset.ratio4x3,
      CropAspectRatioPreset.ratio16x9
    ], uiSettings: [
      AndroidUiSettings(
          toolbarTitle: 'cropper',
          toolbarColor: Colors.deepOrangeAccent,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false)
    ]).then((value) async {
      if (value != null) {
        setState(() {
          croppedImageFile = File(value.path);
        });
      }
    });
  }

  void closePop() {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
