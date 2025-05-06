// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sportify_final/pages/utility/api_constants.dart';

class ViewUserGames extends StatefulWidget {
  const ViewUserGames({super.key});

  @override
  State<ViewUserGames> createState() => _ViewUserGamesState();
}

class _ViewUserGamesState extends State<ViewUserGames> {
  String? userEmail;
  List<Map<String, dynamic>> games = [];
  bool isLoading = true;
  String? userid;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userEmail = prefs.getString("email") ?? "";
    userid = prefs.getString("userUuid") ?? "";
    print(userid);
    if (userEmail!.isNotEmpty) {
      _fetchUserGames();
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchUserGames() async {
    try {
      var url =
          Uri.parse("${ApiConstants.baseUrl}/api/game/getusergames/$userEmail");
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse.containsKey('Games')) {
          setState(() {
            games = List<Map<String, dynamic>>.from(jsonResponse['Games']);
            isLoading = false;
          });
        }
      } else {
        print("Error fetching games: ${response.body}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _recordGameResult(
      String gameId, String score, String result) async {
    try {
      var url = Uri.parse("${ApiConstants.baseUrl}/api/game/recordgameresult");
      var response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "userId": userid,
            "gameId": gameId,
            "score": score,
            "result": result,
          }));

      if (response.statusCode == 200) {
        print("Game result recorded successfully");
      } else {
        print("Error recording game result: ${response.body}");
      }
    } catch (e) {
      print("Error recording game result: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Adjust breakpoint as needed

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Created Games",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : games.isEmpty
              ? Center(
                  child: Padding(
                    // Added padding for better readability
                    padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
                    child: Text(
                      "You have not created any games yet.",
                      style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey),
                      textAlign: TextAlign.center, // Center text horizontally
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(
                      vertical:
                          isSmallScreen ? 8.0 : 12.0), // Added vertical padding
                  itemCount: games.length,
                  itemBuilder: (context, index) {
                    final game = games[index];
                    return Padding(
                      // Added padding around each GameCard
                      padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8.0 : 12.0,
                          vertical: isSmallScreen ? 4.0 : 6.0),
                      child: GameCard(
                        game: game,
                        userId: userid,
                        recordGameResult: _recordGameResult,
                      ),
                    );
                  },
                ),
    );
  }
}

class GameCard extends StatelessWidget {
  final Map<String, dynamic> game;
  final String? userId;
  final Future<void> Function(String gameId, String score, String result)
      recordGameResult;

  const GameCard({
    super.key,
    required this.game,
    required this.userId,
    required this.recordGameResult,
  });

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return "N/A";
    try {
      final parsedDate = DateTime.parse(rawDate);
      return DateFormat('dd MMM yyyy').format(parsedDate);
    } catch (e) {
      return "Invalid Date";
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  void _showFeedbackDialog(BuildContext context, String gameId) {
    TextEditingController scoreController = TextEditingController();
    String result = "Win";
    String experience = "Good";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Give Feedback"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: result,
              items: ["Win", "Loss", "Draw"]
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ))
                  .toList(),
              onChanged: (newValue) => result = newValue!,
              decoration: const InputDecoration(
                  labelText: "Did you win, lose or Draw?"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: scoreController,
              decoration: const InputDecoration(labelText: "Score"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: experience,
              items: ["Good", "Average", "Bad"]
                  .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ))
                  .toList(),
              onChanged: (newValue) => experience = newValue!,
              decoration:
                  const InputDecoration(labelText: "How was the experience?"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              recordGameResult(gameId, scoreController.text, result);
              Navigator.pop(context);
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  void _confirmCancelGame(BuildContext context, String gameId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Game"),
        content: const Text("Are you sure you want to cancel this game?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelGame(context, gameId);
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelGame(BuildContext context, String gameId) async {
    try {
      final response = await http.delete(
        Uri.parse("${ApiConstants.baseUrl}/api/game/cancelgame/$gameId"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"userId": userId}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Game cancelled successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to cancel game: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = game["gameStatus"] ?? "Pending";
    final venue = game["venueName"] ?? "Unknown Venue";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      shadowColor: Colors.black45,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game title + status
            Row(
              children: [
                const Icon(Icons.sports_soccer,
                    size: 26, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    game["gameName"] ?? "Unknown Game",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey[300]),

            // Game date
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text("Date: ${_formatDate(game["gameDate"])}"),
              ],
            ),
            const SizedBox(height: 6),

            // Game time
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text("Time: ${game["gameTime"] ?? "N/A"}"),
              ],
            ),
            const SizedBox(height: 6),

            // Venue
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    "Venue: $venue",
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: Colors.grey[300]),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showFeedbackDialog(context, game['uuid']),
                  icon: const Icon(Icons.feedback_outlined,
                      size: 18, color: Colors.black),
                  label: const Text(
                    "Feedback",
                    style: TextStyle(color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _confirmCancelGame(context, game['uuid']),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text("Cancel"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.shade200,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
