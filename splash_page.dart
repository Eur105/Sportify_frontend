// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:sportify_final/pages/login_page.dart';
import 'package:google_fonts/google_fonts.dart'; // Replace with your login page

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

    // Navigate to the next screen after the animation ends
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    });
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
      body: Stack(
        children: [
          // Green background
          Container(color: Colors.green),

          // Centered animated text
          Center(
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
                        fontSize: 70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AnimatedOpacity(
                        opacity: showDot ? 1.0 : 0.0, // Control dot visibility
                        duration: const Duration(milliseconds: 1500),
                        child: Text(
                          '.',
                          style: GoogleFonts.anton(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
