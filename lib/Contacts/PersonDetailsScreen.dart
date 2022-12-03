import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vcard_maintained/vcard_maintained.dart';

class PersonDetails extends StatefulWidget {
  const PersonDetails({
    Key? key,
    this.contactId,
  }) : super(key: key);

  final String? contactId;

  @override
  State<PersonDetails> createState() => _PersonDetails();
}

class _PersonDetails extends State<PersonDetails> with WidgetsBindingObserver {
  final numberList = [];
  String? mobileNumber;
  Contact? contactDetails;
  bool loading = true;
  String? contactId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (contactId != null) {
      getContactDetails();
    }
  }

  getContactDetails() async {
    contactDetails = await FlutterContacts.getContact(contactId ?? '');
    setState(() {
      contactDetails;
    });
  }

  void navigateBack() {
    Future.delayed(Duration.zero, () {
      Navigator.pop(context);
    });
  }

  void shareExternal() {
    var name = contactDetails!.displayName;
    var number = '';
    var mobilNumber = contactDetails!.phones.first.number;
    if (numberList.isNotEmpty) {
      for (String i in numberList) {
        number = '$number $i\n';
      }
    } else if (mobilNumber.isNotEmpty) {
      number = mobilNumber.toString();
    }
    var details = 'Name:$name \n$number';
    Share.share(details);
  }

  void generateVcf() async {
    ///Create a new vCard
    var vCard = VCard();

    ///Set properties
    vCard.firstName = 'FirstName';
    vCard.middleName = 'MiddleName';
    vCard.lastName = 'LastName';
    vCard.organization = 'ActivSpaces Labs';

    vCard.photo.attachFromUrl('/path/to/image/file.png', 'PNG');
    vCard.workPhone = 'Work Phone Number';
    vCard.birthday = DateTime.now();
    vCard.jobTitle = 'Software Developer';
    vCard.url = 'https://github.com/valerycolong';
    vCard.note = 'Notes on contact';

    /// Save to file
    // vCard.saveToFile('');

    /// Get as formatted string
    // FlutterShare.shareFile(filePath: filePath,title:'file');
  }



  Future<String> getFilePath(String fileName) async {
    Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
    String appDocumentsPath = appDocumentsDirectory.path;
    String filePath = '$appDocumentsPath/$fileName.vcf';
    print('filePath:$filePath');
    return filePath;
  }
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/counter.txt');
  }
  Future<int> readCounter() async {
    try {
      final file = await _localFile;
      // Read the file
      final contents = await file.readAsString();
      return int.parse(contents);
    } catch (e) {
      // If encountering an error, return 0
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    contactId = widget.contactId;
    if (contactId != null) {
      getContactDetails();
    }
    var contactName = contactDetails?.displayName ?? "";
    var phoneNumbersLength = contactDetails?.phones.length;
    Uint8List? photo;
    if (contactDetails?.photoOrThumbnail?.isNotEmpty != null) {
      photo = contactDetails?.photoOrThumbnail;
    }
    if (phoneNumbersLength != 0 && contactDetails?.phones.isNotEmpty != null) {
      if (phoneNumbersLength! > 1) {
        numberList.clear();
        for (var i = 0; i <= phoneNumbersLength - 1; i++) {
          numberList.add(contactDetails?.phones[i].number);
        }
      } else {
        mobileNumber = contactDetails?.phones.first.number ?? "";
      }
    }
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(actions: [
        PopupMenuButton(
            onSelected: (value) async {
              if (value == 0) {
                await FlutterContacts.openExternalEdit(contactDetails!.id);
              } else if (value == 1) {
                await FlutterContacts.deleteContact(contactDetails!);
                navigateBack();
              } else {
                readCounter();
              }
            },
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) {
              return const [
                PopupMenuItem(value: 0, child: Text('Edit')),
                PopupMenuItem(value: 1, child: Text('Delete')),
                PopupMenuItem(value: 2, child: Text('Share'))
              ];
            })
      ]),
      body: SingleChildScrollView(
          child: Column(children: [
        Padding(
            padding: const EdgeInsetsDirectional.only(start: 1, end: 1),
            child: Container(
                height: size.height * 0.3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.purple.shade50,
                    Colors.white,
                    Colors.lightBlue.shade100,
                    Colors.lightBlue.shade100
                  ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  color: Colors.orangeAccent,
                  borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(10),
                      bottomLeft: Radius.circular(10)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 7,
                      blurRadius: 9,
                      offset: const Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                width: size.width,
                child:
                    Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Center(
                    child: photo != null
                        ? CircleAvatar(
                            radius: 80,
                            backgroundImage: MemoryImage(photo),
                          )
                        : const CircleAvatar(
                            radius: 80,
                            child: Icon(Icons.person, size: 80),
                          ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    contactName,
                    style: const TextStyle(
                      fontSize: 20,
                      shadows: <Shadow>[
                        Shadow(
                          offset: Offset(0, 1.0),
                          blurRadius: 1.0,
                          color: Color.fromARGB(25, 0, 0, 0),
                        ),
                        Shadow(
                          offset: Offset(0, 1.0),
                          blurRadius: 2.0,
                          color: Color.fromARGB(125, 34, 0, 255),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  )
                ]))),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 2, end: 2, top: 20),
          child: Container(
              height: size.height * 0.1,
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 7,
                    blurRadius: 9,
                    offset: const Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                      child: IconButton(
                    icon: const Icon(Icons.call_outlined),
                    onPressed: () {
                      if (numberList.isNotEmpty) {
                        _showAlert('call', size);
                      }
                      if (mobileNumber != null) {
                        callFunctionality();
                      }
                    },
                  )),
                  Expanded(
                      child: IconButton(
                    icon: const Icon(Icons.message_outlined),
                    onPressed: () {
                      if (numberList.isNotEmpty) {
                        _showAlert('message', size);
                      }
                      if (mobileNumber != null) {
                        messageFunctionality();
                      }
                    },
                  ))
                ],
              )),
        ),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Column(
              children: [
                ListView.builder(
                    itemCount: phoneNumbersLength ?? 0,
                    shrinkWrap: true,
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                          decoration: BoxDecoration(
                              boxShadow: const [
                                BoxShadow(
                                    offset: Offset(1, 3), color: Colors.black12)
                              ],
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2)),
                          child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 2, vertical: 8),
                              child: ListTile(
                                leading: const Icon(Icons.call),
                                title: Text(
                                    contactDetails?.phones[index].number ?? ''),
                              )));
                    })
              ],
            )),
      ])),
    );
  }

  void _showAlert(actionType, Size size) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Choose number to $actionType'),
            content: SizedBox(
              height: size.height * 0.15,
              width: size.width / 0.2,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: numberList.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    onTap: () {
                      mobileNumber = numberList[index];
                      if (actionType == 'call') {
                        callFunctionality();
                        Navigator.pop(context);
                      } else {
                        messageFunctionality();
                        Navigator.pop(context);
                      }
                    },
                    title: Text(numberList[index]),
                  );
                },
              ),
            ),
          );
        });
  }

  void callFunctionality() {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: '$mobileNumber',
    );
    launchUrl(launchUri);
  }

  void messageFunctionality() {
    final Uri smsLaunchUri = Uri(
      scheme: 'sms',
      path: '$mobileNumber',
    );
    launchUrl(smsLaunchUri);
  }
}
