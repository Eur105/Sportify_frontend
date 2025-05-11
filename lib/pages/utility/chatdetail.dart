// ignore_for_file: unused_import, unused_element, unused_local_variable, use_build_context_synchronously

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportify_final/pages/utility/chatservice.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
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
  String? otherUserId;
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isUploading = false;

  static Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    currentUserId = prefs.getString("userUuid");
    print("see uid in chatdetail page: $currentUserId");
    //loadChats(); // assuming "uuid" is the key
  }

  Future<String?> _getOtherUserId() async {
    final chatDoc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .get();
    final List participants = chatDoc['participants'];
    return participants.firstWhere((id) => id != currentUserId);
  }

  Future<DocumentSnapshot> _getOtherUserData() async {
    otherUserId ??= await _getOtherUserId();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(otherUserId)
        .get();
  }

  Future<void> _reloadCount() async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'unreadCounts.$currentUserId':
            0, // Update the unread count for the current user
      });
      print("Unread count reset to zero for current user.");
    } catch (e) {
      print('Error resetting unread count: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    _loadUserId();
    _reloadCount();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.isGroup
            ? Row(
                children: [
                  const Icon(Icons.group),
                  const SizedBox(width: 10),
                  Text(widget.chatName),
                ],
              )
            : FutureBuilder<DocumentSnapshot>(
                future: _getOtherUserData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text("Loading...");
                  } else if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text("Unknown User");
                  } else {
                    final userData = snapshot.data!;
                    final name = userData['name'] ?? 'User';
                    final photoUrl = userData['photoUrl'] ?? '';

                    return Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : const AssetImage("assets/default_avatar.png")
                                  as ImageProvider,
                        ),
                        const SizedBox(width: 10),
                        Text(name),
                      ],
                    );
                  }
                },
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
                      fileUrl: message['fileUrl'],
                      fileType: message['fileType'],
                      fileName: message['fileName'],
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

      final messageText = _messageController.text;

      // Clear input field immediately
      _messageController.clear();

      // Add message to Firestore
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add(messageData);

      // Fetch the chat document to get participant IDs
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();

      final chatData = chatDoc.data() as Map<String, dynamic>;
      final List<dynamic> participants = chatData['participants'] ?? [];

      // Build update map for unreadCounts
      Map<String, dynamic> unreadUpdates = {};

      for (var userId in participants) {
        if (userId != currentUserId) {
          unreadUpdates['unreadCounts.$userId'] = FieldValue.increment(1);
        }
      }

      // Update last message and unreadCounts in chat document
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'lastMessage': messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        ...unreadUpdates,
      });

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
            .update({
          'unreadCounts.${currentUserId}': 0,
        });
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
      return 'Admin';
    } catch (e) {
      print('Error getting sender name: $e');
      return 'Unknown User';
    }
  }

  Widget _buildMessageBubble({
    required String message,
    required bool isMe,
    required dynamic timestamp,
    Future<String>? senderNameFuture,
    String? fileUrl,
    String? fileType,
    String? fileName,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.green[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show sender name if it's a group chat and not the current user's message
            if (senderNameFuture != null)
              FutureBuilder<String>(
                future: senderNameFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text('Loading...',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12));
                  }
                  return Text(snapshot.data ?? 'Unknown',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12));
                },
              ),

            // Display image attachment if exists
            if (fileUrl != null && fileType == 'image')
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  fileUrl,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Display file attachment if exists
            if (fileUrl != null && fileType == 'file')
              InkWell(
                onTap: () {
                  // Launch file URL
                  // launch(fileUrl);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.insert_drive_file),
                    const SizedBox(width: 8),
                    Text(
                      fileName ?? 'File',
                      style: TextStyle(
                        color: Colors.blue[800],
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),

            // Display text message if exists
            if (message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(message),
              ),

            // Display timestamp
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                timestamp != null
                    ? DateFormat.jm().format(timestamp.toDate())
                    : '',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
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
                    onTap: () async {
                      final ImagePicker _picker = ImagePicker();
                      // Pick an image from gallery
                      final XFile? image =
                          await _picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        Navigator.pop(context); // Close the dialog first

                        // Upload the image to Supabase
                        final fileUrl = await _uploadFileToSupabase(
                          File(image.path),
                          'image',
                        );

                        // Send the image message
                        if (fileUrl != null) {
                          await _sendAttachmentMessage(fileUrl, 'image');
                        }
                      }
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
                        Navigator.pop(context); // Close the dialog first

                        // Upload the image to Supabase
                        final fileUrl = await _uploadFileToSupabase(
                          File(image.path),
                          'image',
                        );

                        // Send the image message
                        if (fileUrl != null) {
                          await _sendAttachmentMessage(fileUrl, 'image');
                        }
                      }
                    },
                  ),
                  // _buildAttachmentOption(
                  //   icon: Icons.insert_drive_file,
                  //   label: 'File',
                  //   onTap: () async {
                  //     // You'll need to add file_picker package for this
                  //     // import 'package:file_picker/file_picker.dart';

                  //     // FilePickerResult? result = await FilePicker.platform.pickFiles();
                  //     // if (result != null) {
                  //     //   Navigator.pop(context); // Close the dialog first
                  //     //
                  //     //   File file = File(result.files.single.path!);
                  //     //
                  //     //   // Upload the file to Supabase
                  //     //   final fileUrl = await _uploadFileToSupabase(
                  //     //     file,
                  //     //     'file',
                  //     //   );
                  //     //
                  //     //   // Send the file message
                  //     //   if (fileUrl != null) {
                  //     //     await _sendAttachmentMessage(fileUrl, 'file');
                  //     //   }
                  //     // }

                  //     // For now, just close the dialog
                  //     Navigator.pop(context);
                  //   },
                  // ),
                ],
              ),
              // Show loading indicator when uploading
              if (_isUploading)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: CircularProgressIndicator(),
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
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blue[800]),
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
                      _removeMemberFromGroup(memberId, currentUserId!);
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
  Future<void> _removeMemberFromGroup(
      String memberId, String currentUserId) async {
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

      String userName = "unknown user";
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        userName = userData['name'] ?? 'unknown User';
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
            void filterUsers(String query) async {
              if (query.isEmpty) {
                setState(() {
                  filteredUsers = [];
                });
                return;
              }

              QuerySnapshot snapshot = await FirebaseFirestore.instance
                  .collection('users')
                  .get(); // Load all users first

              List<QueryDocumentSnapshot> results = [];

              for (var doc in snapshot.docs) {
                final userData = doc.data() as Map<String, dynamic>;
                final userId = doc.id;
                final userName = userData['userName']?.toLowerCase() ?? '';

                if (userName.contains(query.toLowerCase()) &&
                    !currentParticipants.contains(userId) &&
                    userId != currentUserId) {
                  results.add(doc);
                }
              }

              setState(() {
                filteredUsers = results;
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
                        hintText: 'Search by user name',
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
                          var userName = userData['userName'] ?? 'Unknown User';

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

  Future<String?> _uploadFileToSupabase(File file, String fileType) async {
    try {
      setState(() {
        _isUploading = true;
      });

      // Generate a unique file name to prevent collisions
      final String fileName =
          '${const Uuid().v4()}${path.extension(file.path)}';

      // Define storage bucket based on file type
      final String bucket = fileType == 'image' ? 'chatimages' : 'chat_files';

      // Upload the file to Supabase Storage
      final response = await _supabase.storage
          .from(bucket) // Make sure you're using the correct bucket variable
          .upload('uploads/$fileName', file);

      // Get the public URL for the uploaded file
      final String fileUrl =
          _supabase.storage.from(bucket).getPublicUrl('uploads/$fileName');

      setState(() {
        _isUploading = false;
      });

      print('File uploaded successfully: $fileUrl');
      return fileUrl;
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading file: ${e.toString()}')),
      );
      print('Error uploading file: $e');
      return null;
    }
  }

  Future<void> _sendAttachmentMessage(String fileUrl, String fileType) async {
    try {
      // Create message data for Firebase (not Supabase)
      final messageData = {
        'senderId': currentUserId,
        'text': '', // Empty text for attachment-only messages
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'fileUrl': fileUrl,
        'fileType': fileType,
        'fileName':
            'Attachment', // You can improve this to get actual file name
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
        'lastMessage': fileType == 'image' ? '📷 Image' : '📎 File',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      // Scroll to bottom
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );

      print('Attachment message sent successfully');
    } catch (e) {
      print('Error sending attachment message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  Widget _buildMessageItem(Map<String, dynamic> message) {
    final bool isCurrentUser =
        message['user_id'] == _supabase.auth.currentUser?.id;
    final String? attachmentUrl = message['attachment_url'];
    final String? attachmentType = message['attachment_type'];

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentUser ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display attachment if exists
            if (attachmentUrl != null && attachmentType == 'image')
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  attachmentUrl,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            // Display file link if it's a file
            if (attachmentUrl != null && attachmentType == 'file')
              InkWell(
                onTap: () {
                  // Here you could use url_launcher to open the file
                  // launch(attachmentUrl);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.insert_drive_file),
                    const SizedBox(width: 8),
                    Text(
                      'Attachment',
                      style: TextStyle(
                        color: Colors.blue[800],
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            // Display text content if exists
            if (message['content'] != null && message['content'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(message['content']),
              ),
          ],
        ),
      ),
    );
  }
}
