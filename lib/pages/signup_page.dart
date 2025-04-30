// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sportify_final/pages/login_page.dart';
import 'package:sportify_final/pages/utility/api_constants.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isMinLengthValid = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  void _validatePasswordRealTime(String value) {
    setState(() {
      _isMinLengthValid = value.length >= 8;
      _hasNumber = RegExp(r'\d').hasMatch(value);
      _hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);
    });
  }

  String? _validateName(String? value, String fieldName) {
    if (value == null || value.isEmpty) return "$fieldName cannot be empty";
    if (value.length < 3) return "$fieldName should be at least 3 characters";
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return "Email cannot be empty";
    if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
        .hasMatch(value)) {
      return "Please enter a valid email";
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Password cannot be empty";
    if (!_isMinLengthValid) return "Password should be at least 8 characters";
    if (!_hasNumber) return "Password must contain at least one number";
    if (!_hasSpecialChar)
      return "Password must contain at least one special character";
    return null;
  }

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      final url = Uri.parse('${ApiConstants.baseUrl}:5000/api/auth/signup');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': _firstnameController.text,
          'lastName': _lastnameController.text,
          'email': _emailController.text,
          'phoneNo': _phoneController.text,
          'password': _passwordController.text,
          'confirmPassword': _confirmPasswordController.text
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Signup Successful!")),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
          (Route<dynamic> route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? "Signup Failed")),
        );
      }
    }
  }

  Widget _passwordRequirement(String text, bool isValid) {
    return Row(
      children: [
        Icon(isValid ? Icons.check_circle : Icons.cancel,
            color: isValid ? Colors.green : Colors.red, size: 16),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(color: isValid ? Colors.green : Colors.red)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Adjust breakpoint as needed

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen
                  ? 20
                  : screenWidth * 0.2), // Responsive horizontal padding
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    height: isSmallScreen ? 50 : 80), // Responsive top spacing
                Center(
                  child: Text(
                    "Create an Account",
                    style: TextStyle(
                        fontSize: isSmallScreen ? 24 : 30,
                        fontWeight: FontWeight.bold), // Responsive font size
                  ),
                ),
                SizedBox(height: isSmallScreen ? 30 : 40), // Responsive spacing
                TextFormField(
                  controller: _firstnameController,
                  decoration: const InputDecoration(
                      labelText: "First Name", border: OutlineInputBorder()),
                  validator: (value) => _validateName(value, "First Name"),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _lastnameController,
                  decoration: const InputDecoration(
                      labelText: "Last Name", border: OutlineInputBorder()),
                  validator: (value) => _validateName(value, "Last Name"),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                      labelText: "Email", border: OutlineInputBorder()),
                  validator: _validateEmail,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: "Phone Number",
                    prefixText: '+92 ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      value == null || value.isEmpty || value.length != 11
                          ? "Phone number should be exactly 11 digits"
                          : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  onChanged: _validatePasswordRealTime,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_passwordVisible
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                    ),
                  ),
                  obscureText: !_passwordVisible,
                  validator: _validatePassword,
                ),
                SizedBox(height: 10),
                _passwordRequirement(
                    "At least 8 characters", _isMinLengthValid),
                _passwordRequirement("At least 1 number", _hasNumber),
                _passwordRequirement(
                    "At least 1 special character", _hasSpecialChar),
                SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_confirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setState(() =>
                          _confirmPasswordVisible = !_confirmPasswordVisible),
                    ),
                  ),
                  obscureText: !_confirmPasswordVisible,
                  validator: (value) => value == null ||
                          value.isEmpty ||
                          value != _passwordController.text
                      ? "Passwords do not match"
                      : null,
                ),
                SizedBox(height: isSmallScreen ? 30 : 50), // Responsive spacing
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _signup,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: Text("Signup",
                        style: TextStyle(
                            fontSize: isSmallScreen ? 18 : 20,
                            color: Colors.white)), //Responsive font size
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()),
                      ),
                      child: const Text("Login"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
