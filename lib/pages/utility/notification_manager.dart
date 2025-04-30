// ignore_for_file: prefer_const_constructors, unnecessary_null_comparison, avoid_print

import 'package:flutter/material.dart';
import 'package:sportify_final/pages/utility/socket.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final SocketService _socketService = SocketService();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Listen to the notification stream
    _socketService.notificationStream.addListener(() {
      if (_socketService.notificationStream.value != null) {
        _handleNotification(context, _socketService.notificationStream.value!);
      }
    });

    _isInitialized = true;
  }

  Future<void> _initializeLocalNotifications() async {
    var initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }

  Future<void> _showLocalNotification(String title, String body) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'sportify_notifications',
      'Sportify Notifications',
      channelDescription: 'Notifications for Sportify app',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    var iOSPlatformChannelSpecifics = DarwinNotificationDetails();

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0, // ID - use a unique ID for each notification
      title,
      body,
      platformChannelSpecifics,
    );
  }

  void _handleNotification(
      BuildContext context, Map<String, dynamic> notification) {
    try {
      if (notification["type"] == "requestStatusUpdate") {
        var data = notification["data"];

        // Format a user-friendly message
        String message = data["status"] == "approved"
            ? "Your request to join the game was approved!"
            : "Your request to join the game was rejected.";

        // Add game details if available
        if (data["gameTitle"] != null) {
          message += " (${data["gameTitle"]})";
        }

        // Show in-app notification
        _showSnackBar(context, message,
            data["status"] == "approved" ? Colors.green : Colors.red);

        // Also show a system notification
        _showLocalNotification("Game Request Update", message);
      }
      // Other notification types...
    } catch (e) {
      print("Error handling notification: $e");
    }
  }

  void _showSnackBar(
      BuildContext context, String message, Color backgroundColor) {
    try {
      // Make sure we have a valid context
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to notification page
                Navigator.pushNamed(context, '/notifications');
              },
            ),
          ),
        );
      }
    } catch (e) {
      print("Error showing SnackBar: $e");
    }
  }
}
