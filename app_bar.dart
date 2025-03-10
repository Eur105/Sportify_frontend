// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:sportify_final/pages/notification_page.dart';

class SlidingDrawerLayout extends StatefulWidget {
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Chat Inbox',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationPage()));
            },
            icon: Icon(Icons.notifications, color: Colors.black),
          ),
          IconButton(
            onPressed: toggleDrawer,
            icon: Icon(Icons.person, color: Colors.black),
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
                width: MediaQuery.of(context).size.width * 0.7,
                color: Colors.grey[100],
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 50),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: AssetImage(
                                'assets/sportify.png',
                              ), // Ensure asset path is correct
                            ),
                            SizedBox(width: 16),
                            Text(
                              'John Doe', // Replace with dynamic username
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30),
                      Divider(color: Colors.grey),
                      ListTile(
                        leading: Icon(Icons.person),
                        title: Text('Profile'),
                        onTap: () {
                          // Navigate to Profile Page
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.book),
                        title: Text('Bookings'),
                        onTap: () {
                          // Navigate to Bookings Page
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.settings),
                        title: Text('Settings'),
                        onTap: () {
                          // Navigate to Settings Page
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.article),
                        title: Text('Blogs'),
                        onTap: () {
                          // Navigate to Blogs Page
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.help),
                        title: Text('Help/Support'),
                        onTap: () {
                          // Navigate to Help/Support Page
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.logout),
                        title: Text('Logout'),
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
        ],
      ),
      bottomNavigationBar: widget.bottomNavigationBar,
      floatingActionButton: widget.floatingActionButton,
    );
  }
}
