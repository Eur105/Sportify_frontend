import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

//import 'package:sportify_final/pages/admin_panel/dashboard_screen.dart';
import 'package:sportify_final/pages/admin_panel/pre_board.dart';
import 'package:sportify_final/pages/utility/api_constants.dart'; // Ensure this is the correct path

class AdminLoginScreen extends StatefulWidget {
  final bool isAdminLogin; // Declare the missing parameter

  const AdminLoginScreen({super.key, required this.isAdminLogin});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false; // To show loading indicator

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    bool isAdminLogin = widget.isAdminLogin;

    var url = Uri.parse('${ApiConstants.baseUrl}/api/auth/login');
    var body = jsonEncode({
      'email': email,
      'password': password,
      'isAdminLogin': isAdminLogin,
    });

    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      var responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('admintoken', responseData['token']);
        await prefs.setString('email', emailController.text);
        // Successful login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Login Successful"), backgroundColor: Colors.green),
        );

        // Navigate to Admin Dashboard
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => AdminDashboard()),
          (route) => false,
        );
      } else {
        // Login failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(responseData['message'] ?? "Login failed"),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Forgot Password?"),
          content: const Text(
            "If you've forgotten your credentials, please contact Help & Support for assistance.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //     leading: IconButton(
      //   icon: Icon(Icons.arrow_back), // Back arrow icon
      //   onPressed: () {
      //     Navigator.pop(context); // Navigates to the previous screen
      //   },
      // )),
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Admin Login",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your email";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your password";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: const Text("Forgot Password?"),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Login",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
