import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportify_final/pages/utility/chatdetail.dart';
import 'package:sportify_final/pages/utility/chatservice.dart';

class SearchUsersPage extends StatefulWidget {
  const SearchUsersPage({Key? key}) : super(key: key);

  @override
  State<SearchUsersPage> createState() => _SearchUsersPageState();
}

class _SearchUsersPageState extends State<SearchUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getString("userUuid");
    });
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Convert query to lowercase for case-insensitive search
      String searchQuery = query.toLowerCase();

      // Query Firestore for users where name contains the search query
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      // Filter results locally (since Firestore doesn't support contains queries directly)
      List<Map<String, dynamic>> results = [];

      for (var doc in querySnapshot.docs) {
        var userData = doc.data() as Map<String, dynamic>;
        String userName = (userData['userName'] ?? '').toLowerCase();

        // Skip the current user
        if (doc.id == currentUserId) continue;

        // Check if username contains the search query
        if (userName.contains(searchQuery)) {
          results.add({
            'id': doc.id,
            'name': userData['userName'] ?? 'Unknown User',
            'photoUrl': userData['photoUrl'] ?? '',
          });
        }
      }

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching users: $e');
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching users: $e')),
      );
    }
  }

  Future<void> _startChat(String otherUserId, String otherUserName) async {
    try {
      // Check if a chat already exists between these users
      QuerySnapshot chatSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('type', isEqualTo: 'direct')
          .where('participants', arrayContains: currentUserId)
          .get();

      String chatId = '';

      // Look for existing chat with this user
      for (var doc in chatSnapshot.docs) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        List<dynamic> participants =
            data != null ? data['participants'] ?? [] : [];

        if (participants.contains(otherUserId)) {
          chatId = doc.id;
          break;
        }
      }

      // If no chat exists, create one
      if (chatId.isEmpty) {
        DocumentReference chatRef =
            await FirebaseFirestore.instance.collection('chats').add({
          'type': 'direct',
          'participants': [currentUserId, otherUserId],
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessage': 'New conversation started',
        });
        chatId = chatRef.id;
      }

      // Navigate to chat detail page
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailPage(
            chatId: chatId,
            chatName: otherUserName,
            isGroup: false,
          ),
        ),
      );
    } catch (e) {
      print('Error starting chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start conversation: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Users'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by username...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                _searchUsers(value);
              },
            ),
          ),
          _isSearching
              ? const Center(child: CircularProgressIndicator())
              : _searchResults.isEmpty && _searchController.text.isNotEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No users found'),
                      ),
                    )
                  : Expanded(
                      child: ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user['photoUrl'] != null &&
                                      user['photoUrl'].isNotEmpty
                                  ? FileImage(File(user['photoUrl']))
                                  : const AssetImage("assets/profile.png")
                                      as ImageProvider,
                            ),
                            title: Text(user['name']),
                            onTap: () {
                              _startChat(user['id'], user['name']);
                            },
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
