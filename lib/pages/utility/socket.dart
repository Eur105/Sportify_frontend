import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:sportify_final/pages/utility/api_constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;
  String? userUUID;
  final ValueNotifier<List<Map<String, dynamic>>> gameRequests =
      ValueNotifier([]);

  // Add a stream controller for notifications
  final ValueNotifier<Map<String, dynamic>?> notificationStream =
      ValueNotifier(null);

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    print("Initializing SocketService");
    await _loadUserUUID();
    _initializeSocket();

    // Fetch requests on initialization
    if (userUUID != null && userUUID!.isNotEmpty) {
      await fetchGameRequests();
    }

    _isInitialized = true;
  }

  Future<void> _loadUserUUID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userUUID = prefs.getString("userUuid") ?? "";
    print("Loaded user UUID: $userUUID");
  }

  void _initializeSocket() {
    socket = IO.io("${ApiConstants.baseUrl}:5000/game", <String, dynamic>{
      "transports": ["websocket"],
      "autoConnect": false,
    });

    socket!.connect();

    socket!.on("connect", (_) {
      print("Connected to game socket");
      if (userUUID != null && userUUID!.isNotEmpty) {
        socket!.emit("join", {"userId": userUUID});
      }
    });

    socket!.on("userJoinedGame", (data) {
      print("User joined game: $data");
      // Fetch game requests when user joins a game
      fetchGameRequests();
    });

    socket!.on("requestStatusUpdate", (data) {
      print("Request status update: $data");
      // Send notification to stream
      notificationStream.value = {"type": "requestStatusUpdate", "data": data};
    });

    socket!.on("requestStatusUpdate", (data) {
      print("Request status update received: $data");

      // Store the notification for display
      notificationStream.value = {"type": "requestStatusUpdate", "data": data};

      // Also update the game requests list by removing the processed request
      List<Map<String, dynamic>> updatedRequests =
          List.from(gameRequests.value);
      updatedRequests.removeWhere(
          (request) => request["requestUUID"] == data["requestId"]);
      gameRequests.value = updatedRequests;
    });

    socket!.on("newGameRequest", (data) {
      print("New game request received: $data");
      // Update the game requests list
      fetchGameRequests();

      // Notify about the new request
      notificationStream.value = {"type": "newGameRequest", "data": data};
    });

    socket!.on("disconnect", (_) {
      print("Disconnected from game socket");
    });
  }

  Future<void> fetchGameRequests() async {
    if (userUUID == null || userUUID!.isEmpty) {
      print("Cannot fetch game requests: User UUID is missing");
      return;
    }

    try {
      print("Fetching game requests for user: $userUUID");
      var url = Uri.parse(
          "${ApiConstants.baseUrl}:5000/api/game/getuserrequests/$userUUID");

      var response = await http.get(url);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse.containsKey("Requests")) {
          List<dynamic> fetchedRequests = jsonResponse["Requests"];

          List<Map<String, dynamic>> formattedRequests = fetchedRequests
              .where((request) => request["status"] == "pending")
              .map<Map<String, dynamic>>((request) {
            return {
              "requestUUID": request["uuid"],
              "role": request["role"],
              "gameId": request["gameId"],
              "requesteruuid": request["userId"],
              "firstName": request["Requester"]["firstName"],
              "lastName": request["Requester"]["lastName"]
            };
          }).toList();

          print(
              "Updated game requests: ${formattedRequests.length} pending requests");
          gameRequests.value = formattedRequests;
        } else {
          print("Unexpected API response format: $jsonResponse");
        }
      } else {
        print("API request failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching game requests: $e");
    }
  }

  void disconnect() {
    socket?.disconnect();
  }

  void emitApproveRejectRequest(String requestId, String status) {
    print("Emitting approveRejectRequest: $requestId, status: $status");
    socket?.emit("approveRejectRequest", {
      "requestId": requestId,
      "status": status,
    });
  }
}
