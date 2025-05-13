// ignore_for_file: prefer_const_constructors, unused_local_variable, avoid_print, unnecessary_brace_in_string_interps, unused_field

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sportify_final/pages/booking_page.dart';
import 'package:sportify_final/pages/chat_page.dart';

import 'package:sportify_final/pages/learn_page.dart';
import 'package:sportify_final/pages/notification_page.dart';
import 'package:sportify_final/pages/play_page.dart';
import 'package:sportify_final/pages/utility/appbar.dart';
import 'package:sportify_final/pages/utility/bottom_navbar.dart';
import 'package:sportify_final/pages/utility/locationservice.dart';
import 'package:sportify_final/pages/utility/profile.dart';
//import 'package:sportify_final/pages/utility/location_service.dart'; // Import location service
//import 'package:sportify_final/pages/utility/location_appbar_widget.dart'; // Import location widget
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sportify_final/pages/utility/usermanage.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final Color backgroundGrey = const Color(0xFFF5F5F5);
  String gameStatus = 'Start Playing'; // Default status for start playing
  String gameCalendarStatus = 'No games in your calendar';
  late final PageController _pageController;
  int _currentPage = 0;
  late List<Map<String, String>> _promoCards; // Default for calendar

  // Location related variables
  final LocationService _locationService = LocationService();
  String _fullLocationDetails = '';
  String? _locationName;
  bool _isLocationExpanded = false;
  final GlobalKey<LocationAppBarWidgetState> _locationWidgetKey = GlobalKey();

  // Function to update the game status when a game is created
  void createGame() {
    setState(() {
      gameStatus = 'Gear up for your game!'; // Change game status
      gameCalendarStatus = 'Date and Time: TBD'; // Dummy game creation info
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _promoCards = [
      {
        'image': 'assets/picture/umar_minhas_futsal_ground.jpg',
        'title': 'Turf Arena',
        'offer': '20% off on weekday slots!',
      },
      {
        'image': 'assets/picture/kokan_ground.jpg',
        'title': 'Elite Sports Club',
        'offer': 'Free drink with night booking 🍹',
      },
      {
        'image': 'assets/picture/spiritfield_ground.jpg',
        'title': 'Greenfield Ground',
        'offer': 'First booking free!',
      },
    ];

    // Start auto slide
    Timer.periodic(Duration(seconds: 4), (Timer timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % _promoCards.length;
        _pageController.animateToPage(
          _currentPage,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      }
    });
    UserManager.loadUserId();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Message received: ${message}');
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message received: ${message}');
    });
  }

  // Update location details when location widget provides them
  void _updateLocationInfo(String details, String? name) {
    setState(() {
      _fullLocationDetails = details;
      _locationName = name;
      // Show expanded location info when location is tapped
      _isLocationExpanded = true;
    });
  }

  // Toggle expanded location view
  void _toggleLocationExpand() {
    setState(() {
      _isLocationExpanded = !_isLocationExpanded;
    });
  }

  // Refresh location data
  void _refreshLocation() {
    final state = _locationWidgetKey.currentState;
    if (state != null) {
      state.refreshLocation();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Adjust breakpoint as needed

    return Scaffold(
      backgroundColor: backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Align(
          alignment: Alignment.centerLeft,
          child: LocationAppBarWidget(
            key: _locationWidgetKey,
            onLocationChanged: _updateLocationInfo,
          ),
        ),
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        titleSpacing: 0,
        leadingWidth: 0, // Remove default leading spacing
        leading: Container(), // Empty container as leading
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationPage()),
              );
            },
            icon: Icon(
              Icons.notifications,
              color: Colors.black,
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
            icon: Icon(
              Icons.person,
              color: Colors.black,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Expanded location info panel
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: _isLocationExpanded ? 70 : 0,
              color: Colors.blue[50],
              width: double.infinity,
              child: _isLocationExpanded
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 10.0),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.blue[700]),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _locationName ?? 'Unknown location',
                                  style: TextStyle(
                                    color: Colors.blue[900],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // Text(
                                //   _fullLocationDetails,
                                //   style: TextStyle(
                                //     color: Colors.blue[700],
                                //     fontSize: 12,
                                //   ),
                                // ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.refresh, size: 20),
                            onPressed: _refreshLocation,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            color: Colors.blue[700],
                          ),
                          SizedBox(width: 10),
                          IconButton(
                            icon: Icon(Icons.close, size: 20),
                            onPressed: _toggleLocationExpand,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            color: Colors.blue[700],
                          ),
                        ],
                      ),
                    )
                  : null,
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          "🔥 Featured Venues Near You",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        height: 180,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _promoCards.length,
                          itemBuilder: (context, index) {
                            final promo = _promoCards[index];
                            return _buildPromoCard(
                              image: promo['image']!,
                              title: promo['title']!,
                              offer: promo['offer']!,
                            );
                          },
                        ),
                      ),
                    ],
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
          ],
        ),
      ),
      bottomNavigationBar: BottomNavbar(),
    );
  }

  Widget _buildPromoCard(
      {required String image, required String title, required String offer}) {
    return Container(
      width: 250,
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: AssetImage(image),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.black.withOpacity(0.6), Colors.transparent],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        padding: EdgeInsets.all(12),
        alignment: Alignment.bottomLeft,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              offer,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
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
