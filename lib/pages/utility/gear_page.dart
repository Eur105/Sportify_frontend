import 'package:flutter/material.dart';

class GearItem {
  final String title;
  final String imagePath;
  final String description;

  const GearItem({
    required this.title,
    required this.imagePath,
    required this.description,
  });
}

class GearsPage extends StatelessWidget {
  const GearsPage({super.key});

  // Hardcoded gear data
  final List<GearItem> gearList = const [
    // FOOTWEAR
    GearItem(
      title: "Futsal Grippers",
      imagePath: "assets/picture/futsal_grippers.png",
      description:
          "Specialized indoor shoes with excellent grip on smooth surfaces, ideal for quick direction changes in futsal.",
    ),
    GearItem(
      title: "Football Studs",
      imagePath: "assets/picture/football_shoes.jpg",
      description:
          "Designed for outdoor grass pitches. Studs help maintain traction while running, passing, and shooting.",
    ),
    GearItem(
      title: "Basketball Trainers",
      imagePath: "assets/picture/basketball_shoes.jpg",
      description:
          "High-top or mid-top sneakers offering ankle support, cushioning, and grip for quick sprints and sharp pivots on the court.",
    ),
    GearItem(
      title: "Cricket Shoes",
      imagePath: "assets/picture/cricket_shoes.png",
      description:
          "Shoes with spikes or rubber soles to provide traction on grass pitches. Often have reinforced toe areas for bowlers.",
    ),

    // ADDITIONAL GEAR
    GearItem(
      title: "Cricket Bat & Gear",
      imagePath: "assets/picture/cricket_gear.jpg",
      description:
          "Includes the cricket bat, pads, gloves, and helmet. Ensures safety and optimal performance in batting and fielding.",
    ),
    GearItem(
      title: "Football & Shin Guards",
      imagePath: "assets/picture/football_gear.jpg",
      description:
          "A standard football plus shin guards to protect the lower legs from impact during tackles and high-speed play.",
    ),
    GearItem(
      title: "Badminton Racket & Shuttlecock",
      imagePath: "assets/picture/badminton_gear.webp",
      description:
          "A lightweight racket with a grip designed for quick wrist movements, paired with shuttlecocks for gameplay.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Adjust breakpoint as needed

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sports Gears"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Returns to Tutorials grid
          },
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 8.0 : 12.0), // Added vertical padding
        itemCount: gearList.length,
        itemBuilder: (context, index) {
          final gear = gearList[index];
          return Padding(
            // Added padding around each gear card.
            padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8.0 : 12.0,
                vertical: isSmallScreen ? 4.0 : 6.0),
            child: _buildGearCard(gear),
          );
        },
      ),
    );
  }

  Widget _buildGearCard(GearItem gear) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Gear Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.asset(
              gear.imagePath,
              fit: BoxFit.cover,
              height: 180,
              width: double.infinity,
            ),
          ),
          // Gear Title & Description
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gear.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(gear.description, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
