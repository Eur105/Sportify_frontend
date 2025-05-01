import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportify_final/pages/utility/chatservice.dart';
import 'package:image_picker/image_picker.dart';
//import 'package:file_picker/file_picker.dart';

class ChatDetailPage extends StatefulWidget {
  final String chatId;
  final String chatName;
  final bool isGroup;

  const ChatDetailPage({
    Key? key,
    required this.chatId,
    required this.chatName,
    this.isGroup = false,
  }) : super(key: key);

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  static String? currentUserId = "";
  XFile? selectedImage;

  static Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    currentUserId = prefs.getString("userUuid");
    print("see uid in chatdetail page: $currentUserId");
    //loadChats(); // assuming "uuid" is the key
  }

  @override
  void initState() {
    super.initState();

    _loadUserId();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: const AssetImage("assets/picture.png"),
            ),
            const SizedBox(width: 10),
            Text(widget.chatName),
          ],
        ),
        actions: [
          if (widget.isGroup)
            IconButton(
              icon: const Icon(Icons.group),
              onPressed: () {
                // Show group members
                _showGroupMembers();
              },
            ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show more options
              _showOptions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .limit(100)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Start a conversation!'),
                  );
                }

                var messages = snapshot.data!.docs;

                // Mark messages as read
                _markMessagesAsRead(messages);

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message =
                        messages[index].data() as Map<String, dynamic>;
                    bool isMe = message['senderId'] == currentUserId;

                    return _buildMessageBubble(
                      message: message['text'] ?? '',
                      isMe: isMe,
                      timestamp: message['timestamp'],
                      senderNameFuture: widget.isGroup && !isMe
                          ? _getSenderName(message['senderId'])
                          : null,
                    );
                  },
                );
              },
            ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () {
                    // Implement file attachment
                    _showAttachmentOptions();
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                      border: InputBorder.none,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      // Create message data
      final messageData = {
        'senderId': currentUserId,
        'text': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      };

      // Add message to Firestore
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add(messageData);

      // Update last message in chat document
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'lastMessage': _messageController.text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      // Clear input field
      _messageController.clear();

      // Scroll to bottom
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  void _markMessagesAsRead(List<QueryDocumentSnapshot> messages) async {
    for (var message in messages) {
      var messageData = message.data() as Map<String, dynamic>;
      if (messageData['senderId'] != currentUserId &&
          messageData['read'] == false) {
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatId)
            .collection('messages')
            .doc(message.id)
            .update({'read': true});
      }
    }
  }

  Future<String> _getSenderName(String senderId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['name'] ?? 'Unknown User';
      }
      return 'Unknown User';
    } catch (e) {
      print('Error getting sender name: $e');
      return 'Unknown User';
    }
  }

  Widget _buildMessageBubble({
    required String message,
    required bool isMe,
    Timestamp? timestamp,
    Future<String>? senderNameFuture, // Changed from String? to Future<String>?
  }) {
    final time =
        timestamp != null ? DateFormat('HH:mm').format(timestamp.toDate()) : '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isMe ? Colors.green[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (senderNameFuture != null)
              FutureBuilder<String>(
                future: senderNameFuture,
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data ?? 'Loading...',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  );
                },
              ),
            Text(message),
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    XFile? selectedImage;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 180,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Share',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              // Add a variable to store the selected image file

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.photo,
                    label: 'Photo',
                    onTap: () async {
                      final ImagePicker _picker = ImagePicker();
                      // Pick an image from gallery
                      final XFile? image =
                          await _picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        // Store the selected image
                        setState(() {
                          selectedImage = image;
                        });
                      }
                      Navigator.pop(context); // Close the dialog
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () async {
                      final ImagePicker _picker = ImagePicker();
                      // Pick an image using the camera
                      final XFile? image =
                          await _picker.pickImage(source: ImageSource.camera);
                      if (image != null) {
                        // Store the captured image
                        setState(() {
                          selectedImage = image;
                        });
                      }
                      Navigator.pop(context); // Close the dialog
                    },
                  ),
                ],
              ),

// Display the selected image if available
              if (selectedImage != null) Image.file(File(selectedImage!.path)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30),
          const SizedBox(height: 5),
          Text(label),
        ],
      ),
    );
  }

  void _showGroupMembers() async {
    try {
      DocumentSnapshot chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();

      if (chatDoc.exists) {
        Map<String, dynamic> chatData = chatDoc.data() as Map<String, dynamic>;
        List<dynamic> participants = chatData['participants'] ?? [];

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Group Members'),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getGroupMembersInfo(participants.cast<String>()),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        var member = snapshot.data![index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: member['photoUrl'] != null &&
                                    member['photoUrl'].isNotEmpty
                                ? NetworkImage(member['photoUrl'])
                                : const AssetImage("assets/profile.png")
                                    as ImageProvider,
                          ),
                          title: Text(member['name'] ?? 'Unknown User'),
                          subtitle: member['id'] == chatData['createdBy']
                              ? const Text('Admin')
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Error showing group members: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getGroupMembersInfo(
      List<String> memberIds) async {
    List<Map<String, dynamic>> members = [];

    for (String userId in memberIds) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          members.add({
            'id': userId,
            'name': userData['name'] ?? 'Unknown User',
            'photoUrl': userData['photoUrl'] ?? '',
          });
        } else {
          members.add({
            'id': userId,
            'name': 'Unknown User',
            'photoUrl': '',
          });
        }
      } catch (e) {
        print('Error getting member info: $e');
      }
    }

    return members;
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Search in conversation'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement search functionality
                },
              ),
              if (widget.isGroup)
                ListTile(
                  leading: const Icon(Icons.person_add),
                  title: const Text('Add members'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddMembersDialog();
                  },
                ),
              if (widget.isGroup)
                ListTile(
                  leading: const Icon(Icons.person_remove, color: Colors.red),
                  title: const Text('Remove a member'),
                  onTap: () {
                    Navigator.pop(context);
                    _showRemoveMemberConfirmation();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showRemoveMemberConfirmation() async {
    try {
      // Get group data to check who's the admin
      DocumentSnapshot chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();

      if (!chatDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Group not found')),
        );
        return;
      }

      Map<String, dynamic> chatData = chatDoc.data() as Map<String, dynamic>;
      String createdBy = chatData['createdBy'] ?? '';
      List<dynamic> participants = chatData['participants'] ?? [];

      // Check if current user is admin
      if (createdBy != currentUserId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only the admin can remove members')),
        );
        return;
      }

      // Get members info for display
      List<Map<String, dynamic>> membersInfo =
          await _getGroupMembersInfo(participants.cast<String>());

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Remove Member'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: membersInfo.length,
                itemBuilder: (context, index) {
                  var member = membersInfo[index];
                  String memberId = member['id'];

                  // Don't show the current user (admin) in the list
                  if (memberId == currentUserId) return Container();

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: member['photoUrl'] != null &&
                              member['photoUrl'].isNotEmpty
                          ? NetworkImage(member['photoUrl'])
                          : const AssetImage("assets/profile.png")
                              as ImageProvider,
                    ),
                    title: Text(member['name'] ?? 'Unknown User'),
                    onTap: () {
                      Navigator.pop(context);
                      _removeMemberFromGroup(memberId);
                    },
                  );
                },
              ),
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
    } catch (e) {
      print('Error showing remove member dialog: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

// Now, let's implement the _removeMemberFromGroup function
  Future<void> _removeMemberFromGroup(String memberId) async {
    try {
      // Get the current list of participants
      DocumentSnapshot chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();

      if (!chatDoc.exists) return;

      Map<String, dynamic> chatData = chatDoc.data() as Map<String, dynamic>;
      List<dynamic> participants = List.from(chatData['participants'] ?? []);

      // Remove the member
      participants.remove(memberId);

      // Update the chat document
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'participants': participants,
      });

      // Add a system message
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .get();

      String userName = 'Unknown User';
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        userName = userData['name'] ?? 'Unknown User';
      }

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'senderId': 'system',
        'text': '$userName was removed from the group',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member removed successfully')),
      );
    } catch (e) {
      print('Error removing member: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove member: $e')),
      );
    }
  }

// Let's improve the add members dialog with search functionality
  void _showAddMembersDialog() async {
    TextEditingController searchController = TextEditingController();
    List<String> selectedUsers = [];
    List<QueryDocumentSnapshot> allUsers = [];
    List<QueryDocumentSnapshot> filteredUsers = [];

    // Get the current participants to exclude them
    DocumentSnapshot chatDoc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .get();

    List<String> currentParticipants = [];
    if (chatDoc.exists) {
      Map<String, dynamic> chatData = chatDoc.data() as Map<String, dynamic>;
      currentParticipants = List<String>.from(chatData['participants'] ?? []);
    }

    // Get all users
    QuerySnapshot usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();
    allUsers = usersSnapshot.docs;

    // Initial filtered list (exclude current participants)
    filteredUsers = allUsers.where((doc) {
      String userId = doc.id;
      return !currentParticipants.contains(userId) && userId != currentUserId;
    }).toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Filter function
            void filterUsers(String query) {
              setState(() {
                if (query.isEmpty) {
                  filteredUsers = allUsers.where((doc) {
                    String userId = doc.id;
                    return !currentParticipants.contains(userId) &&
                        userId != currentUserId;
                  }).toList();
                } else {
                  filteredUsers = allUsers.where((doc) {
                    String userId = doc.id;
                    if (currentParticipants.contains(userId) ||
                        userId == currentUserId) {
                      return false;
                    }

                    Map<String, dynamic> userData =
                        doc.data() as Map<String, dynamic>;
                    String userName = userData['name'] ?? '';
                    return userName.toLowerCase().contains(query.toLowerCase());
                  }).toList();
                }
              });
            }

            return AlertDialog(
              title: const Text('Add Members'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    // Search box
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search by name',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: filterUsers,
                    ),
                    const SizedBox(height: 10),
                    // User list
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          var userDoc = filteredUsers[index];
                          var userData = userDoc.data() as Map<String, dynamic>;
                          var userId = userDoc.id;
                          var userName = userData['name'] ?? 'Unknown User';

                          bool isSelected = selectedUsers.contains(userId);

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  selectedUsers.add(userId);
                                } else {
                                  selectedUsers.remove(userId);
                                }
                              });
                            },
                            title: Text(userName),
                            secondary: CircleAvatar(
                              backgroundImage: userData['photoUrl'] != null &&
                                      userData['photoUrl'].isNotEmpty
                                  ? NetworkImage(userData['photoUrl'])
                                  : const AssetImage("assets/profile.png")
                                      as ImageProvider,
                            ),
                          );
                        },
                      ),
                    ),
                    // Selected count
                    Text(
                      '${selectedUsers.length} users selected',
                      style: const TextStyle(fontStyle: FontStyle.italic),
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
                  onPressed: selectedUsers.isEmpty
                      ? null
                      : () {
                          Navigator.pop(context);
                          _addMembersToGroup(selectedUsers);
                        },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addMembersToGroup(List<String> newMemberIds) async {
    try {
      bool success =
          await ChatService.addMembersToGroup(widget.chatId, newMemberIds);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Members added successfully')),
        );
        // Optionally, you can refresh the UI or reload chat data if needed here
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No new members were added')),
        );
      }
    } catch (e) {
      print('Error adding members: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add members: $e')),
      );
    }
  }
}
