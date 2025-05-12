// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Adjust breakpoint as needed

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nutrition Guide"),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context); // Goes back to Tutorials
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Banner at the Top
            SizedBox(
              width: double.infinity,
              height: isSmallScreen ? 150 : 200, // Responsive banner height
              child: Image.asset(
                "assets/picture/banner.jpg", // Replace with your banner image
                fit: BoxFit.cover,
              ),
            ),

            // 2. Sections
            Padding(
              padding: EdgeInsets.all(
                  isSmallScreen ? 12.0 : 16.0), // Responsive padding
              child: Column(
                children: [
                  NutritionSection(
                    title: "Pre-Workout Nutrition",
                    content: """
Before a workout, your body needs fuel for energy and endurance.

✔ Carbohydrates: Oats, bananas, whole grains.
✔ Protein: Eggs, yogurt, whey protein.
✔ Healthy Fats: Nuts, avocado, seeds.

🥣 Best Meal Ideas:
- Oatmeal + Banana + Peanut Butter
- Greek Yogurt + Berries + Honey
- Grilled Chicken + Brown Rice + Veggies

⏳ Timing:
- 1-2 hours before: Full meal
- 30-45 minutes before: Light snack
""",
                    imagePath: "assets/picture/pre_workout.png",
                  ),
                  SizedBox(
                      height: isSmallScreen ? 10 : 16), // Responsive spacing
                  NutritionSection(
                    title: "Post-Workout Nutrition",
                    content: """
After a workout, your muscles need nutrients for recovery.

✔ Protein: Chicken, fish, eggs, Greek yogurt.
✔ Carbs: Whole grains, quinoa, fruits.
✔ Hydration: Water, electrolytes.

🥗 Best Meal Ideas:
- Grilled Chicken + Quinoa + Veggies
- Scrambled Eggs + Whole Wheat Toast
- Protein Shake + Banana + Peanut Butter

⏳ Timing:
- Within 30-60 minutes after a workout for best absorption.
""",
                    imagePath: "assets/picture/post_workout.jpeg",
                  ),
                  SizedBox(
                      height: isSmallScreen ? 10 : 16), // Responsive spacing
                  NutritionSection(
                    title: "Hydration",
                    content: """
Proper hydration is essential for performance and recovery.

💧 Why Hydration is Important:
✔ Prevents muscle cramps and fatigue.
✔ Regulates body temperature.
✔ Supports joint lubrication.

🚰 Hydration Guide:
- Before Workout: 500ml water (2 cups)
- During Workout: 200-300ml water every 20 minutes
- After Workout: 500ml - 1L water based on sweat loss

🥤 Best Hydration Sources: 
Water, Coconut Water, Sports Drinks, Watermelon, Cucumber.
""",
                    imagePath: "assets/picture/hydration.jpg",
                  ),
                  SizedBox(
                      height: isSmallScreen ? 10 : 16), // Responsive spacing
                  NutritionSection(
                    title: "Supplements",
                    content: """
Supplements can enhance performance and recovery.

🥛 Common Supplements & Benefits:
✔ Whey Protein: Muscle recovery.
✔ Creatine: Strength & endurance.
✔ BCAAs: Reduce muscle soreness.
✔ Pre-Workout: Boosts energy & focus.
✔ Omega-3: Joint health.

💡 Do You Need Supplements?
- Only if your diet lacks key nutrients.
- Always consult a nutritionist before use.
""",
                    imagePath: "assets/picture/supplements.jpg",
                  ),
                  SizedBox(
                      height: isSmallScreen ? 10 : 16), // Responsive spacing
                  NutritionSection(
                    title: "Diet Plans",
                    content: """
Your diet should match your fitness goals.

📉 Weight Loss: 
✔ High protein, moderate carbs, healthy fats.
✔ Avoid processed sugars & refined carbs.
🥗 Example: Grilled Salmon + Quinoa + Greens.

💪 Muscle Gain: 
✔ High protein, high carbs, moderate fats.
✔ Increase calories with whole foods.
🍗 Example: Chicken Breast + Brown Rice + Veggies.

🏃 Endurance Training: 
✔ High-carb, moderate protein, healthy fats.
✔ Slow-digesting carbs like oats, quinoa.
🥑 Example: Whole Wheat Pasta + Lean Protein + Avocado.

🔥 General Fitness: 
✔ Balanced meals, plenty of fruits, vegetables, and proteins.
🍎 Example: Greek Yogurt + Nuts + Honey.
""",
                    imagePath: "assets/picture/diet_plans.png",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom widget for each expandable section
class NutritionSection extends StatelessWidget {
  final String title;
  final String content;
  final String? imagePath; // Optional image path

  const NutritionSection({
    super.key,
    required this.title,
    required this.content,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        children: [
          // Display image inside the expanded content, if provided
          if (imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(imagePath!, fit: BoxFit.cover),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              content,
              style: TextStyle(fontSize: 16, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }
}
