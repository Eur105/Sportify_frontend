import 'package:flutter/material.dart';

// Data model for each foul
class FoulItem {
  final String foulName;
  final String briefDescription;
  final String inDepthExplanation;

  const FoulItem({
    required this.foulName,
    required this.briefDescription,
    required this.inDepthExplanation,
  });
}

// Data model grouping fouls under a specific sport
class SportFouls {
  final String sportName;
  final List<FoulItem> fouls;

  const SportFouls({required this.sportName, required this.fouls});
}

class FoulsPage extends StatelessWidget {
  const FoulsPage({super.key});

  // Hardcoded data for each sport
  final List<SportFouls> _sportsList = const [
    SportFouls(
      sportName: "Football",
      fouls: [
        FoulItem(
          foulName: "Handball",
          briefDescription: "When a player deliberately handles the ball.",
          inDepthExplanation:
              "Any intentional contact between the ball and the hand/arm. Accidental contact may not be penalized, but referees look for arm movement and intent.",
        ),
        FoulItem(
          foulName: "Tripping / Slide Tackle from Behind",
          briefDescription:
              "Attempting to trip an opponent by sliding or extending the leg from behind.",
          inDepthExplanation:
              "This is considered dangerous play. If contact is made or the opponent is impeded, a direct free kick or penalty is awarded, and possibly a card.",
        ),
        FoulItem(
          foulName: "Charging / Pushing",
          briefDescription: "Using excessive force or body contact.",
          inDepthExplanation:
              "Shoulder-to-shoulder contact is allowed, but pushing with arms or charging violently is a foul. This can lead to free kicks, penalties, or cards.",
        ),
      ],
    ),
    SportFouls(
      sportName: "Basketball",
      fouls: [
        FoulItem(
          foulName: "Personal Foul",
          briefDescription:
              "Illegal physical contact (e.g., blocking, pushing).",
          inDepthExplanation:
              "Most common type of foul. Involves contact that impedes an opponent’s freedom of movement, like reaching in or bumping while dribbling.",
        ),
        FoulItem(
          foulName: "Charging",
          briefDescription:
              "An offensive player runs into a defender with an established position.",
          inDepthExplanation:
              "If the defender’s feet are set and they are not moving laterally, the offensive player is called for a charge, resulting in a turnover.",
        ),
        FoulItem(
          foulName: "Flagrant Foul",
          briefDescription:
              "Excessive or violent contact, more severe than a normal foul.",
          inDepthExplanation:
              "It’s penalized more heavily with free throws and possible ejection, depending on the severity of the contact.",
        ),
      ],
    ),
    SportFouls(
      sportName: "Cricket",
      fouls: [
        FoulItem(
          foulName: "Ball Tampering",
          briefDescription:
              "Altering the ball’s condition to gain an unfair advantage.",
          inDepthExplanation:
              "Using foreign substances or scratching the surface of the ball can lead to penalties, suspension, or fines.",
        ),
        FoulItem(
          foulName: "Obstructing the Field",
          briefDescription:
              "A batsman intentionally obstructs a fielder from fielding the ball.",
          inDepthExplanation:
              "If deemed intentional by the umpire, the batsman can be given out for obstructing the field.",
        ),
        FoulItem(
          foulName: "Time Wasting",
          briefDescription: "Deliberate slowing down of play.",
          inDepthExplanation:
              "Teams may be penalized if they delay the game excessively, resulting in warnings or fines from the match referee.",
        ),
      ],
    ),
    SportFouls(
      sportName: "Badminton",
      fouls: [
        FoulItem(
          foulName: "Service Fault",
          briefDescription:
              "Illegal serve, such as serving above the waist or incorrect racket angle.",
          inDepthExplanation:
              "If the shuttle is struck above the waist or the racket head is above the hand, it’s a service fault, resulting in a point for the opponent.",
        ),
        FoulItem(
          foulName: "Net Touch",
          briefDescription: "Touching the net with the racket or body.",
          inDepthExplanation:
              "Players cannot make contact with the net or invade the opponent’s court. Doing so results in a fault.",
        ),
        FoulItem(
          foulName: "Double Hit",
          briefDescription:
              "Hitting the shuttle twice in succession on one side of the net.",
          inDepthExplanation:
              "A player or team may only strike the shuttle once before it crosses the net. Striking it twice is illegal.",
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
        title: const Text("Fouls & Penalties"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Returns to Tutorials
          },
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
                "Learn about common fouls in different sports. Expand a section to see a brief description of each foul and an in-depth explanation of how it impacts the game.",
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
                    // Added padding around each sport foul card.
                    padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 4.0 : 6.0),
                    child: _buildSportFoulsCard(sport),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportFoulsCard(SportFouls sport) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          sport.sportName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sport.fouls.map((foul) {
                return _buildFoulItem(foul);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoulItem(FoulItem foul) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foul name (bullet point)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("• ", style: TextStyle(fontSize: 18)),
              Expanded(
                child: Text(
                  foul.foulName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          // Brief description
          Padding(
            padding: const EdgeInsets.only(left: 24.0, top: 4.0),
            child: Text(
              "Brief: ${foul.briefDescription}",
              style: const TextStyle(fontSize: 14),
            ),
          ),
          // In-depth explanation
          Padding(
            padding: const EdgeInsets.only(left: 24.0, top: 2.0),
            child: Text(
              "In-depth: ${foul.inDepthExplanation}",
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
