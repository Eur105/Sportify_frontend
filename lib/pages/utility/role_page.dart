import 'package:flutter/material.dart';
import 'package:sportify_final/pages/admin_panel/login_screen.dart';
//import 'package:sportify_final/pages/admin_panel/dashboard_screen.dart';
//import 'package:sportify_final/pages/admin_panel/pre_board.dart';
import 'package:sportify_final/pages/login_page.dart';

class RolePage extends StatelessWidget {
  final bool isAdminLogin = false;
  const RolePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Adjust breakpoint as needed

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        // Added SingleChildScrollView
        child: Padding(
          // Added padding to the main Column
          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 50.0 : 100.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to Sportify',
                style: TextStyle(
                  fontSize: isSmallScreen ? 24 : 28, // Responsive font size
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center, // Added text alignment
              ),
              SizedBox(height: isSmallScreen ? 40 : 50), // Responsive spacing
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    minimumSize: Size(double.infinity,
                        isSmallScreen ? 50 : 60), // Responsive button height
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              AdminLoginScreen(isAdminLogin: true)),
                      (route) => false,
                    );
                  },
                  child: Text(
                    'Log in as Admin',
                    style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 20,
                        color: Colors.white), // Responsive font size
                  ),
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    minimumSize: Size(double.infinity,
                        isSmallScreen ? 50 : 60), // Responsive button height
                  ),
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => LoginPage()));
                  },
                  child: Text(
                    'Log in as Player',
                    style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 20,
                        color: Colors.white), // Responsive font size
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
