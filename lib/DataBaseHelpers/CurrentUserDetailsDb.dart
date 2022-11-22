import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';


class UserDetailsDb {
  final String? uniqueId;
  final String? fireBaseAccessToken;
  final String? name;
  final String? email;
  final String? isGroup;
  final String? profilePicture;
  final String? userChatRooms;


  UserDetailsDb({this.uniqueId,
    this.fireBaseAccessToken,
    this.name,
    this.email,
    this.isGroup,
    this.profilePicture,
  this.userChatRooms});

  factory UserDetailsDb.fromMap(Map<String, dynamic> json) =>
      UserDetailsDb(
          uniqueId: json['uniqueId'],
          fireBaseAccessToken: json['fireBaseAccessToken'],
          name: json['name'],
          email: json['email'],
          isGroup: json['isGroup'],
          profilePicture: json['profilePicture'],
        userChatRooms: json['userChatRooms']
         );

  Map<String, dynamic> toMap() {
    return {
      'uniqueId': uniqueId,
      'fireBaseAccessToken': fireBaseAccessToken,
      'name': name,
      'email': email,
      'isGroup': isGroup,
      'profilePicture': profilePicture,
      'userChatRooms':userChatRooms
    };
  }
}


class ChatRooms {
  final int? unReadMessageCount;

  ChatRooms(this.unReadMessageCount);
}

class DataBaseHelper {
  DataBaseHelper._privateConstructor();

  static final DataBaseHelper instance = DataBaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'CurrentUserDetails.db');
    print('db created');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''CREATE TABLE CurrentUserDetails(
    uniqueId STRING,
        fireBaseAccessToken STRING,
        name STRING,
        email STRING,
        isGroup STRING,
        profilePicture STRING,
        userChatRooms STRING
        )''');
    print('table created');
  }

  Future<List<UserDetailsDb>> getDetails() async {
    Database db = await instance.database;
    var details = await db.query('CurrentUserDetails');

    List<UserDetailsDb> userDetailsList = details.isNotEmpty
        ? details.map((e) => UserDetailsDb.fromMap(e)).toList()
        : [];
    print(userDetailsList);

    return userDetailsList;
  }

  Future<int> add(UserDetailsDb details) async {
    Database db = await instance.database;
    print('data added');
    return await db.insert('CurrentUserDetails', details.toMap());

  }

  Future<int> update(UserDetailsDb details) async {
    Database db = await instance.database;
    return await db.update('CurrentUserDetails', details.toMap(),
        where: "uniqueId = ?", whereArgs: [details.uniqueId]);
  }
  Future<int> delete() async {
    Database db = await instance.database;
    return await db.delete('CurrentUserDetails');
  }
}
