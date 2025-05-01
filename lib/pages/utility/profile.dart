// ignore_for_file: use_build_context_synchronously, avoid_print, prefer_const_constructors, unnecessary_string_interpolations, prefer_const_declarations

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
//import 'package:sportify_final/pages/utility/edit_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportify_final/pages/admin_panel/blogs_screen.dart';
import 'package:sportify_final/pages/utility/api_constants.dart';
import 'package:sportify_final/pages/utility/role_page.dart';
import 'package:sportify_final/pages/utility/view_all_booking.dart';
import 'package:sportify_final/pages/utility/view_all_games.dart';
import 'dart:io';

import 'package:sportify_final/pages/utility/view_profile.dart';
import 'package:sportify_final/pages/utility/view_settings.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final Color backgroundGrey = const Color(0xFFF5F5F5);
  String fullName = "";
  String? profilePicturePath;
  String username = "";
  String? userUuid;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String firstName = prefs.getString('firstName') ?? '';
    final String lastName = prefs.getString('lastName') ?? '';
    username = prefs.getString('userName') ?? "";

    setState(() {
      fullName = "${firstName.toUpperCase()} ${lastName.toUpperCase()}".trim();

      profilePicturePath =
          prefs.getString('profilePicture'); // Load profile picture
      userUuid = prefs.getString('userUuid');
    });
  }

  Future<void> _logout() async {
    final String apiUrl = "${ApiConstants.baseUrl}:5000/api/auth/logout";

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No token found. Please log in again.")),
        );
        return;
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "$token",
        },
      );

      if (response.statusCode == 200) {
        // await prefs.clear();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RolePage()),
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('userUuid');
        await prefs.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Logout failed: ${response.body}")),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred. Please try again.")),
      );
      print("Logout Error: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Adjust breakpoint as needed

    return Scaffold(
      backgroundColor: backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Centered Profile Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundGrey,
              boxShadow: [
                BoxShadow(
                  color: backgroundGrey,
                  blurRadius: 4,
                  spreadRadius: 1,
                )
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: isSmallScreen ? 35 : 40, // Responsive avatar size
                  backgroundImage: profilePicturePath != null &&
                          profilePicturePath!.isNotEmpty
                      ? FileImage(File(profilePicturePath!))
                      : const AssetImage('assets/profile.png') as ImageProvider,
                ),
                SizedBox(height: isSmallScreen ? 8 : 10), // Responsive spacing
                Text(
                  username.isNotEmpty ? username : "User",
                  style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 20,
                      fontWeight: FontWeight.bold), // Responsive font size
                ),
              ],
            ),
          ),

          SizedBox(height: isSmallScreen ? 15 : 20), // Responsive spacing

          // Menu Options
          Expanded(
            child: ListView(
              children: [
                _buildMenuItem(Icons.person, "My Profile", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ViewProfile(viewedUserId: userUuid ?? "")),
                  );
                }),
                _buildMenuItem(Icons.view_list, "My Games", () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => ViewUserGames()));
                }),
                _buildMenuItem(Icons.receipt_long, "My Bookings", () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ViewAllBooking()));
                }),
                _buildMenuItem(Icons.article, "Blogs", () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => BlogsScreen()));
                }),
                _buildMenuItem(Icons.settings, "Settings", () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => ViewSettings()));
                }),
                _buildMenuItem(Icons.logout, "Log Out", _logout),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: Colors.green.shade800),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16),
        ),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 18, color: Colors.black54),
        onTap: onTap,
      ),
    );
  }
}
