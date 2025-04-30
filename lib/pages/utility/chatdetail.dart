// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:sportify_final/pages/utility/chatservice.dart';

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
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.photo,
                    label: 'Photo',
                    onTap: () {
                      // Implement photo sharing
                      Navigator.pop(context);
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      // Implement camera
                      Navigator.pop(context);
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.insert_drive_file,
                    label: 'Document',
                    onTap: () {
                      // Implement document sharing
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              icon,
              size: 30,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
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
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: const Text('Clear chat history'),
                onTap: () {
                  Navigator.pop(context);
                  _showClearChatConfirmation();
                },
              ),
              if (!widget.isGroup)
                ListTile(
                  leading: Icon(Icons.block, color: Colors.orange),
                  title: const Text('Block user'),
                  onTap: () {
                    Navigator.pop(context);
                    _showBlockUserConfirmation();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showAddMembersDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Members'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('users').get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return StatefulBuilder(
                  builder: (context, setState) {
                    // Get current chat participants
                    List<String> selectedUsers = [];

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              var userDoc = snapshot.data!.docs[index];
                              var userData =
                                  userDoc.data() as Map<String, dynamic>;
                              var userId = userDoc.id;

                              // Skip current user
                              if (userId == currentUserId) return Container();

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
                                title: Text(userData['name'] ?? 'Unknown User'),
                                secondary: CircleAvatar(
                                  backgroundImage: userData['photoUrl'] !=
                                              null &&
                                          userData['photoUrl'].isNotEmpty
                                      ? NetworkImage(userData['photoUrl'])
                                      : const AssetImage("assets/profile.png")
                                          as ImageProvider,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
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
            TextButton(
              onPressed: () {
                // Get the list of selected users and add them to the group
                Navigator.pop(context);
                // _addMembersToGroup(selectedUsers);
              },
              child: const Text('Add'),
            ),
          ],
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

  void _showClearChatConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Chat History'),
          content: const Text(
              'Are you sure you want to clear all messages? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _clearChatHistory();
              },
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _clearChatHistory() async {
    try {
      // Get all messages
      QuerySnapshot messagesSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .get();

      // Delete each message
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Update chat document
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'lastMessage': 'No messages',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat history cleared')),
      );
    } catch (e) {
      print('Error clearing chat history: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear chat history: $e')),
      );
    }
  }

  void _showBlockUserConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Block User'),
          content: const Text(
              'Are you sure you want to block this user? You will no longer receive messages from them.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _blockUser();
              },
              child: const Text('Block', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _blockUser() async {
    try {
      // Get other user ID
      DocumentSnapshot chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();

      if (chatDoc.exists) {
        Map<String, dynamic> chatData = chatDoc.data() as Map<String, dynamic>;
        List<dynamic> participants = chatData['participants'] ?? [];

        String otherUserId = participants
            .firstWhere((id) => id != currentUserId, orElse: () => '');

        if (otherUserId.isNotEmpty) {
          // Add to blocked users collection
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .collection('blocked')
              .doc(otherUserId)
              .set({
            'blockedAt': FieldValue.serverTimestamp(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User blocked')),
          );

          // Go back to chat list
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('Error blocking user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to block user: $e')),
      );
    }
  }
}
