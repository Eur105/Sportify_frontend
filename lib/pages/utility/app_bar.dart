// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:sportify_final/pages/notification_page.dart';

class SlidingDrawerLayout extends StatefulWidget {
  final Color backgroundGrey = const Color(0xFFF5F5F5);
  final Widget body; // Main body of the page
  final Widget? bottomNavigationBar; // Optional Bottom Navigation Bar
  final Widget? floatingActionButton; // Optional Floating Action Button

  const SlidingDrawerLayout({
    Key? key,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
  }) : super(key: key);

  @override
  _SlidingDrawerLayoutState createState() => _SlidingDrawerLayoutState();
}

class _SlidingDrawerLayoutState extends State<SlidingDrawerLayout>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(1, 0), // Off-screen to the right
      end: Offset(0, 0), // On-screen
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void toggleDrawer() {
    if (_animationController.isCompleted) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Adjust breakpoint as needed

    return Scaffold(
      backgroundColor: widget.backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Chat Inbox',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NotificationPage()),
              );
            },
            icon: const Icon(Icons.notifications, color: Colors.black),
          ),
          IconButton(
            onPressed: toggleDrawer,
            icon: const Icon(Icons.person, color: Colors.black),
          ),
        ],
      ),
      body: Stack(
        children: [
// Main Content
          widget.body,

          // Sliding Drawer
          SlideTransition(
            position: _slideAnimation,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: screenWidth *
                    (isSmallScreen ? 0.8 : 0.7), // Responsive width
                color: Colors.grey[100],
                child: SingleChildScrollView(
                  child: Padding(
                    // Added Padding
                    padding:
                        EdgeInsets.symmetric(vertical: isSmallScreen ? 20 : 50),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: isSmallScreen
                                    ? 25
                                    : 30, // Responsive radius
                                backgroundImage: const AssetImage(
                                  'assets/sportify.png',
                                ), // Ensure asset path is correct
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'John Doe', // Replace with dynamic username
                                style: TextStyle(
                                  fontSize: isSmallScreen
                                      ? 16
                                      : 18, // Responsive font
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                            height:
                                isSmallScreen ? 20 : 30), // Responsive spacing
                        const Divider(color: Colors.grey),
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('Profile'),
                          onTap: () {
                            // Navigate to Profile Page
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.book),
                          title: const Text('Bookings'),
                          onTap: () {
                            // Navigate to Bookings Page
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.settings),
                          title: const Text('Settings'),
                          onTap: () {
                            // Navigate to Settings Page
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.article),
                          title: const Text('Blogs'),
                          onTap: () {
                            // Navigate to Blogs Page
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.help),
                          title: const Text('Help/Support'),
                          onTap: () {
                            // Navigate to Help/Support Page
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.logout),
                          title: const Text('Logout'),
                          onTap: () {
                            // Logout functionality
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.bottomNavigationBar,
      floatingActionButton: widget.floatingActionButton,
    );
  }
}
