import 'package:flutter/material.dart';

class BlogsScreens extends StatelessWidget {
  const BlogsScreens({super.key});
  final Color backgroundGrey = const Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    // Sample blog data (Replace this with backend data later)
    final List<Map<String, String>> blogs = [
      {
        "title": "The Future of Sports Technology",
        "description":
            "Discover how AI and tech are transforming the sports industry.",
        "date": "February 18, 2025",
      },
      {
        "title": "Top 5 Exercises for Athletes",
        "description":
            "Learn about the best exercises to enhance your strength and endurance.",
        "date": "February 15, 2025",
      },
      {
        "title": "The Rise of E-Sports",
        "description":
            "How competitive gaming is taking over traditional sports.",
        "date": "February 10, 2025",
      },
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Adjust breakpoint as needed

    return Scaffold(
      backgroundColor: backgroundGrey,
      appBar: AppBar(
        title: const Text("Blogs"),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        padding:
            EdgeInsets.all(isSmallScreen ? 12.0 : 16.0), // Responsive padding
        itemCount: blogs.length,
        itemBuilder: (context, index) {
          final blog = blogs[index];

          return Card(
            elevation: 3,
            margin: EdgeInsets.only(
                bottom: isSmallScreen ? 8.0 : 12.0), // Responsive margin
            child: ListTile(
              title: Text(
                blog["title"]!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 14 : 16, // Responsive font size
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: isSmallScreen ? 3 : 5), // Responsive spacing
                  Text(
                    blog["description"]!,
                    style: const TextStyle(color: Colors.black54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isSmallScreen ? 3 : 5), // Responsive spacing
                  Text(
                    blog["date"]!,
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                  ),
                ],
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.black54,
              ),
              onTap: () {
                // TODO: Navigate to Blog Details Screen
              },
            ),
          );
        },
      ),
    );
  }
}
