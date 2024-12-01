import 'package:ecg/page/my_home_page.dart';
import 'package:ecg/page/welcome.dart';
import 'package:flutter/material.dart';
import 'package:ecg/provider/decoration.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ECG Analysis',
      theme: appThemeData,
      home: const WelcomePage(),
    );
  }
}
