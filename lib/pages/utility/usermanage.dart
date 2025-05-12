// ignore_for_file: unused_import, unused_element, avoid_print

//import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserManager {
  //static final FirebaseAuth _auth = FirebaseAuth.instance;
  static String? currentUserId = "";

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    currentUserId = prefs.getString("userUuid");
    print("see uid in user manager page: $currentUserId");
    //loadChats(); // assuming "uuid" is the key
  }

  // Get current user data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(currentUserId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update user profile
  static Future<bool> updateUserProfile({
    String? name,
    String? photoUrl,
    String? bio,
  }) async {
    try {
      Map<String, dynamic> updateData = {};
      if (name != null) updateData['name'] = name;
      if (photoUrl != null) updateData['photoUrl'] = photoUrl;
      if (bio != null) updateData['bio'] = bio;

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .update(updateData);
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Get user data by ID
  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Get all users
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    List<Map<String, dynamic>> users = [];

    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();

      for (var doc in snapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        userData['id'] = doc.id;
        users.add(userData);
      }

      return users;
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  // Check if a user is blocked
  static Future<bool> isUserBlocked(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blocked')
          .doc(userId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking blocked status: $e');
      return false;
    }
  }

  // Block a user
  static Future<bool> blockUser(String userId) async {
    //if (!isLoggedIn) return false;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blocked')
          .doc(userId)
          .set({
        'blockedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error blocking user: $e');
      return false;
    }
  }

  // Unblock a user
  static Future<bool> unblockUser(String userId) async {
    //if (!isLoggedIn) return false;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blocked')
          .doc(userId)
          .delete();
      return true;
    } catch (e) {
      print('Error unblocking user: $e');
      return false;
    }
  }

  // Get blocked users
  static Future<List<String>> getBlockedUsers() async {
    //if (!isLoggedIn) return [];

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blocked')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error getting blocked users: $e');
      return [];
    }
  }

  // Update online status
  static Future<void> updateOnlineStatus(bool isOnline) async {
    // if (!isLoggedIn) return;

    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'isOnline': isOnline,
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating online status: $e');
    }
  }

  // Set up presence system (call this when app starts)
  static void setupPresence() {
    // Update status when app is in foreground
    updateOnlineStatus(true);

    // Add listener for when app goes to background or is closed
    // FirebaseAuth.instance.authStateChanges().listen((User? user) {
    //   if (user == null) {
    //     // User signed out, update status
    //     updateOnlineStatus(false);
    //   }
    // });
  }
}
