import 'package:conversation/FireBaseHelpClasses/FireBaseFireStoreHelperClass.dart';
import 'package:conversation/FireBaseHelpClasses/Method.dart';
import 'package:conversation/HomeScreen.dart';
import 'package:conversation/UserAuthentication/SignInScreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:page_transition/page_transition.dart';

import '../Constsnts/ConstantValues.dart';
import '../NetWorkUtils.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreen();
}

class _SignUpScreen extends State<SignUpScreen> {
  final customKeyForForm = GlobalKey<FormState>();
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool isLoading = false;


  bool validateEmail(email) {
    bool emailValid = RegExp(r'^.+@[a-zA-Z]+\.{1}[a-zA-Z]+(\.{0,1}[a-zA-Z]+)$')
        .hasMatch(email);
    return emailValid;
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return SafeArea(
        child: Scaffold(
      body: isLoading
          ?const Center(
                child:  CircularProgressIndicator(),

            )
          : Form(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              key: customKeyForForm,
              child: Align(
                  alignment: Alignment.center,
                  child: SingleChildScrollView(
                    child: Container(
                      decoration: const BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage('images/background.jpg'),
                              fit: BoxFit.cover)),
                      height: MediaQuery.of(context).size.height,
                      width: double.maxFinite,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                Container(
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.orangeAccent,
                                      ),
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(20)),
                                  padding: EdgeInsets.all(10),
                                  margin: EdgeInsets.all(30),
                                  child: Column(children: [
                                    const Text("SignUp",
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                        )),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 20),
                                        child: TextFormField(textCapitalization: TextCapitalization.sentences,
                                            controller: firstName,
                                            decoration: const InputDecoration(
                                              fillColor: Colors.white38,
                                              filled: true,
                                              labelText: "FirstName",
                                              labelStyle: TextStyle(
                                                  color: Colors.brown),
                                              border: OutlineInputBorder(),
                                            ))),
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 20),
                                        child: TextFormField(textCapitalization: TextCapitalization.sentences,
                                            controller: lastName,
                                            decoration: const InputDecoration(
                                              fillColor: Colors.white38,
                                              filled: true,
                                              labelText: "LastName",
                                              labelStyle: TextStyle(
                                                  color: Colors.brown),
                                              border: OutlineInputBorder(),
                                            ))),
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 20),
                                        child: TextFormField(
                                            validator: (enteredEmail) =>
                                                validateEmail(enteredEmail)
                                                    ? null
                                                    : "Invalid",
                                            controller: email,
                                            decoration: const InputDecoration(
                                              fillColor: Colors.white38,
                                              filled: true,
                                              labelText: "Email",
                                              labelStyle:
                                                  TextStyle(color: Colors.grey),
                                              border: OutlineInputBorder(),
                                            ))),
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 20),
                                        child: TextFormField(
                                            obscureText: true,
                                            validator: (value) {
                                              return value!.length > 8
                                                  ? null
                                                  : "Must be 8 character";
                                            },
                                            controller: password,
                                            decoration: const InputDecoration(
                                              fillColor: Colors.white38,
                                              filled: true,
                                              labelText: "Password",
                                              labelStyle: TextStyle(
                                                  color: Colors.brown),
                                              border: OutlineInputBorder(),
                                            ))),
                                    ElevatedButton(
                                      onPressed: () {
                                        if (email.text.isNotEmpty &&
                                            password.text.isNotEmpty &&
                                            firstName.text.isNotEmpty &&
                                            lastName.text.isNotEmpty) {
                                          setState(() {
                                            isLoading = true;
                                          });
                                          createAccount(
                                                  firstName.text,
                                                  lastName.text,
                                                  email.text,
                                                  password.text)
                                              .then((user) {
                                            if (user != null) {
                                              setState(() {
                                                isLoading = false;
                                              });
                                              snackBar(context, "Account created successfully");
                                              FireBaseFireStoreHelperClass.updateAccessToken();
                                              Navigator.pushAndRemoveUntil(
                                                context,
                                                MaterialPageRoute(maintainState: true,
                                                  builder:
                                                      (BuildContext context) =>
                                                           const NetWorkUtils(),
                                                ),(route) => false,);
                                            } else {
                                              print('Account creation failed');
                                              setState(() {
                                                isLoading = false;
                                              });
                                              snackBar(context, "Account creation failed");
                                              if(internetConnectionStatus=="Internet Connection Lost"){
                                                snackBar(context, "check connection");
                                              }
                                            }
                                          });
                                        } else {
                                          print("Please Enter Fields");
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        primary: Colors.lightBlueAccent,
                                        onSurface: Colors.amber,
                                        elevation: 3,
                                      ),
                                      child: const Text('Sign Up'),
                                    ),
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 20),
                                        child: Row(mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                                'If already have an account?  '),

                                            GestureDetector(
                                              onTap: () =>
                                                  Navigator.pushAndRemoveUntil(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (BuildContext context) =>
                                                      const SignInScreen(),
                                                    ),(route) => false,),
                                              child: const Text('Login',
                                                  style: TextStyle(decoration:TextDecoration.underline,
                                                      color: Colors.brown)),
                                            ),
                                          ],
                                        ))
                                  ]),
                                ),
                              ])),
                        ],
                      ),
                    ),
                  )),
            ),
    ));
  }
}
