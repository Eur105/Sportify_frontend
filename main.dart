// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:sportify_final/pages/Play_page.dart';
import 'package:sportify_final/pages/booking_page.dart';
import 'package:sportify_final/pages/chat_page.dart';
import 'package:sportify_final/pages/forgot_pass.dart';
import 'package:sportify_final/pages/homepage.dart';
import 'package:sportify_final/pages/learn_page.dart';
import 'package:sportify_final/pages/login_page.dart';
import 'package:sportify_final/pages/notification_page.dart';
import 'package:sportify_final/pages/singup_page.dart';
import 'package:sportify_final/pages/splash_page.dart';
import 'package:sportify_final/pages/utility/bottom_navbar.dart';

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
      themeMode: ThemeMode.light,
      theme: ThemeData(),
      home: Homepage(),
    );
  }
}
