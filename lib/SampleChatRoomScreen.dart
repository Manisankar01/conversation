import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:conversation/Constsnts/ConstantValues.dart';
import 'package:conversation/FireBaseHelpClasses/FireBaseFireStoreHelperClass.dart';
import 'package:conversation/LocalNotifications.dart';
import 'package:conversation/ViewModel/ChatMessageViewModel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SampleChatRoomScreen extends StatefulWidget {
  final String chatRoomId;
  final String chatRoomName;
  final String memberId;

  const SampleChatRoomScreen({
    Key? key,
    required this.chatRoomId,
    required this.chatRoomName,
    required this.memberId,
  }) : super(key: key);

  @override
  State<SampleChatRoomScreen> createState() => _SampleChatRoomScreenState();
}

class _SampleChatRoomScreenState extends State<SampleChatRoomScreen> {
  final messageTextController = TextEditingController();

  final fireStore = FirebaseFirestore.instance;

  final auth = FirebaseAuth.instance;
  NotificationServices notificationServices = NotificationServices();
  File? imageFile;

  var membersList = [];
  late Offset tapPosition;
  bool isEditMessage = false;
  String editMessageId = '';
  String editMessage = '';
  String memberId = '';
  String receiverAccessToken = '';

  @override
  void initState() {
    super.initState();
    activeChatRoom();
    getAccessToken(widget.memberId);
    // FireBaseFireStoreHelperClass.messagesCount(
    //     auth.currentUser?.uid, widget.chatRoomId);
  }

  getAccessToken(userId) async {

    await FirebaseFirestore.instance.collection('users').doc(userId)
        .get()
        .then((value) => receiverAccessToken = value.data()?['fireBaseAccessToken']);


  }

  activeChatRoom() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    var activeChatRoom = preferences.setString('activeRoomId', widget.chatRoomId);
    print("activeChatRoom$activeChatRoom");
  }

  removeFromChatRoom() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.remove('activeRoomId');
    print('activeChatRoomRemoved');
  }

  @override
  void dispose() {
    super.dispose();
    removeFromChatRoom();
    FireBaseFireStoreHelperClass.messagesCount(
        auth.currentUser?.uid, widget.chatRoomId);
  }

  void onSendMessage() async {
    if (messageTextController.text.isNotEmpty) {
      if (!isEditMessage) {
        String messageId = const Uuid().v1();
        Map<String, dynamic> messages = {
          "sendBy": auth.currentUser?.displayName,
          "message": messageTextController.text,
          "type": "text",
          "isEdited": false,
          "time": DateTime.now(),
          'isRead': false,
          'chatRoomId': widget.chatRoomId,
          "messageId": messageId
        };
        await fireStore
            .collection('chatroom')
            .doc(widget.chatRoomId)
            .collection('chats')
            .doc(messageId)
            .set(messages)
            .catchError((error) {
          print('message sending failed');
        });
        print('message send');
        FireBaseFireStoreHelperClass.sendNotificationMessageToPeerUser(
            1, "text", messageTextController.text,
            auth.currentUser?.displayName, receiverAccessToken, "message",widget.chatRoomId);
        FireBaseFireStoreHelperClass.updateLastMessageTime(
            widget.chatRoomId, messageId, messageTextController.text, "text");
        messageTextController.clear();
        FireBaseFireStoreHelperClass.updateChatRoomMessagesCount(
            widget.memberId, widget.chatRoomId);
        print("firbaseAccesToken:${fireBaseCloudServerToken}");
        if((receiverAccessToken.isNotEmpty)&&(receiverAccessToken!=null)) {

        }
      } else {
        isEditMessage = false;
        FireBaseFireStoreHelperClass.editMessage(
            widget.chatRoomId, editMessageId, messageTextController.text);
      }
      // FireBaseFireStoreHelperClass.sendNotificationMessageToPeerUser(
      //   1,
      //   'text',
      //   'newNotification',
      //   'mani',
      //   "dMJICoCESJqg9zTey7tiP0:APA91bHiqnsfHgDgBS5J42fyx5-JkPJb8zvHPOar2tr7pnIRwj8InNEUngfS5nJsPvhOXj63ROoDAxVr59u0ShVwYqV6Zn5qXaKtdqt4iGSM8WejI5LYcPo9_Z0rQG6VRoJsgXU3qCDl",
      // );
    } else {
      if (kDebugMode) {
        print("Enter some Text");
      }
    }
  }

  Future getImage() async {
    ImagePicker picker = ImagePicker();

    await picker.pickImage(source: ImageSource.camera).then((xFile) {
      if (xFile != null) {
        imageFile = File(xFile.path);
        uploadImage();
      }
    });
  }

  Future uploadImage() async {
    String fileName = const Uuid().v1();
    int status = 1;
    await fireStore
        .collection('chatroom')
        .doc(widget.chatRoomId)
        .collection('chats')
        .doc(fileName)
        .set({
      "sendBy": auth.currentUser?.displayName,
      "message": "",
      "type": "img",
      "isEdited": false,
      "time": DateTime.now(),
      'isRead': false,
      'chatRoomId': widget.chatRoomId,
      'messageId': fileName
    });

    var ref =
    FirebaseStorage.instance.ref().child('images').child("$fileName.jpg");

    var uploadTask = await ref.putFile(imageFile!).catchError((error) async {
      await fireStore
          .collection('chatroom')
          .doc(widget.chatRoomId)
          .collection('chats')
          .doc(fileName)
          .delete();

      status = 0;
    });

    if (status == 1) {
      String imageUrl = await uploadTask.ref.getDownloadURL();
      await fireStore
          .collection('chatroom')
          .doc(widget.chatRoomId)
          .collection('chats')
          .doc(fileName)
          .update({"message": imageUrl});
      FireBaseFireStoreHelperClass.updateLastMessageTime(
          widget.chatRoomId, fileName, imageUrl, "img");
      print(imageUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    print("--chatRoomWidget--");
    final size = MediaQuery
        .of(context)
        .size;
    Provider.of<ChatMessageViewModel>(context,listen: false)
        .getChatMessages(widget.chatRoomId);
    return Scaffold(
      appBar: AppBar(
          leading: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back)),
                ),
                Expanded(
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.account_circle, size: 40),
                    )),
              ]),
          title: Text("  ${widget.chatRoomName}"),
          // StreamBuilder<DocumentSnapshot>(
          //   stream:
          //   fireStore.collection('users').doc(widget.memberId).snapshots(),
          //   builder: (context, snapshot) {
          //     if (snapshot.data != null) {
          //       if (snapshot.data?['status'] != "Online") {
          //         // setState(() {});
          //       }
          //       return Container(
          //           padding: const EdgeInsetsDirectional.only(start: 10),
          //           child: Column(mainAxisSize: MainAxisSize.min, children: [
          //             Text('${snapshot.data?['name']}',
          //                 style: const TextStyle(fontSize: 16)),
          //             Text('${snapshot.data?['status']}',
          //                 style: const TextStyle(fontSize: 12))
          //           ]));
          //     } else {
          //       return const SizedBox();
          //     }
          //   },
          // ),
          backgroundColor: Colors.orangeAccent,
          shadowColor: Colors.black),
      body: SizedBox(
          height: size.height,
          child: Column(
            children: [
              Expanded(
                  flex: 7,
                  child: SizedBox(
                    width: size.width,
                    child: Consumer<ChatMessageViewModel>(
                        builder: ((context, value, child) {
                          return ListView.builder(
                            shrinkWrap: true, reverse: true,
                            itemCount: value.chatMessages.length,
                            itemBuilder: ((context, index) {
                              var currentIndex = value.chatMessages[index];
                              return GestureDetector(
                                  onTapDown: (details) =>
                                      getTapPosition(details),
                                  onLongPress: () async {
                                    if (currentIndex['sendBy'] ==
                                        auth.currentUser?.displayName) {
                                      await showContextMenu(
                                          context,
                                          currentIndex['messageId'],
                                          currentIndex['message'],
                                          currentIndex['type']);
                                    }
                                  },
                                  child: messages(size, currentIndex, context));
                            }),
                          );
                        })),
                  )),
              Expanded(
                  flex: 1,
                  child: Container(
                    width: size.width,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 7,
                          child: TextField(
                            controller: messageTextController,
                            decoration: InputDecoration(
                                suffixIcon: IconButton(
                                    onPressed: () => getImage(),
                                    icon: const Icon(Icons.image)),
                                hintText: "Send Message",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                )),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          flex: 1,
                          child: Container(
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.orangeAccent),
                              child: IconButton(
                                  color: Colors.white,
                                  icon: const Icon(Icons.send),
                                  onPressed: onSendMessage)),
                        ),
                        const SizedBox(width: 5)
                      ],
                    ),
                  )),
            ],
          )),
    );
  }

  showContextMenu(BuildContext context, messageId, message, type) async {
    final RenderObject? overlay =
    Overlay
        .of(context)
        ?.context
        .findRenderObject();
    if (type == "text") {
      final result = await showMenu(
        context: context,
        position: RelativeRect.fromRect(
            Rect.fromLTWH(tapPosition.dx, tapPosition.dy, 30, 30),
            Rect.fromLTWH(0, 0, overlay!.paintBounds.size.width,
                overlay.paintBounds.size.height)),
        items: [
          const PopupMenuItem(value: "Edit", child: Text('Edit')),
          const PopupMenuItem(value: "Delete", child: Text('Delete'))
        ],
      );
      switch (result) {
        case 'Edit':
          messageTextController.text = message;
          editMessageId = messageId;
          setState(() {
            isEditMessage = true;
          });
          break;
        case 'Delete':
          FireBaseFireStoreHelperClass.deleteMessage(
              widget.chatRoomId, messageId);
          break;
      }
    } else {
      final result = await showMenu(
        context: context,
        position: RelativeRect.fromRect(
            Rect.fromLTWH(tapPosition.dx, tapPosition.dy, 30, 30),
            Rect.fromLTWH(0, 0, overlay!.paintBounds.size.width,
                overlay.paintBounds.size.height)),
        items: [const PopupMenuItem(value: "Delete", child: Text('Delete'))],
      );
      switch (result) {
        case 'Delete':
          FireBaseFireStoreHelperClass.deleteMessage(
              widget.chatRoomId, messageId);
          break;
      }
    }
  }

  getTapPosition(TapDownDetails details) {
    final RenderBox referenceBox = context.findRenderObject() as RenderBox;
    tapPosition = referenceBox.globalToLocal(details.globalPosition);
  }

  Widget messages(Size size, map, BuildContext context) {
    return map['type'] == "text"
        ? Row(
      mainAxisAlignment: map['sendBy'] == auth.currentUser?.displayName
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        (map['sendBy'] == auth.currentUser?.displayName &&
            map['isEdited'])
            ? const Icon(
          Icons.edit,
          size: 15,
        )
            : const SizedBox(),
        Container(
          padding:
          const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: map['sendBy'] == auth.currentUser?.displayName
                ? Colors.orangeAccent
                : Colors.lightBlue,
          ),
          child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: size.width / 2),
              child: Text(
                map['message'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              )),
        ),
        (map['sendBy'] != auth.currentUser?.displayName &&
            map['isEdited'])
            ? const Icon(Icons.edit, size: 15)
            : const SizedBox()
      ],
    )
        : Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      height: size.height / 3.0,
      width: size.width / 2,
      alignment: map['sendBy'] == auth.currentUser?.displayName
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () =>
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ShowImage(imageUrl: map['message']))),
        child: Container(
            height: size.height / 3.0,
            width: size.width / 2,
            alignment: map['message'] != "" ? null : Alignment.center,
            decoration: BoxDecoration(
                border: Border.all(
                    color: map['sendBy'] == auth.currentUser?.displayName
                        ? Colors.orangeAccent
                        : Colors.lightBlue,
                    width: 2),
                borderRadius: BorderRadius.circular(20)),
            child: map['message'] != ""
                ? ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Hero(
                  tag: 'effect',
                  child: CachedNetworkImage(
                    imageUrl: map['message'],
                    fit: BoxFit.cover,
                  ),
                ))
                : const CircularProgressIndicator()),
      ),
    );
  }
}

class ShowImage extends StatelessWidget {
  final String imageUrl;

  const ShowImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery
        .of(context)
        .size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox(
          width: size.width,
          height: size.height,
          child: Hero(
              tag: 'effect', child: CachedNetworkImage(imageUrl: imageUrl))),
    );
  }
}
