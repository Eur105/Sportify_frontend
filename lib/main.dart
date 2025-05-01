// ignore_for_file: unused_import, avoid_print, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:sportify_final/pages/play_page.dart';
import 'package:sportify_final/pages/booking_page.dart';
import 'package:sportify_final/pages/chat_page.dart';
import 'package:sportify_final/pages/create_game.dart';
import 'package:sportify_final/pages/forgot_pass.dart';
import 'package:sportify_final/pages/homepage.dart';
import 'package:sportify_final/pages/learn_page.dart';
import 'package:sportify_final/pages/login_page.dart';
import 'package:sportify_final/pages/notification_page.dart';
import 'package:sportify_final/pages/signup_page.dart';
import 'package:sportify_final/pages/splash_page.dart';
import 'package:sportify_final/pages/utility/bottom_navbar.dart';
//import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sportify_final/pages/utility/notification_manager.dart';
import 'package:sportify_final/pages/utility/role_page.dart';
import 'package:sportify_final/pages/utility/socket.dart';
//import 'package:sportify_final/pages/utility/inbox_page.dart';
//import 'package: web_socket_channel/web_socket_channel.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sportify_final/pages/utility/usermanage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SocketService().initialize();
  await Firebase.initializeApp();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // 🔔 Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print(
          "Notification received in foreground: ${message.notification?.title}");

      if (message.notification != null) {
        final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
            FlutterLocalNotificationsPlugin();

        await flutterLocalNotificationsPlugin.show(
          0,
          message.notification?.title ?? 'No Title',
          message.notification?.body ?? 'No Body',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    // 🔔 When app opened via notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("📲 Notification clicked:");
      // You can add logic here to navigate to a specific screen
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(),
      home: Builder(
        builder: (context) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NotificationManager().initialize(context);
          });
          return RolePage(); // Splash/Login
        },
      ),
    );
  }
}

// Initialize local notifications
//   Future<void> _initializeNotifications(
//       FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     final InitializationSettings initializationSettings =
//         InitializationSettings(
//       android: initializationSettingsAndroid,
//     );

//     await flutterLocalNotificationsPlugin.initialize(initializationSettings);
//   }
// }
