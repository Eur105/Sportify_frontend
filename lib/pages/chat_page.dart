// ignore_for_file: unused_import, unused_element, avoid_print, collection_methods_unrelated_type, unused_local_variable

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportify_final/pages/notification_page.dart';
import 'package:sportify_final/pages/searching_panel/search_user.dart';
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
  late StreamSubscription<QuerySnapshot> chatSubscription;

  @override
  void initState() {
    super.initState();
    chatSubscription = _chatStream().listen((snapshot) {
      // Map snapshot to your dms list like in your loadChats()
      // and call setState()
    });
    UserManager.setupPresence();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    currentUserId = prefs.getString("userUuid");
    print("see uid in chatpage: $currentUserId");
    ChatService.hello(currentUserId!);
    print("sent uid in chatpage: $currentUserId");
    loadChats();

    // assuming "uuid" is the key
  }

  Future<void> loadChats() async {
    setState(() {
      isLoading = true;
    });
    // int unread = 0;

    try {
      // Get DMs using ChatService
      ChatService.getUserChats(isGroup: false, uid: currentUserId)
          .listen((snapshot) async {
        List<Map<String, dynamic>> tempDms = [];
        for (var doc in snapshot.docs) {
          var chatData = doc.data() as Map<String, dynamic>;

          int unread = chatData['unreadCounts']?[currentUserId] ?? 0;

          // Get other user ID
          String otherUserId = (chatData['participants'] as List)
              .firstWhere((id) => id != currentUserId, orElse: () => '');

          if (otherUserId.isNotEmpty) {
            // Get user data using UserManager
            print("participants: ${chatData['participants']}");
            var userData = await UserManager.getUserData(otherUserId);
            print("Other user id ok: $otherUserId");

            if (userData != null) {
              tempDms.add({
                'id': doc.id,
                'name': userData['name'] ?? 'Unknown User',
                'message': chatData['lastMessage'] ?? 'Start a conversation',
                'photoUrl': userData['photoUrl'] ?? '',
                'timestamp': chatData['lastMessageTime'],
                'unreadCount': unread
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

  Stream<QuerySnapshot> _chatStream() {
    final userId = currentUserId;
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

      // Initialize unreadCounts map
      Map<String, int> unreadCounts = {
        currentUserId!: 0,
        otherUserId: 0,
      };

      // Create a new chat
      DocumentReference chatRef =
          await FirebaseFirestore.instance.collection('chats').add({
        'type': 'direct',
        'participants': [currentUserId, otherUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessage': 'New conversation started',
        'unreadCounts': unreadCounts,
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
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: groupNameController,
                      decoration: const InputDecoration(
                        labelText: 'Group Name',
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('Select members:'),
                    const SizedBox(height: 10),
                    // 👇 Fetch users from database or service
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: UserManager
                          .getAllUsers(), // Replace with your actual method
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return const Text('Error loading users');
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Text('No users found');
                        }

                        final users = snapshot.data!
                            .where((user) => user['id'] != currentUserId)
                            .toList();

                        return SizedBox(
                          height: 200,
                          width: double.maxFinite,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              final isSelected =
                                  selectedUsers.contains(user['id']);

                              return CheckboxListTile(
                                title: Text(user['name'] ?? 'No Name'),
                                secondary: CircleAvatar(
                                  backgroundImage:
                                      FileImage(File(user['photoUrl'] ?? '')),
                                ),
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedUsers.add(user['id']);
                                    } else {
                                      selectedUsers.remove(user['id']);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (groupNameController.text.isNotEmpty &&
                        selectedUsers.isNotEmpty) {
                      createNewGroup(groupNameController.text,
                          [...selectedUsers, currentUserId!]);

                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Please enter a group name and select members')),
                      );
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
                            backgroundImage: userData["photoUrl"] != null &&
                                    userData["photoUrl"].toString().isNotEmpty
                                ? FileImage(File(userData["photoUrl"]))
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
            icon: const Icon(Icons.search),
            onPressed: () {
              // Navigate to the search page (previously in the search bar)
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SearchUsersPage()),
              ).then((_) {
                // Refresh chats when returning
                loadChats();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
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

          // 🟠 Removed Search TextField from here

          SizedBox(height: isSmallScreen ? 8 : 10), // Responsive spacing
          Expanded(
            child: isLoading
                ? const Center(child: Text("No chats yet"))
                : _buildChatList(showDms ? dms : groups),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (showDms) {
            _showNewChatDialog();
          } else {
            _showCreateGroupDialog();
          }
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
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
            FutureBuilder<bool>(
              future: Future.delayed(const Duration(seconds: 2), () => true),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  return const Text(
                    "No chats yet!",
                    style: TextStyle(fontSize: 16),
                  );
                }
              },
            ),
            const SizedBox(height: 10),
            // ElevatedButton(
            //   onPressed: () {
            //     if (showDms) {
            //       _showNewChatDialog();
            //     } else {
            //       _showCreateGroupDialog();
            //     }
            //   },
            //   child: Text(showDms ? "Start a new chat" : "Create a group"),
            // ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: chatData.length,
      itemBuilder: (context, index) {
        // First, check if the chat document exists in Firestore
        return FutureBuilder<bool>(
            future: _checkChatExists(chatData[index]["id"]),
            builder: (context, snapshot) {
              // If the chat doesn't exist, don't show anything
              if (snapshot.data == false) {
                return const SizedBox.shrink();
              }

              // If the chat exists, show the ListTile
              if (showDms) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: CircleAvatar(
                      backgroundImage: chatData[index]["photoUrl"] != null &&
                              chatData[index]["photoUrl"].isNotEmpty
                          ? FileImage(File(chatData[index]["photoUrl"]))
                          : const AssetImage("assets/profile.png")
                              as ImageProvider,
                    ),
                  ),
                  title: Text(chatData[index]["name"] ?? ""),
                  subtitle: Text(chatData[index]["message"] ?? ""),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (chatData[index]['unreadCount'] > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.red,
                            child: Text(
                              '${chatData[index]['unreadCount']}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
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
                          isGroup: !showDms,
                        ),
                      ),
                    ).then((_) {
                      loadChats();
                    });
                  },
                  isThreeLine: true,
                );
              } else {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: CircleAvatar(
                      backgroundImage: chatData[index]["photoUrl"] != null &&
                              chatData[index]["photoUrl"].isNotEmpty
                          ? FileImage(File(chatData[index]["photoUrl"]))
                          : const AssetImage("assets/profile.png")
                              as ImageProvider,
                    ),
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
                          isGroup: !showDms,
                        ),
                      ),
                    ).then((_) {
                      loadChats();
                    });
                  },
                  isThreeLine: true,
                );
              }
            });
      },
    );
  }

  // Add this function to your class
  Future<bool> _checkChatExists(String chatId) async {
    try {
      // Get a reference to the chat document
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();

      // Return true if the document exists
      return chatDoc.exists;
    } catch (e) {
      print('Error checking if chat exists: $e');
      // Return false if there was an error
      return false;
    }
  }

  @override
  void dispose() {
    // Make sure to cancel any active listeners
    messageController.dispose();
    chatSubscription.cancel();
    super.dispose();
  }
}
