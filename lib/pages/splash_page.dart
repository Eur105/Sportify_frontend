// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportify_final/pages/utility/role_page.dart'; // Replace with your login page
import 'package:sportify_final/pages/homepage.dart'; // Import your homepage

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  bool showDot = false; // To control the appearance of the full stop

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _animationController = AnimationController(
      duration: const Duration(seconds: 2), // Faster animation speed
      vsync: this,
    );

    // Define a scaling animation
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Define a slide animation
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Start the animation
    _animationController.forward();

    // Delay the appearance of the full stop by 1 second
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        showDot = true;
      });
    });

    // After 3 seconds (animation + logo time), check if logged in
    Future.delayed(const Duration(seconds: 3), () {
      checkLoginStatus();
    });
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    print("Token is : $token");

    if (token != null && token.isNotEmpty) {
      // Token exists, navigate to Homepage
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const Homepage()),
      );
    } else {
      // No token, navigate to RolePage
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const RolePage()),
      );
    }
  }

  @override
  void dispose() {
    // Dispose of the animation controller
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          double screenHeight = constraints.maxHeight;

          // Adjust font size based on screen width
          double fontSize = screenWidth * 0.12; // Dynamic font size
          double dotFontSize = screenWidth * 0.08; // Dynamic dot size

          return Container(
            width: screenWidth,
            height: screenHeight,
            color: Colors.green,
            child: Center(
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sportify',
                        style: GoogleFonts.anton(
                          fontSize: fontSize.clamp(40, 100), // Min 40, Max 100
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: showDot ? 1.0 : 0.0, // Control dot visibility
                        duration: const Duration(milliseconds: 1500),
                        child: Text(
                          '.',
                          style: GoogleFonts.anton(
                            fontSize:
                                dotFontSize.clamp(30, 80), // Min 30, Max 80
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
