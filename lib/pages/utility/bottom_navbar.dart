// ignore_for_file: prefer_const_constructors, unused_element

import 'package:flutter/material.dart';
import 'package:sportify_final/pages/booking_page.dart';
import 'package:sportify_final/pages/chat_page.dart';
import 'package:sportify_final/pages/homepage.dart';
import 'package:sportify_final/pages/learn_page.dart';
import 'package:sportify_final/pages/play_page.dart';

class BottomNavbar extends StatefulWidget {
  const BottomNavbar({super.key});

  @override
  State<BottomNavbar> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> {
  final Color backgroundGrey = const Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      child: SafeArea(
        // Added SafeArea to avoid overflow
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 8.0), // slight padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                icon: Icons.home,
                label: 'Home',
                context: context,
                page: const Homepage(),
              ),
              _buildBottomNavItem(
                icon: Icons.people_alt,
                label: 'Play',
                context: context,
                page: const PlayPage(),
              ),
              _buildBottomNavItem(
                icon: Icons.book_online,
                label: 'Book',
                context: context,
                page: const BookingPage(),
              ),
              _buildBottomNavItem(
                icon: Icons.chat,
                label: 'Chat',
                context: context,
                page: ChatPage(),
              ),
              _buildBottomNavItem(
                icon: Icons.school,
                label: 'Learn',
                context: context,
                page: const LearningScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required BuildContext context,
    required Widget page,
  }) {
    return Expanded(
      // Ensures equal spacing
      child: InkWell(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: 4.0), // slight padding inside each item
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 26,
                color: Colors.black,
              ), // slightly smaller icon
              SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10, // small font
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
