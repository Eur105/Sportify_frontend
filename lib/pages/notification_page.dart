// ignore_for_file: library_prefixes, avoid_print, prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportify_final/pages/utility/api_constants.dart';
import 'package:sportify_final/pages/utility/socket.dart';
import 'package:sportify_final/pages/utility/view_profile.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final Color backgroundGrey = const Color(0xFFF5F5F5);
  final SocketService _socketService = SocketService();
  String? userid;

  @override
  void initState() {
    super.initState();

    // Make sure socket service is initialized
    if (_socketService.socket == null) {
      _socketService.initialize();
    }

    // Fetch requests immediately
    _loadUserEmail();

    // Listen for socket updates
    _socketService.notificationStream.addListener(_handleNotificationUpdate);
  }

  void _handleNotificationUpdate() {
    if (_socketService.notificationStream.value != null &&
        _socketService.notificationStream.value!["type"] ==
            "requestStatusUpdate") {
      _updateRequestStatus(_socketService.notificationStream.value!["data"]);
    }
  }

  Future<void> _loadUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //  userid = prefs.getString("email") ?? "";
    userid = prefs.getString("userUuid") ?? "";
    print(userid);
    if (userid!.isNotEmpty) {
      _fetchGameRequests();
    } else {
      //setState(() => isLoading = false);
    }
  }

  Future<void> _fetchGameRequests() async {
    if (userid == null) {
      print("Cannot fetch game requests: User UUID is missing");

      // Try to load UUID if not available
      // await _socketService._loadUserUUID();

      if (_socketService.userUUID == null || _socketService.userUUID!.isEmpty) {
        print("Still unable to get user UUID after reload attempt");
        return;
      }
    }

    try {
      print("Fetching game requests for user: ${userid}");
      var url = Uri.parse(
          "${ApiConstants.baseUrl}/api/game/getuserrequests/${userid}");

      var response = await http.get(url);
      print("API Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        print("API Response body: $jsonResponse");

        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse.containsKey("Requests")) {
          List<dynamic> fetchedRequests = jsonResponse["Requests"];
          print("Found ${fetchedRequests.length} requests");

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

          print("Pending requests: ${formattedRequests.length}");

          // Update both state variables to ensure UI updates
          setState(() {
            _socketService.gameRequests.value = formattedRequests;
          });
        } else {
          print("Unexpected API response format: $jsonResponse");
        }
      } else {
        print("Failed to fetch game requests: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (e) {
      print("Error fetching game requests: $e");
    }
  }

  Future<void> _respondToRequest(
      String requestUUID, String gameId, String isAccepted) async {
    print("Responding to request: $requestUUID with status: $isAccepted");
    var url = Uri.parse(
        "${ApiConstants.baseUrl}/api/game/approverequest/$requestUUID");

    try {
      var response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"status": isAccepted}),
      );

      if (response.statusCode == 200) {
        print("Request updated successfully");

        // Store the processed request
        SharedPreferences prefs = await SharedPreferences.getInstance();
        List<String> processedRequests =
            prefs.getStringList("processedRequests") ?? [];
        processedRequests.add(requestUUID);
        await prefs.setStringList("processedRequests", processedRequests);

        // Update local list and notify UI
        setState(() {
          var newList = List<Map<String, dynamic>>.from(
              _socketService.gameRequests.value);
          newList
              .removeWhere((request) => request["requestUUID"] == requestUUID);
          _socketService.gameRequests.value = newList;
        });

        // Emit the socket event
        _socketService.emitApproveRejectRequest(requestUUID, isAccepted);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAccepted == "approved"
                ? "Request Approved"
                : "Request Rejected"),
            backgroundColor:
                isAccepted == "approved" ? Colors.green : Colors.red,
          ),
        );
      } else {
        print("Failed to update request: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (e) {
      print("Error responding to request: $e");
    }
  }

  void _updateRequestStatus(dynamic data) {
    print("Updating request status with data: $data");
    setState(() {
      var newList =
          List<Map<String, dynamic>>.from(_socketService.gameRequests.value);
      newList.removeWhere(
          (request) => request["requestUUID"] == data["requestId"]);
      _socketService.gameRequests.value = newList;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: backgroundGrey,
        title: const Text(
          "Game Requests",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchGameRequests,
            tooltip: "Refresh Requests",
          ),
        ],
      ),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: _socketService.gameRequests,
        builder: (context, gameRequests, _) {
          print("Building UI with ${gameRequests.length} requests");

          if (gameRequests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "No game requests",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: Icon(Icons.refresh),
                    label: Text("Refresh"),
                    onPressed: _fetchGameRequests,
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: gameRequests.length,
            itemBuilder: (context, index) {
              final request = gameRequests[index];
              final String role = request['role'] ?? "Player";
              final String firstname = request['firstName'] ?? "Unknown";
              final String lastname = request['lastName'] ?? "Unknown";
              final String fullname = "$firstname $lastname";
              final String id = request['requesteruuid'];

              return Card(
                margin: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: Colors.black54,
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueAccent.withOpacity(0.2),
                        child: Icon(Icons.person, color: Colors.blueAccent),
                      ),
                      title: Text(
                        "$fullname has requested to join the game as a $role",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          const Text("New Request",
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Colors.grey),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon:
                                  const Icon(Icons.check, color: Colors.white),
                              label: const Text("Approve"),
                              onPressed: () {
                                _respondToRequest(request['requestUUID'] ?? "",
                                    request['gameId'] ?? "", "approved");
                              },
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                              label: const Text("Reject"),
                              onPressed: () {
                                _respondToRequest(request['requestUUID'] ?? "",
                                    request['gameId'] ?? "", "rejected");
                              },
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 4),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ViewProfile(viewedUserId: id),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(
                              colors: [Colors.blueAccent, Colors.blue],
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person, color: Colors.white),
                              const SizedBox(width: 8),
                              const Text(
                                "View Profile",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _socketService.notificationStream.removeListener(_handleNotificationUpdate);
    super.dispose();
  }
}
