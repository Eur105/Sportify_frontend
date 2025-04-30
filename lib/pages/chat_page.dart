// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportify_final/pages/notification_page.dart';
import 'package:sportify_final/pages/utility/bottom_navbar.dart';
import 'package:sportify_final/pages/utility/chatdetail.dart';
import 'package:sportify_final/pages/utility/chatservice.dart';
import 'package:sportify_final/pages/utility/profile.dart';
import 'package:sportify_final/pages/utility/usermanage.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final Color backgroundGrey = const Color(0xFFF5F5F5);
  bool showDms = true;
  List<Map<String, dynamic>> dms = [];
  List<Map<String, dynamic>> groups = [];
  TextEditingController messageController = TextEditingController();
  String currentChatId = "";
  //String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
  bool isLoading = true;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    UserManager.setupPresence();
    _loadUserId();
    loadChats();

    // Listen for auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && user.uid != currentUserId) {
        setState(() {
          currentUserId = user.uid;
          print("user.uid value: ${user.uid}");
        });
        loadChats();
      }
    });
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    currentUserId = prefs.getString("userUuid");
    print("see uid: $currentUserId");
    //loadChats(); // assuming "uuid" is the key
  }

  Future<void> loadChats() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get DMs using ChatService
      ChatService.getUserChats(isGroup: false, uid: currentUserId)
          .listen((snapshot) async {
        List<Map<String, dynamic>> tempDms = [];
        for (var doc in snapshot.docs) {
          var chatData = doc.data() as Map<String, dynamic>;

          // Get other user ID
          String otherUserId = (chatData['participants'] as List).firstWhere(
              (id) => id != UserManager.currentUserId,
              orElse: () => '');

          if (otherUserId.isNotEmpty) {
            // Get user data using UserManager
            var userData = await UserManager.getUserData(otherUserId);
            if (userData != null) {
              tempDms.add({
                'id': doc.id,
                'name': userData['name'] ?? 'Unknown User',
                'message': chatData['lastMessage'] ?? 'Start a conversation',
                'photoUrl': userData['photoUrl'] ?? '',
                'timestamp': chatData['lastMessageTime'],
              });
            }
          }
        }
        setState(() {
          dms = tempDms;
          isLoading = false;
        });
      });

      ChatService.getUserChats(isGroup: true, uid: currentUserId)
          .listen((snapshot) {
        List<Map<String, dynamic>> tempGroups = [];

        for (var doc in snapshot.docs) {
          var chatData = doc.data() as Map<String, dynamic>;

          tempGroups.add({
            'id': doc.id,
            'name': chatData['name'] ?? 'Unnamed Group',
            'message': chatData['lastMessage'] ?? 'No messages yet',
            'photoUrl': chatData['photoUrl'] ?? '',
            'timestamp': chatData['lastMessageTime'],
          });
        }

        setState(() {
          groups = tempGroups;
          isLoading = false;
        });
      });

      // Similar code for group chats using ChatService.getUserChats(isGroup: true)
    } catch (e) {
      print('Error loading chats: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Other methods similarly refactored...

  void processChats(QuerySnapshot snapshot) async {
    List<Map<String, dynamic>> tempDms = [];
    List<Map<String, dynamic>> tempGroups = [];

    for (var doc in snapshot.docs) {
      var chatData = doc.data() as Map<String, dynamic>;
      String chatType = chatData['type'] ?? 'direct';

      if (chatType == 'direct') {
        // Process direct messages
        String otherUserId = (chatData['participants'] as List)
            .firstWhere((id) => id != currentUserId, orElse: () => '');

        if (otherUserId.isNotEmpty) {
          try {
            var userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(otherUserId)
                .get();

            if (userDoc.exists) {
              var userData = userDoc.data() as Map<String, dynamic>;
              tempDms.add({
                'id': doc.id,
                'name': userData['name'] ?? 'Unknown User',
                'message': chatData['lastMessage'] ?? 'Start a conversation',
                'photoUrl': userData['photoUrl'] ?? '',
                'timestamp': chatData['lastMessageTime'],
              });
            }
          } catch (e) {
            print('Error getting user data: $e');
          }
        }
      } else if (chatType == 'group') {
        // Process group chats
        tempGroups.add({
          'id': doc.id,
          'name': chatData['name'] ?? 'Unnamed Group',
          'message': chatData['lastMessage'] ?? 'No messages yet',
          'photoUrl': chatData['photoUrl'] ?? '',
          'timestamp': chatData['lastMessageTime'],
        });
      }
    }

    setState(() {
      dms = tempDms;
      groups = tempGroups;
    });
  }

  Stream<QuerySnapshot> _chatStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    return FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getChatMessages(String chatId) {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  Future<void> sendMessage() async {
    if (messageController.text.isNotEmpty && currentChatId.isNotEmpty) {
      try {
        // Create message data
        final messageData = {
          'senderId': currentUserId,
          'text': messageController.text,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        };

        // Add message to subcollection
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(currentChatId)
            .collection('messages')
            .add(messageData);

        // Update the last message in the chat document
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(currentChatId)
            .update({
          'lastMessage': messageController.text,
          'lastMessageTime': FieldValue.serverTimestamp(),
        });

        messageController.clear();
      } catch (e) {
        print('Error sending message: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } else {
      if (currentChatId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a chat first')),
        );
      }
    }
  }

  Future<void> createNewDm(String otherUserId, String otherUserName) async {
    try {
      // Check if chat already exists
      final querySnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('type', isEqualTo: 'direct')
          .where('participants', arrayContains: currentUserId)
          .get();

      for (var doc in querySnapshot.docs) {
        List<dynamic> participants = doc.data()['participants'];
        if (participants.contains(otherUserId)) {
          // Chat already exists, just open it
          setState(() {
            currentChatId = doc.id;
          });
          return;
        }
      }

      // Create a new chat
      DocumentReference chatRef =
          await FirebaseFirestore.instance.collection('chats').add({
        'type': 'direct',
        'participants': [currentUserId, otherUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessage': 'New conversation started',
      });

      setState(() {
        currentChatId = chatRef.id;
        dms.add({
          'id': chatRef.id,
          'name': otherUserName,
          'message': 'New conversation started',
          'timestamp': Timestamp.now(),
        });
      });
    } catch (e) {
      print('Error creating new DM: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create conversation: $e')),
      );
    }
  }

  Future<void> createNewGroup(String groupName, List<String> memberIds) async {
    try {
      // Call the ChatService to create the group
      String? newGroupId =
          await ChatService.createGroupChat(groupName, memberIds);

      if (newGroupId != null) {
        setState(() {
          currentChatId = newGroupId;
          groups.add({
            'id': newGroupId,
            'name': groupName,
            'message': 'Group created',
            'timestamp': Timestamp.now(),
          });
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create group')),
        );
      }
    } catch (e) {
      print('Error creating new group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create group: $e')),
      );
    }
  }

  void _showCreateGroupDialog() {
    final TextEditingController groupNameController = TextEditingController();
    final List<String> selectedUsers = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create New Group'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: groupNameController,
                    decoration: const InputDecoration(
                      labelText: 'Group Name',
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Here you would normally show a list of users to select
                  // For simplicity we're just using a placeholder
                  const Text('Select members:'),
                  // In a real app, replace this with a user selection list
                  const Text('(User selection would go here)'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (groupNameController.text.isNotEmpty) {
                      // In a real app, selectedUsers would come from UI selection
                      createNewGroup(groupNameController.text, selectedUsers);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showNewChatDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Start a New Chat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance.collection('users').get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  final users = snapshot.data?.docs
                          .where((doc) => doc.id != currentUserId)
                          .toList() ??
                      [];

                  return SizedBox(
                    height: 300,
                    width: double.maxFinite,
                    child: ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        var userData =
                            users[index].data() as Map<String, dynamic>;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: userData['photoUrl'] != null &&
                                    userData['photoUrl'].isNotEmpty
                                ? NetworkImage(userData['photoUrl'])
                                : const AssetImage("assets/profile.png")
                                    as ImageProvider,
                          ),
                          title: Text(userData['name'] ?? 'Unknown User'),
                          onTap: () {
                            createNewDm(users[index].id,
                                userData['name'] ?? 'Unknown User');
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Adjust breakpoint as needed

    return Scaffold(
      backgroundColor: backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Let's Connect",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              if (showDms) {
                _showNewChatDialog();
              } else {
                _showCreateGroupDialog();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => NotificationPage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ProfilePage()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: backgroundGrey,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildToggleButton("DMs", showDms, () {
                  setState(() {
                    showDms = true;
                    currentChatId = "";
                  });
                }),
                _buildToggleButton("Groups", !showDms, () {
                  setState(() {
                    showDms = false;
                    currentChatId = "";
                  });
                }),
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 10), // Responsive spacing
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                // Implement search functionality here
              },
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 10), // Responsive spacing
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildChatList(showDms ? dms : groups),
          ),
          Visibility(
            visible: currentChatId.isNotEmpty,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 10), // Responsive spacing
                  FloatingActionButton(
                    onPressed: sendMessage,
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavbar(),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
        backgroundColor: isSelected ? Colors.green : Colors.grey[300],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildChatList(List<Map<String, dynamic>> chatData) {
    if (chatData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "No chats yet!",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (showDms) {
                  _showNewChatDialog();
                } else {
                  _showCreateGroupDialog();
                }
              },
              child: Text(showDms ? "Start a new chat" : "Create a group"),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: chatData.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: chatData[index]["photoUrl"] != null &&
                    chatData[index]["photoUrl"].isNotEmpty
                ? NetworkImage(chatData[index]["photoUrl"])
                : const AssetImage("assets/profile.png") as ImageProvider,
          ),
          title: Text(chatData[index]["name"] ?? ""),
          subtitle: Text(chatData[index]["message"] ?? ""),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            setState(() {
              currentChatId = chatData[index]["id"];
            });

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailPage(
                  chatId: chatData[index]["id"],
                  chatName: chatData[index]["name"],
                  isGroup: !showDms, // Add this parameter
                ),
              ),
            ).then((_) {
              // This ensures state is refreshed when returning from ChatDetailPage
              loadChats();
            });
          },
        );
      },
    );
  }

  @override
  void dispose() {
    // Make sure to cancel any active listeners
    messageController.dispose();
    super.dispose();
  }
}
