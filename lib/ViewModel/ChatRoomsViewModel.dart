import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

class ChatRoomsViewModel extends ChangeNotifier {
  List _chatRooms = [];

  List get chatRooms => _chatRooms;

  void getChatRoomsFromServer(context, userChatRooms) async {
    await FirebaseFirestore.instance
        .collection('chatroom')
        .orderBy('lastMessage', descending: true)
        .get()
        .then((value) => {
      _chatRooms.clear(),
            value.docs.forEach((chatRoom) {
              var containsUserChatRoom = userChatRooms.any((element) => element ==chatRoom.data()['groupId']);
              if(containsUserChatRoom){
                _chatRooms.add(chatRoom.data());
              }
            })});
    notifyListeners();
  }

  //to get userChatRoom

  List _userChatRooms = [];

  void getChatRoomsCount(currentUseId, context) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUseId)
        .get()
        .then((value) =>{ _userChatRooms = value.data()?['roomDetails']});
    notifyListeners();
    if (_userChatRooms.isNotEmpty) {
      Provider.of<ChatRoomsViewModel>(context, listen: false)
          .getChatRoomsFromServer(context,_userChatRooms);
    }
  }


}
