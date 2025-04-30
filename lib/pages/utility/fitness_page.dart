import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FitnessItem {
  final String title;
  final String description;
  final String youtubeLink;

  const FitnessItem({
    required this.title,
    required this.description,
    required this.youtubeLink,
  });
}

class FitnessSection {
  final String sectionName;
  final String imagePath;
  final String sectionDescription;
  final List<FitnessItem> items;

  const FitnessSection({
    required this.sectionName,
    required this.imagePath,
    required this.sectionDescription,
    required this.items,
  });
}

class FitnessPage extends StatelessWidget {
  const FitnessPage({super.key});

  final List<FitnessSection> _sections = const [
    FitnessSection(
      sectionName: "Warm-Up",
      imagePath: "assets/picture/warmup.jpg",
      sectionDescription:
          "A proper warm-up increases blood flow, loosens muscles, and prepares your body for exercise. It reduces the risk of injury and improves performance.",
      items: [
        FitnessItem(
          title: "Dynamic Stretches",
          description:
              "Activate major muscle groups with leg swings, arm circles, and hip rotations.",
          youtubeLink: "https://www.youtube.com/watch?v=3qyWpJ34dWw",
        ),
        FitnessItem(
          title: "Light Cardio",
          description:
              "Engage in 5-10 minutes of jogging in place or skipping to elevate heart rate.",
          youtubeLink: "https://m.youtube.com/watch?v=RMeqrB7c-GU&t=59s",
        ),
      ],
    ),
    FitnessSection(
      sectionName: "Workout Routines",
      imagePath: "assets/picture/workout.png",
      sectionDescription:
          "Choose a routine based on your fitness level. Consistency and progression are key for best results.",
      items: [
        FitnessItem(
          title: "Beginner Cardio",
          description:
              "A 20-minute low-impact session focusing on steady-state jogging or brisk walking.",
          youtubeLink: "https://www.youtube.com/watch?v=VWj8ZxCxrYk",
        ),
        FitnessItem(
          title: "Intermediate Strength",
          description:
              "A 30-minute routine featuring bodyweight exercises (push-ups, squats) and light weights.",
          youtubeLink: "https://www.youtube.com/watch?v=bUd635j-KAA",
        ),
        FitnessItem(
          title: "Advanced Endurance",
          description:
              "High-intensity interval training (HIIT) for improved stamina and calorie burn.",
          youtubeLink: "https://www.youtube.com/watch?v=2M8bTJj-ouY",
        ),
      ],
    ),
    FitnessSection(
      sectionName: "Cool-Down",
      imagePath: "assets/picture/cooldown.jpg",
      sectionDescription:
          "A cool-down helps your body transition back to rest, reducing muscle soreness and heart rate gradually.",
      items: [
        FitnessItem(
          title: "Static Stretches",
          description:
              "Hold stretches for 15-30 seconds to improve flexibility and relieve tension.",
          youtubeLink: "https://www.youtube.com/watch?v=uO4KFToGWS0",
        ),
        FitnessItem(
          title: "Breathing Exercises",
          description:
              "Deep breathing to calm the nervous system and aid recovery.",
          youtubeLink: "https://www.youtube.com/watch?v=7Ep5mKuRmAA",
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Adjust breakpoint as needed

    return Scaffold(
      appBar: AppBar(
        title: const Text("Fitness Guide"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Intro Paragraph
            Padding(
              padding: EdgeInsets.all(
                  isSmallScreen ? 12.0 : 16.0), // Responsive padding
              child: Text(
                "Explore essential fitness routines for a well-rounded workout. Expand a section to view detailed plans, descriptions, and links to video tutorials.",
                style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16), // Responsive font size
              ),
            ),
            // Collapsible sections
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: _sections.map((section) {
                  return Padding(
                    // Added padding around each fitness section.
                    padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 4.0 : 6.0),
                    child: _buildFitnessSection(section),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFitnessSection(FitnessSection section) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          section.sectionName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        children: [
          // Section Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              section.imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          // Section Description + Items
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.sectionDescription,
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 12),
                ...section.items.map(_buildFitnessItem).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFitnessItem(FitnessItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(item.description, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => _launchUrl(item.youtubeLink),
            child: const Text(
              "Watch Tutorial",
              style: TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch $urlString");
    }
  }
}
