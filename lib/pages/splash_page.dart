// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportify_final/pages/homepage.dart';
import 'package:sportify_final/pages/utility/role_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();

    // Navigate after delay
    Future.delayed(const Duration(seconds: 6), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const RolePage()),
      );
    });
    Future.delayed(const Duration(seconds: 3), () {
      checkLoginStatus();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final titleFontSize = screenWidth * 0.14;
    final taglineFontSize = screenWidth * 0.05;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Using a different approach with Row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // First part of text "Sp"
                    Text(
                      'Sp',
                      style: GoogleFonts.anton(
                        fontSize: titleFontSize.clamp(40, 100),
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),

                    // The ball animation replacing "o"
                    SizedBox(
                      width: titleFontSize.clamp(40, 100) * 0.8,
                      height: titleFontSize.clamp(40, 100) * 0.8,
                      child: Lottie.asset(
                        'assets/animation/ani1.json',
                        fit: BoxFit.contain,
                        repeat: true,
                        animate: true,
                      ),
                    ),

                    // Last part of text "rtify"
                    Text(
                      'rtify',
                      style: GoogleFonts.anton(
                        fontSize: titleFontSize.clamp(40, 100),
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Text(
                  'Game on, Anytime, Anywhere',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: taglineFontSize.clamp(16, 28),
                    color: Colors.green,
                    fontWeight: FontWeight.w400,
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
