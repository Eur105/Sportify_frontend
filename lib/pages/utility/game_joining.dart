import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:sportify_final/pages/utility/api_constants.dart';

class GameJoiningPage extends StatelessWidget {
  final Map<String, String> gameDetails;
  final Color backgroundGrey = const Color(0xFFF5F5F5);
  final String role; // Either "Player" or "Opponent"
  final String uuid; // Game UUID

  const GameJoiningPage({
    Key? key,
    required this.gameDetails,
    required this.role,
    required this.uuid,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Adjust breakpoint as needed

    return Scaffold(
      backgroundColor: backgroundGrey,
      appBar: AppBar(
        title: const Text(
          "Game Details",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding:
            EdgeInsets.all(isSmallScreen ? 12.0 : 16.0), // Responsive padding
        child: Column(
          children: [
            _buildHeaderCard(),
            SizedBox(height: isSmallScreen ? 15 : 20), // Responsive spacing
            _buildDetailCard(),
            SizedBox(height: isSmallScreen ? 20 : 30), // Responsive spacing
            _buildJoinButton(context),
          ],
        ),
      ),
    );
  }

  /// Builds the Header Card with role information
  Widget _buildHeaderCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: Colors.green,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Icon(Icons.sports, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "You're Joining as a $role",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the game details in a visually appealing card
  Widget _buildDetailCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDetailRow(Icons.sports_soccer, "Sport Type",
                gameDetails["sportType"] ?? "Unknown"),
            _buildDetailRow(
                Icons.person, "Host", gameDetails["fullName"] ?? "Unknown"),
            _buildDetailRow(Icons.location_on, "Venue",
                gameDetails["venueName"] ?? "Unknown"),
            _buildDetailRow(Icons.calendar_today, "Date",
                gameDetails["gameDate"] ?? "Unknown"),
            _buildDetailRow(Icons.access_time, "Time",
                gameDetails["gameTime"] ?? "Unknown"),
          ],
        ),
      ),
    );
  }

  /// Builds the join button
  Widget _buildJoinButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _requestToJoinGame(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sports_handball, color: Colors.white, size: 22),
          SizedBox(width: 8),
          Text(
            "Request To Join",
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper function to display each detail row with an icon
  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Function to request to join a game
  Future<void> _requestToJoinGame(BuildContext context) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userUuid = prefs.getString('userUuid'); // Get user UUID

      if (userUuid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User UUID not found.')),
        );
        return;
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/api/game/joingame');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userUuid,
          'gameId': uuid,
          'role': role,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request sent successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Request failed.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
