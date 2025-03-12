// ignore_for_file: file_names
/*
import 'package:flutter/material.dart';
import 'notification_page.dart';
import 'profile.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  final Color backgroundGrey = const Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
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
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.center,
            child: Text(
              "LEARN FROM THE PROFESSIONALS",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          const SizedBox(height: 30),
          const Align(
            alignment: Alignment.center,
            child: Text(
              "TUTORIALS",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Cards arranged in a Grid
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCard(
                  context,
                  "Nutritions",
                  "lib/assets/images/nutritions.jpg",
                ),
                _buildCard(context, "Rules", "lib/assets/images/rules.jpg"),
                _buildCard(context, "Gears", "lib/assets/images/gears.jpg"),
                _buildCard(context, "Skills", "lib/assets/images/skills.jpg"),
                _buildCard(context, "Fouls", "lib/assets/images/fouls.jpg"),
                _buildCard(context, "Fitness", "lib/assets/images/fitness.jpg"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, String imagePath) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => Scaffold(
                  appBar: AppBar(title: Text(title)),
                  body: Center(
                    child: Text("Content for $title will be added here."),
                  ),
                ),
          ),
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
              color: Colors.black.withOpacity(
                0.4,
              ), // Dark overlay for text visibility
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
*/

import 'package:flutter/material.dart';
import 'notification_page.dart';
import 'profile.dart';

// Import your tutorial pages
import 'nutritions.dart';
import 'rules_page.dart';
import 'gear_page.dart';
import 'skills_page.dart';
import 'fouls_page.dart';
import 'fitness_page.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  final Color backgroundGrey = const Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
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
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.center,
            child: Text(
              "LEARN FROM THE PROFESSIONALS",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          const SizedBox(height: 30),
          const Align(
            alignment: Alignment.center,
            child: Text(
              "TUTORIALS",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Cards arranged in a Grid
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCard(
                  context,
                  "Nutritions",
                  "lib/assets/images/nutritions.jpg",
                  const NutritionScreen(),
                ),
                _buildCard(
                  context,
                  "Rules",
                  "lib/assets/images/rules.jpg",
                  const RulesPage(),
                ),
                _buildCard(
                  context,
                  "Gears",
                  "lib/assets/images/gears.jpg",
                  const GearsPage(),
                ),
                _buildCard(
                  context,
                  "Skills",
                  "lib/assets/images/skills.jpg",
                  const SkillsPage(),
                ),
                _buildCard(
                  context,
                  "Fouls",
                  "lib/assets/images/fouls.jpg",
                  const FoulsPage(),
                ),
                _buildCard(
                  context,
                  "Fitness",
                  "lib/assets/images/fitness.jpg",
                  const FitnessPage(),
                ),
              ],
            ),
          ),
        ],
      ),
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
