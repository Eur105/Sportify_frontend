import 'package:flutter/material.dart';
import 'package:sportify_final/pages/utility/bottom_navbar.dart';
import 'package:sportify_final/pages/utility/fitness_page.dart';
import 'package:sportify_final/pages/utility/fouls_page.dart';
import 'package:sportify_final/pages/utility/gear_page.dart';
import 'package:sportify_final/pages/utility/nutritions.dart';
import 'package:sportify_final/pages/utility/profile.dart';
import 'package:sportify_final/pages/utility/rules_page.dart';
import 'package:sportify_final/pages/utility/skills_page.dart';
import 'notification_page.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  final Color backgroundGrey = const Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Adjust breakpoint as needed

    return Scaffold(
      backgroundColor: backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        title: const Text(
          "Let's Grow",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NotificationPage()),
              );
            },
            icon: const Icon(Icons.notifications, color: Colors.black),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            icon: const Icon(Icons.person, color: Colors.black),
          ),
        ],
      ),
      body: SingleChildScrollView(
        // Added for scrollability
        child: Column(
          children: [
            SizedBox(height: isSmallScreen ? 10 : 20), // Responsive spacing
            Align(
              alignment: Alignment.center,
              child: Text(
                "LEARN FROM THE PROFESSIONALS",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 18 : 20), // Responsive font size
              ),
            ),
            SizedBox(height: isSmallScreen ? 20 : 30), // Responsive spacing
            Align(
              alignment: Alignment.center,
              // child: Text(
              //   "TUTORIALS",
              //   style: TextStyle(
              //     fontSize: isSmallScreen ? 20 : 22, // Responsive font size
              //     fontWeight: FontWeight.bold,
              //     color: Colors.grey,
              //   ),
              // ),
            ),
            SizedBox(height: isSmallScreen ? 20 : 30), // Responsive spacing

            // Cards arranged in a Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount:
                    2, // always show 2 columns (good even for small screens)
                childAspectRatio: 2 / 2, // smaller height
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildCard(context, "Nutritions",
                      "assets/picture/nutritions.jpg", const NutritionScreen()),
                  _buildCard(context, "Rules", "assets/picture/rules.jpg",
                      const RulesPage()),
                  _buildCard(context, "Gears", "assets/picture/gears.jpg",
                      const GearsPage()),
                  _buildCard(context, "Skills", "assets/picture/skills.jpg",
                      const SkillsPage()),
                  _buildCard(context, "Fouls", "assets/picture/fouls.jpg",
                      const FoulsPage()),
                  _buildCard(context, "Fitness", "assets/picture/fitness.jpg",
                      const FitnessPage()),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavbar(),
    );
  }

  Widget _buildCard(
    BuildContext context,
    String title,
    String imagePath,
    Widget targetPage,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12), // Rounded corners
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              imagePath,
              fit: BoxFit.cover, // Cover entire card
            ),
            Container(
              color: Colors.black.withOpacity(0.4), // Dark overlay
            ),
            Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // White text for contrast
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
