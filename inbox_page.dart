import 'package:flutter/material.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  // Sample friends list
  final List<String> friends = [
    'Alice Johnson',
    'Bob Smith',
    'Charlie Davis',
    'Diana Evans',
    'Eve Carter'
  ];

  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    // Filtered friends based on search query
    final filteredFriends = friends
        .where((friend) =>
            friend.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: TextField(
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search for friends',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.black),
          ),
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: filteredFriends.isEmpty
          ? Center(
              child: Text(
                'No friends found.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: filteredFriends.length,
              itemBuilder: (context, index) {
                final friend = filteredFriends[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Text(friend[0]),
                  ),
                  title: Text(friend),
                  onTap: () {
                    // Create a new chat with this friend (placeholder)
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Starting chat with $friend'),
                    ));
                  },
                );
              },
            ),
    );
  }
}
