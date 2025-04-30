// ignore_for_file: prefer_conditional_assignment, unnecessary_null_comparison, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  // String? currentId;
  static String currentUserId = "";

  static String hello(String id) {
    currentUserId = id;
    print("currenttt: $currentUserId");
    return currentUserId;
  }

  //static String get currentUserId => _auth.currentUser?.uid ?? '';

  // Future<String?> _loadUserId() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();

  //   currentUserId = prefs.getString("userUuid"); // assuming "uuid" is the key
  //   return currentUserId;
  // }

  // Get all chats for current user
  static Stream<QuerySnapshot> getUserChats(
      {bool isGroup = false, String? uid}) {
    return _firestore
        .collection('chats')
        .where('type', isEqualTo: isGroup ? 'group' : 'direct')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Get messages for a specific chat
  static Stream<QuerySnapshot> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  // Send a text message
  static Future<bool> sendMessage(String chatId, String text) async {
    try {
      // Create message data
      final messageData = {
        'senderId': currentUserId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'type': 'text',
      };

      // Add message to subcollection
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      // Update the last message in the chat document
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  // Send an image message
  static Future<bool> sendImageMessage(String chatId, File imageFile) async {
    try {
      // Upload image to Firebase Storage
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${currentUserId}.jpg';
      Reference storageRef =
          _storage.ref().child('chat_images/$chatId/$fileName');

      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;

      // Get download URL
      String imageUrl = await taskSnapshot.ref.getDownloadURL();

      // Create message data
      final messageData = {
        'senderId': currentUserId,
        'text': 'Image',
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'type': 'image',
      };

      // Add message to subcollection
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      // Update the last message in the chat document
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': 'Image',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error sending image message: $e');
      return false;
    }
  }

  // Create a new direct chat
  static Future<String?> createDirectChat(String otherUserId) async {
    try {
      // Check if chat already exists
      QuerySnapshot existingChats = await _firestore
          .collection('chats')
          .where('type', isEqualTo: 'direct')
          .where('participants', arrayContains: currentUserId)
          .get();

      for (var doc in existingChats.docs) {
        // Get the data safely
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

        // Check if data is not null before accessing the participants
        if (data != null && data.containsKey('participants')) {
          List<dynamic> participants = data['participants'];
          if (participants.contains(otherUserId)) {
            // Chat already exists
            return doc.id;
          }
        }
      }

      // Create new chat
      DocumentReference chatRef = await _firestore.collection('chats').add({
        'type': 'direct',
        'participants': [currentUserId, otherUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessage': 'New conversation started',
      });

      return chatRef.id;
    } catch (e) {
      print('Error creating direct chat: $e');
      return null;
    }
  }

  // Create a new group chat
  static Future<String?> createGroupChat(
      String groupName, List<String> memberIds) async {
    try {
      // Ensure current user is included
      if (!memberIds.contains(currentUserId)) {
        memberIds.add(currentUserId);
      }

      // Create new group chat
      DocumentReference chatRef = await _firestore.collection('chats').add({
        'type': 'group',
        'name': groupName,
        'participants': memberIds,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessage': 'Group created',
        'createdBy': currentUserId,
      });

      // Add system message
      await _firestore
          .collection('chats')
          .doc(chatRef.id)
          .collection('messages')
          .add({
        'senderId': 'system',
        'text': 'Group created by ${await _getUserName(currentUserId)}',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'type': 'system',
      });

      return chatRef.id;
    } catch (e) {
      print('Error creating group chat: $e');
      return null;
    }
  }

  // Add members to a group
  // Add members to a group
  static Future<bool> addMembersToGroup(
      String chatId, List<String> newMemberIds) async {
    try {
      // Get current members
      DocumentSnapshot chatDoc =
          await _firestore.collection('chats').doc(chatId).get();

      if (chatDoc.exists) {
        Map<String, dynamic> chatData = chatDoc.data() as Map<String, dynamic>;

        // Check if it's a group chat
        if (chatData['type'] != 'group') {
          return false;
        }

        // Check if 'participants' is not null and is a list
        List<dynamic> currentParticipants = chatData['participants'] ?? [];

        // If participants is null or not present, initialize it as an empty list
        if (currentParticipants == null) {
          currentParticipants = [];
        }

        List<String> addedMembers = [];

        // Add new members
        for (String userId in newMemberIds) {
          if (!currentParticipants.contains(userId)) {
            currentParticipants.add(userId);
            addedMembers.add(userId);
          }
        }

        if (addedMembers.isEmpty) {
          return false; // No new members to add
        }

        // Update chat document
        await _firestore.collection('chats').doc(chatId).update({
          'participants': currentParticipants,
        });

        // Add system message
        List<String> addedNames = [];
        for (String userId in addedMembers) {
          String name = await _getUserName(userId);
          addedNames.add(name);
        }

        String addedMembersText = addedNames.join(', ');
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .add({
          'senderId': 'system',
          'text': '$addedMembersText added to the group',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'type': 'system',
        });

        return true;
      }

      return false;
    } catch (e) {
      print('Error adding members to group: $e');
      return false;
    }
  }

  // Remove a member from a group
  static Future<bool> removeMemberFromGroup(
      String chatId, String memberId) async {
    try {
      // Get current members
      DocumentSnapshot chatDoc =
          await _firestore.collection('chats').doc(chatId).get();

      if (chatDoc.exists) {
        Map<String, dynamic> chatData = chatDoc.data() as Map<String, dynamic>;

        // Check if it's a group chat
        if (chatData['type'] != 'group') {
          return false;
        }

        List<dynamic> currentParticipants = chatData['participants'] ?? [];

        // Remove member
        if (currentParticipants.contains(memberId)) {
          currentParticipants.remove(memberId);

          // Update chat document
          await _firestore.collection('chats').doc(chatId).update({
            'participants': currentParticipants,
          });

          // Add system message
          String name = await _getUserName(memberId);
          await _firestore
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .add({
            'senderId': 'system',
            'text': '$name removed from the group',
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
            'type': 'system',
          });

          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error removing member from group: $e');
      return false;
    }
  }

  // Leave a group
  static Future<bool> leaveGroup(String chatId) async {
    try {
      return await removeMemberFromGroup(chatId, currentUserId);
    } catch (e) {
      print('Error leaving group: $e');
      return false;
    }
  }

  // Delete a chat
  static Future<bool> deleteChat(String chatId) async {
    try {
      // Delete all messages
      QuerySnapshot messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete chat document
      batch.delete(_firestore.collection('chats').doc(chatId));

      await batch.commit();
      return true;
    } catch (e) {
      print('Error deleting chat: $e');
      return false;
    }
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead(String chatId) async {
    try {
      QuerySnapshot unreadMessages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .where('read', isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Helper method to get user name
  static Future<String> _getUserName(String userId) async {
    try {
      if (userId == 'system') return 'System';

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['name'] ?? 'Unknown User';
      }

      return 'Unknown User';
    } catch (e) {
      print('Error getting user name: $e');
      return 'Unknown User';
    }
  }
}
