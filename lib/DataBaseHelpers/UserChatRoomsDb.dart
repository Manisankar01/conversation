import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class UserChatRoomsDb {
  final String? chatRoomId;
  final int? lastMessage;
  final int? time;
  final String? isGroup;
  final String? groupName;
  final String? chatRoomMembers;

  UserChatRoomsDb(
      {this.chatRoomId,
      this.lastMessage,
      this.time,
      this.isGroup,
      this.groupName,
      required this.chatRoomMembers});

  factory UserChatRoomsDb.fromMap(Map<String, dynamic> json) => UserChatRoomsDb(
        chatRoomId: json['chatRoomId'],
    lastMessage: json['lastMessage'],
        time: json['time'],
        isGroup: json['isGroup'],
        groupName: json['groupName'],
        chatRoomMembers: json['chatRoomMembers'],
      );



  Map<String, dynamic> toMap() {
    return {
      'chatRoomId': chatRoomId,
      'lastMessage': lastMessage,
      'time': time,
      'isGroup': isGroup,
      'groupName': groupName,
      'chatRoomMembers': chatRoomMembers
    };
  }
}

class ChatRoomMembers {
  String? memberId;

  ChatRoomMembers({required this.memberId});

  factory ChatRoomMembers.fromMap(Map<String, dynamic> json) =>
      ChatRoomMembers(memberId: json['memberId']);

  Map<String, dynamic> toMap() {
    return {'memberId': memberId};
  }
}


class DBUserChatRooms {
  DBUserChatRooms._privateConstructor();

  static final DBUserChatRooms instance = DBUserChatRooms._privateConstructor();

  static Database? _database;

  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'UserChatRooms.db');
    print('User chatRoom db created');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''CREATE TABLE UserChatRooms(
 chatRoomId STRING,
 lastMessage STRING,
       time INTEGER,
     isGroup STRING,
     groupName STRING,
     chatRoomMembers STRING
        )''');
    print('table created');
  }

  Future<List<UserChatRoomsDb>> getDetails() async {
    Database db = await instance.database;
    var details = await db.query('UserChatRooms');

    List<UserChatRoomsDb> userChatRoomsList = details.isNotEmpty
        ? details.map((e) => UserChatRoomsDb.fromMap(e)).toList()
        : [];
    print(userChatRoomsList);

    return userChatRoomsList;
  }
  Future<List<UserChatRoomsDb>> getChatRoom(chatRoomId) async {
    Database db = await instance.database;
    var details = await db.query('UserChatRooms',where: "chatRoomId = ?",whereArgs: [chatRoomId]);
    List<UserChatRoomsDb>  userChatRoomsList = details.isNotEmpty
        ? details.map((e) => UserChatRoomsDb.fromMap(e)).toList()
        : [];
    print(userChatRoomsList);
    return userChatRoomsList;
  }

  Future<int> add(UserChatRoomsDb details) async {
    Database db = await instance.database;
    print('data added');
    return await db.insert('UserChatRooms', details.toMap());

  }

  Future<int> update(UserChatRoomsDb details) async {
    Database db = await instance.database;
    return await db.update('UserChatRooms', details.toMap(),
        where: "chatRoomId = ?", whereArgs: [details.chatRoomId]);
  }
  Future<int> delete() async {
    Database db = await instance.database;
    return await db.delete('UserChatRooms');
  }
  Future<int> deleteChatRoom(chatRoomId) async {
    Database db = await instance.database;
    return await db.delete('UserChatRooms',where: "chatRoomId = ?",whereArgs:[chatRoomId] );
  }


}


//https://stackoverflow.com/questions/55232650/how-to-store-list-of-object-data-in-sqlite-on-flutter