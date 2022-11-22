import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class Chats {
  String? chatRoomId;
  String? messageId;
  String? isEdited;
  String? isRead;
  String? message;
  String? sendBy;
  int? time;
  String? type;

  Chats(
      {this.chatRoomId,
      this.messageId,
      this.isEdited,
      this.isRead,
      this.message,
      this.sendBy,
      this.time,
      this.type});

  factory Chats.fromMap(Map<String, dynamic> json) => Chats(
      chatRoomId: json['chatRoomId'],
      messageId: json['messageId'],
      isEdited: json['isEdited'],
      isRead: json['isRead'],
      message: json['message'],
      sendBy: json['sendBy'],
      time: json['time'],
      type: json['type']);

  Map<String, dynamic> toMap() {
    return {
      'chatRoomId': chatRoomId,
      'messageId': messageId,
      'isEdited': isEdited,
      'isRead': isRead,
      'message': message,
      'sendBy': sendBy,
      'time': time,
      'type': type
    };
  }
}

class DbUserChats {
  DbUserChats._privateConstructor();

  static final DbUserChats instance = DbUserChats._privateConstructor();

  static Database? _database;

  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'UserChats.db');
    print('db created');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''CREATE TABLE UserChats(
    chatRoomId STRING,
    messageId STRING,
    isEdited STRING,
    isRead STRING,
    message STRING,
    sendBy STRING,
    time INTEGER,
    type STRING
        )''');
    print('table created');
  }

  Future<List<Chats>> getDetails() async {
    Database db = await instance.database;
    var details = await db.query('UserChats');

    List<Chats> userChats =
        details.isNotEmpty ? details.map((e) => Chats.fromMap(e)).toList() : [];
    print(userChats);

    return userChats;
  }
  Future<List<Chats>> getMessagesFromChatRoom(chatRoomId) async {
    Database db = await instance.database;
    var details = await db.query('UserChats',where: "chatRoomId= ?",whereArgs:[chatRoomId]);

    List<Chats> userChats =
    details.isNotEmpty ? details.map((e) => Chats.fromMap(e)).toList() : [];
    print(userChats);

    return userChats;
  }

  Future<int> add(Chats details) async {
    Database db = await instance.database;
    print('data added');
    return await db.insert('UserChats', details.toMap());
  }

  Future<int> updateMessage(Chats details) async {
    Database db = await instance.database;
    return await db.update('UserChats', details.toMap(),
        where: "messageId = ?", whereArgs: [details.messageId]);
  }
  Future<int> deleteMessage(messageId) async {
    Database db = await instance.database;
    return await db.delete('UserChats',where: "messageId= ? ",whereArgs:[messageId] );
  }
  Future<int> deleteAllMessages() async {
    Database db = await instance.database;
    return await db.delete('UserChats');
  }

}
