import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportify_final/pages/utility/api_constants.dart';
import 'dart:convert';
import 'package:sportify_final/pages/utility/view_profile.dart';

class ViewGameDetails extends StatefulWidget {
  final String? gameId;
  final Color backgroundGrey = const Color(0xFFF5F5F5);
  const ViewGameDetails({super.key, required this.gameId});

  @override
  State<ViewGameDetails> createState() => _ViewGameDetailsState();
}

class _ViewGameDetailsState extends State<ViewGameDetails> {
  Map<String, dynamic>? gameData;
  Map<String, dynamic>? hostData;
  List<dynamic>? joinedPlayers;
  String? currentUserId;
  Map<String, dynamic>? oppPlayers;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _fetchGameDetails();
    _fetchJoinedPlayers();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getString("userUuid"); // assuming "uuid" is the key
    });
  }

  Future<void> _fetchGameDetails() async {
    final url = Uri.parse(
        '${ApiConstants.baseUrl}:5000/api/game/getgame/${widget.gameId}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        gameData = data['Game'];
        hostData = data['Host'];
      });
    }
  }

  Future<void> _fetchJoinedPlayers() async {
    final url = Uri.parse(
        '${ApiConstants.baseUrl}:5000/api/game/getgameplayers/${widget.gameId}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        joinedPlayers = data['joinedPlayersData'];
        oppPlayers = data['opponentTeamData'];
      });
    }
  }

  Future<void> removePlayer(String playerId) async {
    final url = Uri.parse(
        "${ApiConstants.baseUrl}:5000/api/game/removeplayer/${widget.gameId}");
    final response = await http.delete(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"hostId": currentUserId, "playerId": playerId}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Player removed successfully")),
      );
      _fetchJoinedPlayers(); // Refresh the list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to remove player: ${response.body}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Adjust breakpoint as needed

    return Scaffold(
      backgroundColor: widget.backgroundGrey,
      appBar: AppBar(
        title: const Text(
          "Game Details",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: gameData == null || hostData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(
                  isSmallScreen ? 12.0 : 16.0), // Responsive padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHostCard(),
                  SizedBox(
                      height: isSmallScreen ? 15 : 20), // Responsive spacing
                  _buildGameDetailsCard(),
                  SizedBox(
                      height: isSmallScreen ? 15 : 20), // Responsive spacing
                  if (gameData!["hostTeamSize"] != 0) _buildJoinedPlayersList(),
                  if (oppPlayers != null) _buildOpponentTeam(),
                ],
              ),
            ),
    );
  }

  Widget _buildHostCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.green,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.green, size: 30),
              ),
              title: Text(
                "${hostData!["firstName"].toUpperCase()} ${hostData!["lastName"].toUpperCase()}",
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              // subtitle: Text(
              //   "Contact: ${hostData!["phoneNo"]}",
              //   style: const TextStyle(fontSize: 14, color: Colors.white70),
              // ),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ViewProfile(viewedUserId: hostData!["uuid"]),
                    ),
                  );
                },
                child: const Text("View Profile",
                    style: TextStyle(color: Colors.green)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameDetailsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Game Details",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),
            const Divider(),
            _buildDetailRow(
                Icons.sports_soccer, "Game Type", gameData!["sportType"]),
            _buildDetailRow(Icons.location_on, "Venue",
                gameData!["venueName"] ?? "Unknown"),
            _buildDetailRow(Icons.calendar_today, "Date",
                _formatDate(gameData!["gameDate"])),
            _buildDetailRow(Icons.access_time, "Time", gameData!["gameTime"]),
            _buildDetailRow(Icons.timeline, "Opponent Difficulty",
                gameData!["opponentDifficulty"]),
            _buildDetailRow(
                Icons.group, "Players Required", gameData!["hostTeamSize"]),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, dynamic value) {
    String displayValue = value != null && value.toString().isNotEmpty
        ? value.toString()
        : "Unknown";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 12),
          Text(
            "$title:",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayValue,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinedPlayersList() {
    if (joinedPlayers == null || joinedPlayers!.isEmpty) {
      return const Center(
        child: Text("No players have joined yet.",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );
    }
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Joined Players",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),
            const Divider(),
            ...joinedPlayers!.map((player) {
              var requester = player['Requester'];
              return ListTile(
                leading: const Icon(Icons.sports_soccer, color: Colors.green),
                title: Text(
                  "${requester["firstName"].toUpperCase()} ${requester["lastName"].toUpperCase()}",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Contact: ${requester["phoneNo"]}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.account_circle,
                          color: Colors.green, size: 30),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ViewProfile(viewedUserId: requester["uuid"]),
                          ),
                        );
                      },
                    ),
                    if (currentUserId == hostData!["uuid"])
                      IconButton(
                        icon:
                            const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () =>
                            _confirmRemovePlayer(requester["uuid"]),
                      ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _confirmRemovePlayer(String playerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Player"),
        content: const Text("Are you sure you want to remove this player?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("No")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              removePlayer(playerId);
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  Widget _buildOpponentTeam() {
    // if (oppPlayers == null) {
    //   return const SizedBox.shrink(); // Or return a loading indicator if needed
    // }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Opponent Team",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.group, color: Colors.green),
              title: Text(
                "${oppPlayers!["Requester"]["firstName"].toUpperCase()} ${oppPlayers!["Requester"]["lastName"].toUpperCase()}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text("Contact: ${oppPlayers!["Requester"]["phoneNo"]}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.account_circle,
                        color: Colors.green, size: 30),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewProfile(
                              viewedUserId: oppPlayers!["Requester"]["uuid"]),
                        ),
                      );
                    },
                  ),
                  if (currentUserId == hostData!["uuid"])
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => _confirmRemovePlayer(
                          oppPlayers!["Requester"]["uuid"]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateTime) {
    if (dateTime == null) return "Unknown";
    return dateTime.split("T")[0];
  }
}
