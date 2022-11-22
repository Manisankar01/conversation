import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:conversation/Constsnts/ConstantValues.dart';
import 'package:conversation/DataBaseHelpers/CurrentUserDetailsDb.dart';
import 'package:conversation/FireBaseHelpClasses/FireBaseFireStoreHelperClass.dart';
import 'package:conversation/FireBaseHelpClasses/Method.dart';
import 'package:conversation/LocalNotifications.dart';
import 'package:conversation/NewChatScreen.dart';
import 'package:conversation/UserDetailsStream.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ChatRoomScreen.dart';
import 'GroupChatScreen.dart';
import 'UpdateLastMessageTime/LastMessageTime.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> with WidgetsBindingObserver {
  FirebaseFirestore fireStore = FirebaseFirestore.instance;
  NotificationServices notificationServices = NotificationServices();
  final auth = FirebaseAuth.instance;
  var chatRooms = [];
  late String memberUid;
   List? userChatRooms ;
  var messageDetails = '';
  var chatsInGroup = false;
   File? croppedImageFile;
  String chatRoomName = '';
  String chatMemberId = '';
  int messagesCount = 0;
  var searchTextController = TextEditingController();
  var currentUserDetails;


  @override
  void initState() {
    super.initState();
    notificationServices.initialiseNotifications();
    WidgetsBinding.instance.addObserver(this);
    setStatus("Online");

    FireBaseFireStoreHelperClass.sendNotificationMessageToPeerUser(10,"text","checking","user","e2YXDlOjSY-Xe2kp_UZWSU:APA91bF8ov1_Za7xmqolm3M8SNioyu49u03REdoy2s6gsOOIe5GE6xoMXE73IVPGvMMt-EZ5kmbbRCH1dnDIHRcBZ17iRa8l07Mxm7QScRWhqIczUYtMBQXUgA6ELavi7Z6gu8KyQ9Pj","message");
    // UserDetailsStream.removeUserData();
    UserDetailsStream.setUserDetailsInDb();

  }
  void loadImage()async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
   var image =  preferences.getString('profileImage');
   if(image!=null){
     setState((){  croppedImageFile = File(image);
     });
   }
  }


  void setStatus(String status) async {
    await fireStore.collection('users').doc(auth.currentUser?.uid).update({
      "status": status,
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setStatus("Online");
    } else {
      setStatus("Offline");
    }
  }


  gettingUserChatRoom() async {
    await fireStore
        .collection('users')
        .doc(auth.currentUser?.uid)
        .get()
        .then((value) {
      userChatRooms = value.data()?['roomDetails'];
    });
    setState(() {
      userChatRooms;
    });
  }

  updatingValues() async {
    List data = [];
    fireStore
        .collection('users')
        .doc(auth.currentUser?.uid)
        .get()
        .then((value) {
      data.addAll(value['roomDetails']);
      print(value['roomDetails']);
      data.add('customRoomId');
      fireStore
          .collection('users')
          .doc(auth.currentUser?.uid)
          .update({'roomDetails': data});
    });
  }

  Future<String> fetchLastMessage(String roomId) async {
    var lastMessage = await fireStore
        .collection('chatroom')
        .doc(roomId)
        .collection('chats')
        .orderBy("time", descending: true)
        .limit(1)
        .get();
    return "${lastMessage.docs.first['sendBy']}::${lastMessage.docs.first['message']}";
  }

  memberName(String memberId) async {
    await fireStore.collection('users').doc(memberId).get().then((value) => {
          chatRoomName = value.data()?['name'],
          chatMemberId = value.data()?['uniqueId']
        });
  }

  openChatRoom(String roomId, List members, String creator) async {
    creator == auth.currentUser?.uid
        ? memberName(members.first)
        : memberName(creator);
    Navigator.push(
        context,
        PageTransition(
            child: ChatRoomScreen(
              memberId: chatMemberId,
              chatRoomId: roomId,
              chatRoomName: chatRoomName,
            ),
            type: PageTransitionType.rightToLeft));
  }
  Future<String?> active()async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString('chatRoomId');

  }
  bool activeChatRoom(chatRoomId) {
  String? roomId = "";
      active().then((value) => roomId = value);
    if(roomId!=null) {
      if (chatRoomId == roomId) {
        return false;
      }
      else {
        return true;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    gettingUserChatRoom();
    if (kDebugMode) {
      print("-----WIDGET----------");
    }
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
            title: const Text('Conversation'),
            surfaceTintColor: Colors.white54),
        floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.push(
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
                      child:  CircleAvatar(backgroundImage:croppedImageFile!=null?FileImage(croppedImageFile!):null,
                        radius: 60,
                        child:croppedImageFile==null? const Icon(Icons.person, size: 60):null,
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
        body: SingleChildScrollView(
          child: Container(
              child: userChatRooms==null?const Center(child: CircularProgressIndicator(),):userChatRooms!.isEmpty
                  ? const Center(
                      child: ListTile(title: Text('No chat Rooms')),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: fireStore
                          .collection('chatroom')
                          .orderBy('lastMessage', descending: true)
                          .snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.data != null) {
                          return ListView.separated(
                            shrinkWrap: true,
                            itemCount: snapshot.data?.size ?? 0,
                            itemBuilder: (context, index) {

                              var groupId =
                                  snapshot.data?.docs[index]['groupId'];
                              var isThere = userChatRooms?.any((element) =>
                                  element ==
                                  snapshot.data?.docs[index]['groupId']);
                              bool isGroup =
                                  snapshot.data?.docs[index]['isGroup'];
                              int messages = 0;
                              FireBaseFireStoreHelperClass.checkMessages(
                                      snapshot.data?.docs[index]['groupId'])
                                  .then((value) => messages = value);
                              if (messages > 0) {
                                setState(() {
                                  chatsInGroup = true;
                                });
                              }
                              return (isThere!)
                                  ?
                                  // chatsInGroup?
                                  StreamBuilder<QuerySnapshot>(
                                      stream: fireStore
                                          .collection('chatroom')
                                          .doc(groupId)
                                          .collection('chats')
                                          .orderBy('time', descending: true)
                                          .limit(1)
                                          .snapshots(),
                                      builder: (context,
                                          AsyncSnapshot<QuerySnapshot>
                                              lastMessage) {
                                        if (lastMessage.data != null) {
                                          if (lastMessage.hasData) {
                                            if ((lastMessage.data?.docs
                                                        .first['sendBy'] !=
                                                    auth.currentUser
                                                        ?.displayName) &&
                                                (!lastMessage.data?.docs
                                                        .first['isRead'])&&(!activeChatRoom(groupId))) {
                                              notificationServices
                                                  .sendNotification(
                                                      lastMessage.data?.docs
                                                          .first['sendBy'],
                                                      lastMessage.data?.docs
                                                          .first['message']);
                                              // FireBaseFireStoreHelperClass
                                              //     .stopNotification(
                                              //         groupId,
                                              //         lastMessage
                                              //             .data?.docs.first.id);
                                            }
                                            else{
                                              FireBaseFireStoreHelperClass
                                                  .stopNotification(
                                                  groupId,
                                                  lastMessage
                                                      .data?.docs.first.id);
                                            }
                                            FireBaseFireStoreHelperClass
                                                    .getUnReadMessageCount(
                                                        auth.currentUser?.uid,
                                                        groupId)
                                                .then((value) =>
                                                    messagesCount = value);
                                            Timestamp time = lastMessage
                                                .data?.docs.first['time'];
                                            var value = MessageTime
                                                .updateMessageTimeOnChatRoom(
                                                    time.millisecondsSinceEpoch);
                                            return ListTile(
                                              trailing: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(value),
                                                    const SizedBox(height: 5),
                                                    (messagesCount > 0)
                                                        ? CircleAvatar(
                                                            backgroundColor:
                                                                Colors.green,
                                                            radius: 10,
                                                            child: Text(
                                                                '$messagesCount',
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                )),
                                                          )
                                                        : SizedBox(),
                                                  ]),
                                              onTap: () async {
                                                isGroup
                                                    ? Navigator.push(
                                                        context,
                                                        PageTransition(
                                                            child:
                                                                GroupChatScreen(
                                                              chatRoomId: snapshot
                                                                          .data
                                                                          ?.docs[
                                                                      index]
                                                                  ['groupId'],
                                                              groupName: snapshot
                                                                          .data
                                                                          ?.docs[
                                                                      index]
                                                                  ['GroupName'],
                                                              memberIds: snapshot
                                                                          .data
                                                                          ?.docs[
                                                                      index]
                                                                  ['members'],
                                                            ),
                                                            type: PageTransitionType
                                                                .rightToLeft))
                                                    : openChatRoom(
                                                        snapshot.data
                                                                ?.docs[index]
                                                            ['groupId'],
                                                        snapshot.data
                                                                ?.docs[index]
                                                            ['members'],
                                                        snapshot.data
                                                                ?.docs[index]
                                                            ['creator']);
                                              },
                                              leading: CircleAvatar(
                                                child: snapshot.data
                                                        ?.docs[index]['isGroup']
                                                    ? const Icon(Icons.groups)
                                                    : const Icon(Icons.person),
                                              ),
                                              title: Text(
                                                  '${snapshot.data?.docs[index]['GroupName']}'),
                                              subtitle: lastMessage.data?.docs
                                                          .first['type'] ==
                                                      "text"
                                                  ? Text(lastMessage.data?.docs
                                                      .first['message'])
                                                  : Container(
                                                      alignment:
                                                          Alignment.topLeft,
                                                      child: const Icon(
                                                          Icons.image)),
                                            );
                                          } else if (lastMessage.hasError) {
                                            return const SizedBox();
                                          } else {
                                            return const Text('');
                                          }
                                        } else if(lastMessage.hasError) {
                                          return const Text('last message not found');
                                        }
                                        else {
                                          return SizedBox();
                                        }
                                      })
                                  /*
                            ListTile(
                          onTap: () {
                            isGroup
                                ? Navigator.push(
                                context,
                                PageTransition(
                                    child:
                                    GroupChatScreen(
                                      chatRoomId: snapshot
                                          .data
                                          ?.docs[
                                      index]
                                      ['groupId'],
                                      groupName: snapshot
                                          .data
                                          ?.docs[
                                      index][
                                      'GroupName'],
                                    ),
                                    type: PageTransitionType
                                        .rightToLeft))
                                : Navigator.push(
                                context,
                                PageTransition(
                                    child:
                                    ChatRoomScreen(
                                      chatRoomId: snapshot
                                          .data
                                          ?.docs[
                                      index]
                                      ['groupId'],
                                      groupName: snapshot
                                          .data
                                          ?.docs[
                                      index][
                                      'GroupName'],
                                    ),
                                    type: PageTransitionType
                                        .rightToLeft));
                          },
                          leading: CircleAvatar(
                            child: snapshot
                                .data?.docs[index]
                            ['isGroup']
                                ? const Icon(Icons.groups)
                                : const Icon(
                                Icons.person),
                          ),
                          title: Text(
                              '${snapshot.data
                                  ?.docs[index]['GroupName']}'),
                        )
                          */
                                  : SizedBox();
                            },
                            separatorBuilder:
                                (BuildContext context, int index) {
                              return const Divider();
                            },
                          );
                        } else if (snapshot.hasError) {
                          return const Center(
                            child: Text('Failed to fetch Details'),
                          );
                        } else if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else {
                          return const Text('No Data found');
                        }
                      },
                    )),
        ),
      ),
    );
  }

  void _showAlert() {
    showDialog(
        context: context,
        builder: (context) {
          return (AlertDialog(
            title: const Text('Choose One'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(
                onTap: () => {openCamera(),closePop()},
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
                onTap: () => {openGallery(),closePop(),},
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
    await ImagePicker().pickImage(source: ImageSource.gallery).then((xFile) => {
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
        setState((){
          croppedImageFile = File(value.path);
        });
      }
    });
  }

  void closePop() {
    Navigator.of(context,rootNavigator: true).pop();
  }
}