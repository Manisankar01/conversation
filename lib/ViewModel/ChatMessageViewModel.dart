import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ChatMessageViewModel extends ChangeNotifier{
  List _chatMessages = [];
  List get chatMessages => _chatMessages;

  void getChatMessages(chatRoomId) async {
    await FirebaseFirestore.instance
        .collection('chatroom')
        .doc(chatRoomId).collection('chats').orderBy("time", descending: true)
        .get()
        .then((value) => _chatMessages =value.docs);
    notifyListeners();
  }
}