import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Common {
  static String dateFormat = 'yyMMddHHmmss';
  static  String masterServerPort = 'http://140.118.155.65:9000/demo/fs';
  //static  String masterServerPort = 'http://192.168.0.15:9000/demo/fs';
  static Duration timerDuration = const Duration(seconds: 5);

  static String? uuid;
  static String? platform;
  static String? systemName;
  static EdgeInsets pagePadding = const EdgeInsets.only(left:10, right:10);
  static EdgeInsets menuItemPadding = const EdgeInsets.only(left: 0);

  static int timestampNow() => DateTime.now().millisecondsSinceEpoch;

  static Future getDeviceInfo() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    try {
      if(Platform.isAndroid){
        var deviceInfo = await deviceInfoPlugin.androidInfo;
        uuid = deviceInfo.id;
        platform = deviceInfo.model;
        systemName = 'Android${deviceInfo.version.release}';
      } else if (Platform.isIOS) {
        var deviceInfo = await deviceInfoPlugin.iosInfo;
        uuid = deviceInfo.identifierForVendor;
        platform = deviceInfo.utsname.machine;
        systemName = '${deviceInfo.systemName}${deviceInfo.systemVersion}';
      }
    } on PlatformException {
      uuid = 'NA';
      platform = 'NA';
      systemName = 'NA';
    }
  }

  static String dateTimeToString(DateTime dateTime, String format) {
    if(format.isEmpty) {
      return DateFormat(dateFormat).format(dateTime);
    } else {
      return DateFormat(format).format(dateTime);
    }
  }

  static String timestampToString(int timestampInSecond) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestampInSecond*1000);
    return DateFormat(dateFormat).format(date);
  }

  static String timestampToStringWithFormat(int timestampInSecond, String format) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestampInSecond*1000);

    return DateFormat(format).format(date);
  }

  static String differentTimestampToString(int t1, int t2) {
    DateTime dt1 = DateTime.fromMillisecondsSinceEpoch(t1*1000);
    DateTime dt2 = DateTime.fromMillisecondsSinceEpoch(t2*1000);
    Duration duration = dt1.difference(dt2);
    String s = '';
    if(duration.inDays>0) s = '$s${duration.inDays.toString()} days';
    if(duration.inHours>0) s = '$s ${(duration.inHours % 24).toString()} hours';
    if(duration.inMinutes>0) s = '$s ${(duration.inMinutes % 60).toString()} minutes';
    if(duration.inSeconds>0) s = '$s ${(duration.inSeconds % 60).toString().padLeft(2, '0')} seconds';

    return s;
  }

  static String timeLeftStringFromNow(int timeEnd) {
    DateTime dt1 = DateTime.fromMillisecondsSinceEpoch(timeEnd*1000);
    DateTime dt2 = DateTime.now();
    Duration duration = dt1.difference(dt2);
    String s = '';
    if(duration.inDays>0) s = '$s| ${duration.inDays.toString()}d |';
    if(duration.inHours>0) s = '$s ${(duration.inHours % 24).toString()}h |';
    if(duration.inMinutes>0) s = '$s ${(duration.inMinutes % 60).toString()}m |';
    if(duration.inSeconds>0) s = '$s ${(duration.inSeconds % 60).toString().padLeft(2, '0')}s |';

    return s;
  }

  static String timeNowString() {
    return DateFormat(dateFormat).format(DateTime.now());
  }

  static void showAlertDialog(BuildContext context, String title, String message, Duration duration, [color=Colors.black]) {
    Timer? timer;

    showDialog(
      context: context,
      builder: (BuildContext buildContext) {
        if(!duration.isNegative) {
          timer = Timer(duration, () {
            Navigator.of(buildContext).pop();
          });
        }

        return AlertDialog(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          content: Text(message, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 20,),),
        );
      }).then((value) {
        if(timer!=null && timer!.isActive) {
          timer!.cancel();
        }
      }
    );
  }


  static listDoubleToString(List<double> list, String delimiter, int precision) {
    String s = '';
    var n = list.length;
    for(int i = 0; i<n-1; ++i) {
      s = '$s${list[i].toStringAsPrecision(precision)}$delimiter';
    }
    s = '$s${list.last.toStringAsPrecision(precision)}';
    return s;
  }
}
