import 'package:conversation/Constsnts/ConstantValues.dart';
import 'package:conversation/HomeScreen.dart';
import 'package:conversation/FireBaseHelpClasses/Method.dart';
import 'package:conversation/NetWorkUtils.dart';
import 'package:conversation/UserAuthentication/SignUpScreen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

import '../FireBaseHelpClasses/FireBaseFireStoreHelperClass.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreen();
}

class _SignInScreen extends State<SignInScreen> {
  var customKeyForForm;
  final email = TextEditingController();
  final password = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SafeArea(
        child: Scaffold(
            body: isLoading
                ? const Center(
                        child:  CircularProgressIndicator(),
                  )
                : Form(
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
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    padding: const EdgeInsets.all(10),
                                    margin: const EdgeInsets.all(30),
                                    child: Column(
                                      children: [
                                        const Text("Login",
                                            style: TextStyle(
                                              fontSize: 20,
                                              color: Colors.white,
                                            )),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10, horizontal: 20),
                                            child: TextFormField(
                                                controller: email,
                                                decoration:
                                                    const InputDecoration(
                                                  fillColor: Colors.white38,
                                                  filled: true,
                                                  labelText: "Email",
                                                  labelStyle: TextStyle(
                                                      color: Colors.brown),
                                                  border: OutlineInputBorder(),
                                                ))),
                                        Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10, horizontal: 20),
                                            child: TextFormField(
                                                obscureText: true,
                                                controller: password,
                                                decoration:
                                                    const InputDecoration(
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
                                                password.text.isNotEmpty) {
                                              setState(() {
                                                isLoading = true;
                                              });
                                              login(email.text, password.text)
                                                  .then((user) {
                                                if (user != null) {
                                                  if (kDebugMode) {
                                                    print('Login Successful');
                                                  }
                                                  setState(() {
                                                    isLoading = false;
                                                  });
                                                  snackBar(context, "SignIn Success");
                                                  FireBaseFireStoreHelperClass.updateAccessToken();
                                                  Navigator.pushAndRemoveUntil(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (BuildContext
                                                              context) =>
                                                          const NetWorkUtils()
                                                    ),(route) => false,
                                                  );
                                                } else {
                                                  if (kDebugMode) {
                                                    print('Login failed');
                                                  }
                                                  setState(() {
                                                    isLoading = false;
                                                  });
                                                  snackBar(context, "SignIn failed");
                                                  if(internetConnectionStatus=="Internet Connection Lost"){
                                                    snackBar(context, "check connection");
                                                  }
                                                }
                                              });
                                            } else {
                                              if (kDebugMode) {
                                                print(
                                                    "Please enter valid details");
                                              }
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            primary: Colors.lightBlueAccent,
                                            onSurface: Colors.amber,
                                            elevation: 3,
                                          ),
                                          child: const Text('Login'),
                                        ),
                                        Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10, horizontal: 20),
                                            child: Row(mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Text(
                                                      ' Create a new account? '),

                                            GestureDetector(
                                                    onTap: () =>
                                                        Navigator.pushAndRemoveUntil(
                                                          context,
                                                          MaterialPageRoute(builder:(BuildContext
                                                              context) =>const SignUpScreen() ),
                                                              (route) => false,),
                                                    child: const Text('SignUp',
                                                        style: TextStyle(decoration:TextDecoration.underline,
                                                            color: Colors.brown)),
                                                  ),
                                              ],
                                            ))
                                      ],
                                    ),
                                  )
                                ],
                              )),
                            ],
                          ),
                        ))))));
  }
}
