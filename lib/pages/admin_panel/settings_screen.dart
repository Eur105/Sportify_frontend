// ignore_for_file: use_build_context_synchronously, prefer_const_constructors, unnecessary_string_interpolations

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:sportify_final/pages/admin_panel/blogs_screen.dart';
import 'package:sportify_final/pages/admin_panel/help_support_screen.dart';
//import 'package:sportify_final/pages/admin_panel/login_screen.dart';
import 'package:sportify_final/pages/admin_panel/profile_screen.dart';
import 'package:sportify_final/pages/utility/api_constants.dart';
import 'package:sportify_final/pages/utility/role_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Import login screen

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _logout(BuildContext context) async {
    final String apiUrl = "${ApiConstants.baseUrl}/api/auth/logout";

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? admintoken = prefs.getString('admintoken');

      if (admintoken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No token found. Please log in again.")),
        );
        return;
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "$admintoken",
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
        // await prefs.remove('profilePicture');
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
    String adminName = "Admin Name"; // Will be fetched from backend later

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Profile Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage(
                    'assets/profile.png',
                  ), // Placeholder
                ),
                const SizedBox(height: 10),
                Text(
                  adminName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminProfileScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "View your full profile",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Menu Options
          Expanded(
            child: ListView(
              children: [
                _buildMenuItem(Icons.person, "My Profile", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminProfileScreen(),
                    ),
                  );
                }),
                _buildMenuItem(Icons.article, "Blogs", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BlogsScreen()),
                  );
                }),
                _buildMenuItem(Icons.help_outline, "Help & Support", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HelpSupportScreen(),
                    ),
                  );
                }),
                _buildMenuItem(Icons.logout, "Log Out", () {
                  _logout(context);
                }),
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
        leading: Icon(icon, color: Colors.blue.shade800),
        title: Text(title, style: const TextStyle(fontSize: 16)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: Colors.black54,
        ),
        onTap: onTap,
      ),
    );
  }
}
