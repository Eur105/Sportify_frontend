import 'package:flutter/material.dart';
import 'package:sportify_final/pages/utility/bottom_navbar.dart';

class LearnPage extends StatefulWidget {
  const LearnPage({super.key});

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.notifications, color: Colors.black),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.person, color: Colors.black),
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
                _buildCard(context, "Nutritions"),
                _buildCard(context, "Rules"),
                _buildCard(context, "Gears"),
                _buildCard(context, "Skills"),
                _buildCard(context, "Fouls"),
                _buildCard(context, "Fitness"),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavbar(),
    );
  }

  // A helper function to build each card with InkWell
  Widget _buildCard(BuildContext context, String title) {
    return InkWell(
      onTap: () {
        // Placeholder for navigation; replace with actual routes
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: Text(title)),
              body:
                  Center(child: Text("Content for $title will be added here.")),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      splashColor: Colors.blueAccent.withOpacity(0.2), // Customize splash color
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
