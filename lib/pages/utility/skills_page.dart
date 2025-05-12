import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Skill {
  final String title;
  final String description;
  final String youtubeLink;

  const Skill({
    required this.title,
    required this.description,
    required this.youtubeLink,
  });
}

class SportSkills {
  final String sportName;
  final String imagePath;
  final List<Skill> skills;

  const SportSkills({
    required this.sportName,
    required this.imagePath,
    required this.skills,
  });
}

class SkillsPage extends StatelessWidget {
  const SkillsPage({super.key});

  // Hardcoded data for each sport
  final List<SportSkills> _sportsList = const [
    SportSkills(
      sportName: "Football",
      imagePath: "assets/picture/football_skills.jpg",
      skills: [
        Skill(
          title: "Dribbling",
          description: "Master ball control to move past defenders.",
          youtubeLink: "https://www.youtube.com/watch?v=naEccnjzLxM",
        ),
        Skill(
          title: "Passing",
          description: "Deliver accurate passes to teammates under pressure.",
          youtubeLink: "https://www.youtube.com/watch?v=oIpRuzvsU80",
        ),
        Skill(
          title: "Shooting",
          description: "Learn various techniques to shoot on goal effectively.",
          youtubeLink: "https://www.youtube.com/watch?v=QDb5-cMIbjM",
        ),
      ],
    ),
    SportSkills(
      sportName: "Cricket",
      imagePath: "assets/picture/cricket_skills.jpg",
      skills: [
        Skill(
          title: "Batting",
          description: "Improve timing, footwork, and shot selection.",
          youtubeLink: "https://www.youtube.com/watch?v=U7pI9fHQnzY",
        ),
        Skill(
          title: "Bowling",
          description: "Master pace, spin, and line & length control.",
          youtubeLink: "https://www.youtube.com/watch?v=dPOo79b1UcM",
        ),
        Skill(
          title: "Fielding",
          description: "Enhance catching, throwing, and agility on the field.",
          youtubeLink: "https://www.youtube.com/watch?v=zKo2vy4cjdo",
        ),
      ],
    ),
    SportSkills(
      sportName: "Basketball",
      imagePath: "assets/picture/basketball_skills.webp",
      skills: [
        Skill(
          title: "Dribbling",
          description:
              "Use crossovers and hesitations to outmaneuver opponents.",
          youtubeLink: "https://www.youtube.com/watch?v=CMQp0bwjokw",
        ),
        Skill(
          title: "Shooting",
          description: "Refine your jump shot and free throw techniques.",
          youtubeLink: "https://www.youtube.com/watch?v=UcnB9e5O5NY",
        ),
        Skill(
          title: "Defending",
          description:
              "Learn how to guard effectively and read offensive plays.",
          youtubeLink: "https://www.youtube.com/watch?v=hPmc7R_dAxc",
        ),
      ],
    ),
    SportSkills(
      sportName: "Badminton",
      imagePath: "assets/picture/badminton_skills.jpg",
      skills: [
        Skill(
          title: "Serving",
          description:
              "Master high serve, low serve, and flick serve variations.",
          youtubeLink: "https://www.youtube.com/watch?v=J-YAqfLpzsQ",
        ),
        Skill(
          title: "Smashing",
          description: "Generate power and precision in your smash shots.",
          youtubeLink: "https://www.youtube.com/watch?v=H7kpZ9inc10",
        ),
        Skill(
          title: "Footwork",
          description:
              "Enhance speed and agility for effective court coverage.",
          youtubeLink: "https://www.youtube.com/watch?v=NhNEEcLPjpc",
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
        title: const Text("Skills & Tutorials"),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Returns to Tutorials grid
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Intro paragraph
            Padding(
              padding: EdgeInsets.all(
                  isSmallScreen ? 12.0 : 16.0), // Responsive padding
              child: Text(
                "Explore essential skills for each sport. Expand a section to view key skills, brief descriptions, and links to video tutorials for deeper learning.",
                style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16), // Responsive font size
              ),
            ),
            // Collapsible sections for each sport
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: _sportsList.map((sport) {
                  return Padding(
                    // Added padding around each expansion tile.
                    padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 4.0 : 6.0),
                    child: _buildSportExpansion(sport),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportExpansion(SportSkills sport) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          sport.sportName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        children: [
          // Sport image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              sport.imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          // List of skills
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: sport.skills.map((skill) {
                return _buildSkillItem(skill);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillItem(Skill skill) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            skill.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(skill.description, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => _launchYouTube(skill.youtubeLink),
            child: const Text(
              "Watch Tutorial",
              style: TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const Divider(), // a line separator
        ],
      ),
    );
  }

  Future<void> _launchYouTube(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch $urlString");
    }
  }
}
