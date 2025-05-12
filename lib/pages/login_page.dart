// ignore_for_file: use_build_context_synchronously, prefer_const_constructors, prefer_final_fields, avoid_print

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sportify_final/pages/forgot_pass.dart';
import 'package:sportify_final/pages/homepage.dart';
import 'package:sportify_final/pages/signup_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportify_final/pages/utility/api_constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isAdminLogin = false;
  final _formKey = GlobalKey<FormState>();
  bool _passwordVisible = false;
  bool _rememberMe = false;
  TextEditingController _emailcontroller = TextEditingController();
  TextEditingController _passcontroller = TextEditingController();
  bool isLoading = false;

  Future<void> moveToHome(BuildContext context) async {
    setState(() {
      isLoading = true; // Start loader
    });

    if (_formKey.currentState!.validate()) {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/auth/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailcontroller.text,
          'password': _passcontroller.text,
          'isAdminLogin': isAdminLogin
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['token'] != null) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();

        await prefs.setString('token', responseData['token']);
        await prefs.setString('email', _emailcontroller.text);

        Map<String, dynamic> user = responseData['user'];

        await prefs.setInt('userId', user['id']);
        await prefs.setString('userUuid', user['uuid']);
        await prefs.setString('firstName', user['firstName']);
        await prefs.setString('userName', user['userName']);
        await prefs.setString('lastName', user['lastName']);
        await prefs.setString('phoneNo', user['phoneNo']);
        await prefs.setString('role', user['role']);
        await prefs.setString('address', user['address'] ?? "");
        await prefs.setString('gender', user['gender'] ?? "Male");
        await prefs.setString('profilePicture', user['profilePicture'] ?? "");

        if (responseData['userbio'] != null) {
          Map<String, dynamic> userbio = responseData['userbio'];
          await prefs.setString('bioDescription', userbio['description'] ?? "");
          await prefs.setString('bioSkillLevel', userbio['skillLevel'] ?? "");
        } else {
          await prefs.setString('bioDescription', "");
          await prefs.setString('bioSkillLevel', "");
        }

        if (user['gender'] != null)
          await prefs.setString('gender', user['gender']);
        if (user['address'] != null)
          await prefs.setString('address', user['address']);
        if (user['bio'] != null) await prefs.setString('bio', user['bio']);
        if (user['profilePicture'] != null)
          await prefs.setString('profilePicture', user['profilePicture']);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful!')),
        );

        storeFcmToken(user['uuid']);

        // Stop loader before navigating
        setState(() {
          isLoading = false;
        });

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Homepage()),
          (Route<dynamic> route) => false,
        );
      } else {
        String errorMessage = "Login failed. Please try again.";
        if (response.statusCode == 400) {
          errorMessage =
              responseData['message'] ?? "Invalid email or password.";
        } else if (response.statusCode == 401) {
          errorMessage = "Invalid email or password.";
        } else if (response.statusCode == 404) {
          errorMessage = "User not found.";
        }

        // Show error and stop loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );

        setState(() {
          isLoading = false;
        });
      }
    } else {
      // Stop loader if validation fails
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> storeFcmToken(String userUUID) async {
    try {
      String? newToken = await FirebaseMessaging.instance.getToken();
      print("📲 FCM Token: $newToken");
      print("now this is uuid $userUUID");

      if (newToken != null && userUUID.isNotEmpty) {
        final response = await http.post(
          Uri.parse('${ApiConstants.baseUrl}/api/user/storefcmtoken'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'userUUID': userUUID,
            'fcmToken': newToken,
          }),
        );

        print("✅ Token store response: ${response.body}");

        // Optional: handle the response if needed
      } else {
        print("⚠️ FCM token or userUUID is null/empty.");
      }

      //Listen for future token refreshes
      FirebaseMessaging.instance.onTokenRefresh.listen((refreshedToken) async {
        print("🔁 Refreshed FCM Token: $refreshedToken");

        await http.post(
          Uri.parse('${ApiConstants.baseUrl}/api/user/storefcmtoken'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'userUUID': userUUID,
            'fcmToken': newToken,
          }),
        );
      });
    } catch (e) {
      print("❌ Error storing FCM token: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Adjust breakpoint as needed

    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
        icon: Icon(Icons.arrow_back), // Back arrow icon
        onPressed: () {
          Navigator.pop(context); // Navigates to the previous screen
        },
      )),
      body: Center(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            // Add SingleChildScrollView for scrolling on smaller screens
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                      top: isSmallScreen ? 50 : 70, // Adjust top padding
                      left: isSmallScreen ? 30 : 70, // Adjust left padding
                      right: isSmallScreen ? 30 : 70), // Adjust right padding
                  child: Text(
                    "Hi, WELCOME BACK!",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 18 : 20, // Adjust font size
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 30 : 40), // Adjust spacing

                // Email TextField
                Padding(
                  padding: EdgeInsets.only(
                      top: 16,
                      left: isSmallScreen ? 16 : 20,
                      right: isSmallScreen ? 16 : 20), // Adjust padding
                  child: TextFormField(
                    controller: _emailcontroller,
                    decoration: const InputDecoration(
                      hintText: "Enter Email",
                      labelText: "Email",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Email cannot be empty";
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 20),

                // Password TextField
                Padding(
                  padding: EdgeInsets.only(
                      left: isSmallScreen ? 16 : 20,
                      right: isSmallScreen ? 16 : 20), // Adjust padding
                  child: TextFormField(
                    controller: _passcontroller,
                    decoration: InputDecoration(
                      hintText: "Enter Password",
                      labelText: "Password",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                    ),
                    obscureText: !_passwordVisible,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Password cannot be empty";
                      } else if (value.length < 6) {
                        return "Password must be at least 6 characters long";
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 20),

                // Remember me checkbox and Forgot Password
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (bool? value) {
                          setState(() {
                            _rememberMe = value!;
                          });
                        },
                      ),
                      const Text(
                        "Remember me",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ForgotPass()),
                          );
                        },
                        child: const Text("Forgot password?"),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Login Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () => moveToHome(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "Login",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize:
                                    isSmallScreen ? 16 : 18, // Adjust font size
                              ),
                            ),
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 30 : 40), // Adjust spacing

                // Signup navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignupPage()),
                        );
                      },
                      child: const Text(
                        "Signup",
                        style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
