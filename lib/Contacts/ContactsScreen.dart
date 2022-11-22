import 'dart:typed_data';

import 'package:conversation/Contacts/PersonDetailsScreen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  State<ContactsScreen> createState() => _ContactsScreen();
}

class _ContactsScreen extends State<ContactsScreen>
    with WidgetsBindingObserver {
  List<Contact>? contacts;
  late List<Contact>? filteredContacts;
  final searchController = TextEditingController();
  bool isContactPermissionGranted = false;
  bool loading = true;
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    checkPermission();
    WidgetsBinding.instance.addObserver(this);
    searchController.addListener(() {
      contactsFilter();
    });
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  void checkPermission() async {
    await Permission.contacts.isGranted
        ? fetchContacts()
        : askContactsPermission();
  }

  void askContactsPermission() async {
    if (await Permission.contacts.request().isGranted) {
      setState(() {
        isContactPermissionGranted = true;
        fetchContacts();
      });
    } else {
      setState(() {
        isContactPermissionGranted = false;
        loading = false;
      });
    }
  }

  void fetchContacts() async {
    contacts = await FlutterContacts.getContacts(
        withProperties: true, withPhoto: true);
    setState(() {
      isContactPermissionGranted = true;
      loading = false;
      contacts;
    });
    searchController.addListener(() {
      contactsFilter();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      checkPermission();
    }
  }

  contactsFilter() {
    List<Contact> searchRelatedContacts = [];
    searchRelatedContacts.addAll(contacts!);
    if (searchController.text.toString().isNotEmpty) {
      searchRelatedContacts.retainWhere((contact) {
        String searchTerm = searchController.text.toLowerCase();
        String contactName = contact.displayName.toLowerCase();
        return contactName.contains(searchTerm);
      });
      setState(() {
        filteredContacts = searchRelatedContacts;
      });
    }
  }

  String flatterPhoneNumber(String value) {
    return value.replaceAll(RegExp(r'^(\+)|D'), '');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    bool isSearching = searchController.text.isNotEmpty;
    return isContactPermissionGranted
        ? Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                await FlutterContacts.openExternalInsert();
              },
              child: const Icon(Icons.add),
            ),
            body: contacts == null
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Column(children: [
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 15),
                        child: Material(
                          child: TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                              suffixIcon: const Icon(Icons.search),
                              hintText: 'Search for contacts',
                              border: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.white24,
                                  ),
                                  borderRadius: BorderRadius.circular(10)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Colors.black38,
                                  )),
                            ),
                          ),
                        )),
                    Expanded(
                        child: ListView.builder(controller: scrollController,
                            itemCount: isSearching
                                ? filteredContacts!.length
                                : contacts!.length,
                            itemBuilder: (BuildContext context, int index) {
                              Contact contactDetails = isSearching
                                  ? filteredContacts![index]
                                  : contacts![index];
                              Uint8List? image = contactDetails.photo;
                              var length = (contactDetails.phones.isNotEmpty)
                                  ? (contactDetails.phones.length)
                                  : 0;
                              return ListTile(
                                focusColor: Colors.white54,
                                leading: (contactDetails.photo == null)
                                    ? const CircleAvatar(
                                        child: Icon(Icons.person))
                                    : CircleAvatar(
                                        backgroundImage: MemoryImage(image!)),
                                title: Text(
                                    "${contactDetails.name.first} ${contactDetails.name.last}"),
                                subtitle: length > 0
                                    ? Text(contactDetails.phones.first.number)
                                    : const Text(''),
                                onTap: () {
                                  Navigator.of(context)
                                      .push(PageTransition(
                                          child: PersonDetails(contactId: contactDetails.id),
                                          type: PageTransitionType.rightToLeft))
                                      .then((value) => {});
                                },
                              );
                            }))
                  ]),
          )
        : Scaffold(
                body: Center(
                    child: loading?const CircularProgressIndicator():Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: size.height * 0.5,
                    width: size.width * 0.5,
                    child: const Image(
                      image: AssetImage('images/shield-lock.png'),
                    ),
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          primary: Colors.indigoAccent.shade100,
                          shadowColor: Colors.grey,
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20))),
                      child: const Text('Open settings'),
                      onPressed: () async {
                        openAppSettings();
                      }),
                  const SizedBox(height: 20),
                  const Text(
                    'This App Need contacts permission',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ],
              )));
  }
}
