import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportify_final/pages/utility/api_constants.dart';

class ViewSettings extends StatefulWidget {
  const ViewSettings({super.key});
  final Color backgroundGrey = const Color(0xFFF5F5F5);

  @override
  State<ViewSettings> createState() => _ViewSettingsState();
}

class _ViewSettingsState extends State<ViewSettings> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Adjust breakpoint as needed

    return Scaffold(
      backgroundColor: widget.backgroundGrey,
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView(
        padding:
            EdgeInsets.all(isSmallScreen ? 12.0 : 16.0), // Responsive padding
        children: [
          _buildSectionTitle("Account"),
          ListTile(
            leading: const Icon(Icons.lock, color: Colors.blue),
            title: const Text("Change Password"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ChangePasswordPage()),
              );
            },
          ),
          const Divider(),
          _buildSectionTitle("General"),
          _buildStaticText("Version", "1.0.0"),
          _buildStaticText("Privacy Policy", "Read our privacy terms"),
          _buildStaticText("Terms & Conditions", "View our terms of service"),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildStaticText(String title, String subtitle) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    );
  }
}

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});
  final Color backgroundGrey = const Color(0xFFF5F5F5);

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController currentPasswordController =
      TextEditingController();

  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool isUpdating = false;

  Future<void> _changePassword() async {
    if (newPasswordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() {
      isUpdating = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email'); // Retrieve stored email

      if (email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("User email not found. Please log in again.")),
        );
        setState(() => isUpdating = false);
        return;
      }

      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}:5000/api/auth/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": newPasswordController.text,
        }),
      );

      setState(() => isUpdating = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password changed successfully!")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to change password: ${response.body}")),
        );
      }
    } catch (e) {
      setState(() => isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: widget.backgroundGrey,
      appBar: AppBar(
        title: const Text("Reset Password"),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField(
                  "Current Password", currentPasswordController, false),
              SizedBox(height: isSmallScreen ? 10 : 16),
              _buildTextField("New Password", newPasswordController, true),
              SizedBox(height: isSmallScreen ? 10 : 16),
              _buildTextField(
                  "Confirm New Password", confirmPasswordController, true),
              SizedBox(height: isSmallScreen ? 15 : 20),
              ElevatedButton(
                onPressed: isUpdating ? null : _changePassword,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: isUpdating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Reset Password",
                        style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, bool obscureText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
