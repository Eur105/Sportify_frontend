import 'package:flutter/material.dart';

class BlogsScreen extends StatelessWidget {
  const BlogsScreen({super.key});
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

    return Scaffold(
      backgroundColor: backgroundGrey,
      appBar: AppBar(
        title: const Text(
          "Blogs",
          style: TextStyle(),
        ),
        backgroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: blogs.length,
        itemBuilder: (context, index) {
          final blog = blogs[index];

          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(
                blog["title"]!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  Text(
                    blog["description"]!,
                    style: const TextStyle(color: Colors.black54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to Add Blog Screen
        },
        backgroundColor: Colors.blue.shade800,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
