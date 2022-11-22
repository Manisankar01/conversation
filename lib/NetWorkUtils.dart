import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:conversation/HomeScreen.dart';
import 'package:conversation/UserAuthentication/Authenticate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'Constsnts/ConstantValues.dart';

class NetWorkUtils extends StatefulWidget {
  const NetWorkUtils({Key? key}) : super(key: key);

  @override
  State<NetWorkUtils> createState() => _NetWorkUtilsState();
}

class _NetWorkUtilsState extends State<NetWorkUtils>with  WidgetsBindingObserver {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    initConnectivity();
    print("Network utils class initstate");
    WidgetsBinding.instance.addObserver(this);

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

@override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      print("Network utils class resumed");
    } else if(state == AppLifecycleState.inactive){
      print("Network utils class inactive");
    }
    else if(state == AppLifecycleState.paused){
      print("Network utils class paused");
    }
    else if(state == AppLifecycleState.detached){
      print("Network utils class detached");
    }
  }
  @override
  void deactivate() {
    super.deactivate();
    print("network utils class deactivate");
  }
  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
    print("network utils class dispose");
  }

  Future<void> initConnectivity() async {
    late ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print('Couldn\'t check connectivity status, $e');
      return;
    }

    if (!mounted) {
      return Future.value(null);
    }
    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    String networkStatus = "";
    if (result.toString() == "ConnectivityResult.wifi") {
      networkStatus = "Connected to Network";
      internetConnectionStatus = networkStatus;
    } else if (result.toString() == "ConnectivityResult.none") {
      networkStatus = "Internet Connection Lost";
      internetConnectionStatus = networkStatus;
    } else if (result.toString() == "ConnectivityResult.mobile") {
      networkStatus = "Connected to Network";
      internetConnectionStatus = networkStatus;
    } else if (result.toString() == "ConnectivityResult.ethernet") {
      networkStatus = "Connected to Network";
      internetConnectionStatus = networkStatus;
    }
    snackBar(context, internetConnectionStatus);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Authenticate());
  }
}
