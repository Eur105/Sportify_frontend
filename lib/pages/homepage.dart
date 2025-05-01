// ignore_for_file: prefer_const_constructors, unused_local_variable, deprecated_member_use, annotate_overrides, avoid_print, sized_box_for_whitespace

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:sportify_final/pages/booking_page.dart';
import 'package:sportify_final/pages/chat_page.dart';
import 'package:sportify_final/pages/create_game.dart';
import 'package:sportify_final/pages/learn_page.dart';
import 'package:sportify_final/pages/notification_page.dart';
import 'package:sportify_final/pages/play_page.dart';
import 'package:sportify_final/pages/utility/bottom_navbar.dart';
import 'package:sportify_final/pages/utility/profile.dart';
import 'package:sportify_final/pages/utility/usermanage.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final Color backgroundGrey = const Color(0xFFF5F5F5);
  String gameStatus = 'Start Playing'; // Default status for start playing
  String gameCalendarStatus =
      'No games in your calendar'; // Default for calendar

  // Function to update the game status when a game is created
  void createGame() {
    setState(() {
      gameStatus = 'Gear up for your game!'; // Change game status
      gameCalendarStatus = 'Date and Time: TBD'; // Dummy game creation info
    });
  }

  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(message);
    });
    UserManager.loadUserId();
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Adjust breakpoint as needed

    return Scaffold(
      backgroundColor: backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationPage()),
              );
            },
            icon: Icon(Icons.notifications),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
            icon: Icon(Icons.person),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          // Added padding to the overall body
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            gameStatus,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Create Game",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const CreateGame()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                            child: Text(
                              "Create",
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        gameCalendarStatus,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 20),
                      Divider(thickness: 1),
                      InkWell(
                        onTap: () {},
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          child: Text(
                            "View My Calendar",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildResponsiveContainer(
                          context,
                          'Play',
                          'Find players and join games',
                          'assets/picture/player.jpg',
                          const PlayPage()),
                      _buildResponsiveContainer(
                          context,
                          'Book',
                          'Book your slots in venues nearby',
                          'assets/picture/ground.jpg',
                          const BookingPage()),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildResponsiveContainer(
                      context,
                      'Groups',
                      'Connect, compete and discuss',
                      'assets/picture/group.jpg',
                      ChatPage(),
                      isFullWidth: true),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildResponsiveContainer(
                          context,
                          'Learn',
                          'Tips & tricks',
                          'assets/picture/learn.jpg',
                          const LearningScreen()),
                      _buildResponsiveContainer(
                          context,
                          'Friends',
                          'Find your friends',
                          'assets/picture/friend.jpg',
                          ChatPage()),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavbar(),
    );
  }

  Widget _buildResponsiveContainer(BuildContext context, String title,
      String subtitle, String imagePath, Widget nextPage,
      {bool isFullWidth = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = isFullWidth ? screenWidth * 0.8 : screenWidth * 0.4;
    return InkWell(
      onTap: () {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => nextPage));
      },
      child: Container(
        width: containerWidth,
        height: 200,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(12),
                color: Colors.black.withOpacity(0.6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
