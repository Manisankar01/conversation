import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'FireBaseHelpClasses/FireBaseFireStoreHelperClass.dart';
import 'ViewModel/ChatMessageViewModel.dart';
import 'ViewModel/ChatRoomsViewModel.dart';

class SampleGroupChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String groupName;
  final List memberIds;

  const SampleGroupChatScreen({
    Key? key,
    required this.chatRoomId,
    required this.groupName,
    required this.memberIds,
  }) : super(key: key);

  @override
  State<SampleGroupChatScreen> createState() => _SampleGroupChatScreenState();
}

class _SampleGroupChatScreenState extends State<SampleGroupChatScreen> {
  final messageTextController = TextEditingController();
  final fireStore = FirebaseFirestore.instance;

  final auth = FirebaseAuth.instance;

  File? imageFile;
  late Offset tapPosition;
  String editMessageId = '';
  bool isEditMessage = false;

  @override
  void initState() {
    super.initState();
    FireBaseFireStoreHelperClass.messagesCount(
        auth.currentUser?.uid, widget.chatRoomId);

  }

  @override
  void dispose() {
    super.dispose();
    FireBaseFireStoreHelperClass.messagesCount(
        auth.currentUser?.uid, widget.chatRoomId);

    FireBaseFireStoreHelperClass.removeFromActiveMembers(
        widget.chatRoomId, auth.currentUser?.uid);
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
          'messageId': messageId
        };

        await fireStore
            .collection('chatroom')
            .doc(widget.chatRoomId)
            .collection('chats')
            .doc(messageId)
            .set(messages);
        FireBaseFireStoreHelperClass.updateLastMessageTime(
            widget.chatRoomId, messageId, messageTextController.text, "text");
        messageTextController.clear();
        for (int i = 0; i < widget.memberIds.length; i++) {
          FireBaseFireStoreHelperClass.updateChatRoomMessagesCount(
              widget.memberIds[i], widget.chatRoomId);
        }
      } else {
        isEditMessage = false;
        FireBaseFireStoreHelperClass.editMessage(
            widget.chatRoomId, editMessageId, messageTextController.text);
      }
    } else {
      if (kDebugMode) {
        print("Enter some Text");
      }
    }
  }

  Future getImage() async {
    ImagePicker picker = ImagePicker();

    await picker.pickImage(source: ImageSource.gallery).then((xFile) {
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

      var activeMembersList = [];
      FireBaseFireStoreHelperClass.getActiveMembers(widget.chatRoomId)
          .then((value) => activeMembersList = value.first['activeMembers']);
      FireBaseFireStoreHelperClass.sendMessageToActiveMembers(
          widget.chatRoomId, activeMembersList);
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ChatMessageViewModel>(context, listen: false)
        .getChatMessages(widget.chatRoomId);
    final size = MediaQuery.of(context).size;
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
                ))
              ]),
          title: Text(widget.groupName),
          backgroundColor: Colors.black12,
          shadowColor: Colors.orangeAccent),
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
                            return ListView.builder(reverse: true,shrinkWrap: true,
                                itemCount: value.chatMessages.length,
                                itemBuilder: ((context, index) {
                                  var currentIndex = value.chatMessages[index];
                                  return GestureDetector(
                                      onTapDown: (details) => getTapPosition(details),
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
                                }));
                          })))),
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
                              child: Center(
                                child: IconButton(
                                    color: Colors.white,
                                    icon: const Icon(Icons.send),
                                    onPressed: onSendMessage),
                              )),
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
        Overlay.of(context)?.context.findRenderObject();
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

  Widget messages(Size size,  map, BuildContext context) {
    return map['type'] == "text"
        ? Container(
            width: size.width,
            alignment: map['sendBy'] == auth.currentUser?.displayName
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: map['sendBy'] == auth.currentUser?.displayName
                    ? Colors.orangeAccent
                    : Colors.lightBlue,
              ),
              child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: size.width / 2),
                  child: map['sendBy'] == auth.currentUser?.displayName
                      ? Text(
                          map['message'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        )
                      : Column(
                          children: [
                            Text(
                              map['sendBy'],
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              map['message'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            )
                          ],
                        )),
            ))
        : Container(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            height: size.height / 3.0,
            width: size.width / 2,
            alignment: map['sendBy'] == auth.currentUser?.displayName
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
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
    ;
  }
}

class ShowImage extends StatelessWidget {
  final String imageUrl;

  const ShowImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox(
          width: size.width,
          height: size.height,
          child: Image.network(imageUrl)),
    );
  }
}
