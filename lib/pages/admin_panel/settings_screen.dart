import 'package:flutter/material.dart';
import 'package:sportify_final/pages/admin_panel/blogs_screen.dart';
import 'package:sportify_final/pages/admin_panel/help_support_screen.dart';
//import 'package:sportify_final/pages/admin_panel/login_screen.dart';
import 'package:sportify_final/pages/admin_panel/profile_screen.dart';
import 'package:sportify_final/pages/utility/role_page.dart';
// Import login screen

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
                  _showLogoutDialog(context);
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                // Close the dialog
                Navigator.pop(context);

                // Navigate back to Login Screen and remove all previous screens
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RolePage(),
                  ),
                  (Route<dynamic> route) =>
                      false, // Remove all previous screens
                );
              },
              child: const Text("Log Out", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
