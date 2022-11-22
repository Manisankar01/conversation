import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const String fireBaseCloudServerToken = 'AAAAFC82T0I:APA91bHDrZmEj7UvokTiF1rRxiOuyuDNvpwnBi3rjkdLR-PfQQTiq5YrOHd0fNeaiEHvpKn73v9KsELIQx_x7rsu62qmNMFMYHC-CkohST-qrI-qo_v28l1ah7BS9SBCsEvwM-mwZWPM';
var internetConnectionStatus = "";

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> snackBar(context,message){
  return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
  ));
}
