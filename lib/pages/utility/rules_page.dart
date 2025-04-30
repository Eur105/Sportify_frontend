import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// A simple data model for each sport rule section
class SportRule {
  final String title;
  final String imagePath;
  final String content;
  final String link; // Link for further reading

  const SportRule({
    required this.title,
    required this.imagePath,
    required this.content,
    required this.link,
  });
}

class RulesPage extends StatelessWidget {
  const RulesPage({super.key});

  // List of sports with rules
  final List<SportRule> sports = const [
    SportRule(
      title: "Cricket",
      imagePath: "assets/picture/cricket.jpg",
      content: """
Cricket is a bat-and-ball game played between two teams of eleven players. 
Basic rules include batting, bowling, and fielding, with the objective of scoring runs and dismissing opponents.

Key Points:
• Each team bats once in limited-overs matches.
• A batsman is 'out' if the ball hits the stumps or is caught by a fielder.
• An over consists of 6 legal deliveries (balls).

""",
      link: "https://www.icc-cricket.com/about/cricket/rules-and-regulations",
    ),
    SportRule(
      title: "Basketball",
      imagePath: "assets/picture/basketball.jpg",
      content: """
Basketball is played by two teams of five players each. 
Players score by shooting the ball through the opponent's hoop.

Key Points:
• 4 quarters of 10 or 12 minutes (league-dependent).
• Dribbling is required while moving with the ball.
• 2 or 3 points per shot, depending on distance.

""",
      link: "https://www.fiba.basketball/rules",
    ),
    SportRule(
      title: "Football",
      imagePath: "assets/picture/football.jpg",
      content: """
Football (soccer) is played by two teams of eleven. 
Players aim to score by getting the ball into the opposing goal.

Key Points:
• A match consists of two 45-minute halves.
• Offside rule prevents attackers from gaining an unfair advantage.
• Fouls may result in free kicks, penalties, or yellow/red cards.

""",
      link: "https://www.fifa.com/inside-football-documents/laws-of-the-game",
    ),
    SportRule(
      title: "Futsal",
      imagePath: "assets/picture/futsal.jpg",
      content: """
Futsal is a variant of football played on a smaller, indoor court with five players per side.

Key Points:
• Two halves of 20 minutes each.
• Smaller ball with less bounce.
• Emphasis on quick passing, dribbling, and close control.

""",
      link: "https://www.fifa.com/inside-futsal-documents",
    ),
    SportRule(
      title: "Badminton",
      imagePath: "assets/picture/badminton.jpg",
      content: """
Badminton is a racquet sport played with a shuttlecock. 
Players score points by striking the shuttlecock over the net into the opponent's court.

Key Points:
• Best of 3 games, each up to 21 points.
• Serve must be below the waist.
• Only one hit per side to get the shuttle over the net.

""",
      link: "https://corporate.bwfbadminton.com/regulations/",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Adjust breakpoint as needed

    return Scaffold(
      appBar: AppBar(
        title: const Text("Rules & Regulations"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Returns to Tutorials grid
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding:
              EdgeInsets.all(isSmallScreen ? 12.0 : 16.0), // Responsive padding
          child: Column(
            children: sports.map((sport) {
              return Padding(
                // Added padding around each rule card.
                padding:
                    EdgeInsets.symmetric(vertical: isSmallScreen ? 4.0 : 6.0),
                child: _buildSportRuleCard(sport),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Build each collapsible card
  Widget _buildSportRuleCard(SportRule sport) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          sport.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        children: [
          // Display image inside expanded section
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(sport.imagePath, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              sport.content,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
          // Link for further reading
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: TextButton(
              onPressed: () => _launchLink(sport.link),
              child: const Text(
                "Learn More",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchLink(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      // Launch in external browser
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // handle error
      debugPrint("Could not launch $urlString");
    }
  }
}
