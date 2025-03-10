// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:sportify_final/pages/utility/app_bar.dart';
import 'package:sportify_final/pages/utility/bottom_navbar.dart';
import 'utility/inbox_page.dart'; // Import the new inbox page

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // Sample chat data. If empty, "Let's chat" message will appear.
  List<Map<String, String>> chats = [];

  @override
  Widget build(BuildContext context) {
    return SlidingDrawerLayout(
      body: chats.isEmpty
          ? Center(
              child: Text(
                "Let's chat!",
                style: TextStyle(fontSize: 20, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Text(chat['name']![0]),
                  ),
                  title: Text(chat['name']!),
                  subtitle: Text(
                    chat['lastMessage']!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    // Navigate to chat detail (placeholder)
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Open chat with ${chat['name']}'),
                    ));
                  },
                );
              },
            ),
      bottomNavigationBar: BottomNavbar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to InboxPage
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => InboxPage()),
          );
        },
        child: Icon(Icons.chat),
      ),
    );
  }
}
