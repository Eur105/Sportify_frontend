// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, avoid_print, prefer_const_literals_to_create_immutables, unused_field, sort_child_properties_last, unused_element

import 'package:flutter/material.dart';
import 'package:sportify_final/pages/create_game.dart';
import 'package:sportify_final/pages/notification_page.dart';
import 'package:sportify_final/pages/utility/api_constants.dart';
import 'package:sportify_final/pages/utility/bottom_navbar.dart';
import 'package:sportify_final/pages/utility/edit_profile.dart';
import 'package:sportify_final/pages/utility/filter.dart';
import 'package:sportify_final/pages/utility/game_joining.dart';
import 'package:sportify_final/pages/utility/profile.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportify_final/pages/utility/view_gamedetails.dart';

class PlayPage extends StatefulWidget {
  const PlayPage({super.key});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  final Color backgroundGrey = const Color(0xFFF5F5F5);
  int selectedTab = 1; // Default to "My Sports"

  // Lists to separate public and private games
  List<Map<String, String>> publicGames = [];
  List<Map<String, String>> privateGames = [];
  bool hasPrivateGame = false; // To track if any private game is created
  // TextEditingController _searchController = TextEditingController();
  String? _selectedSport;

  @override
  void initState() {
    super.initState();
    _fetchAllGames();
  }

  Future<void> _fetchAllGames() async {
    try {
      var url = Uri.parse("${ApiConstants.baseUrl}/api/game/getallgames");
      var response = await http.get(url);

      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = jsonDecode(response.body);

        if (responseBody.containsKey("Games")) {
          List<dynamic> gamesList = responseBody["Games"];

          setState(() {
            // Reset the lists
            publicGames.clear();
            privateGames.clear();
            hasPrivateGame = false;

            // Categorize games into public and private
            for (var game in gamesList) {
              String rawDate = game["gameDate"] ?? "Unknown";
              String formattedDate =
                  rawDate.split("T")[0]; // Extract only YYYY-MM-DD

              Map<String, String> gameDetails = {
                "uuid": game["uuid"] ?? "",
                "fullName": game["fullName"] ?? "Unknown",
                "userEmail": game["userEmail"] ?? "Unknown",
                "sportType": game["sportType"] ?? "Unknown",
                "gameDate": formattedDate, // Store only the date
                "gameTime": game["gameTime"] ?? "Unknown",
                "visibility": game["visibility"] ?? "Unknown",
                "venueName": game["venueName"] ?? "Unknown",
                "hostTeamSize": game["hostTeamSize"]?.toString() ?? "Unknown",
                "joinedPlayers": game["joinedPlayers"]?.toString() ?? "0",
                "opponentDifficulty":
                    game["opponentDifficulty"]?.toString() ?? "0",
                "isOpponent": game["isOpponent"]?.toString() ?? "false",
                "isTeamPlayer": game["isTeamPlayer"]?.toString() ?? "false",
                "opponentTeamId": game["opponentTeamId"] ?? "0",
                "latitude": game["latitude"].toString(),
                "longitude": game["longitude"].toString(),
              };

              // Categorize based on visibility type
              if (game["visibility"] == "private") {
                privateGames.add(gameDetails);
                hasPrivateGame = true;
              } else {
                publicGames.add(gameDetails);
              }
            }
          });
        } else {
          print("Failed to load games: No 'Games' key found in API response.");
        }
      } else {
        print("Failed to load games: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching games: $e");
    }
  }

  Future<bool> _isProfileComplete() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userUuid = prefs.getString('userUuid');

    if (userUuid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User not logged in!")),
      );
      return false;
    }

    final Uri url =
        Uri.parse("${ApiConstants.baseUrl}/api/auth/verify-profile");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userUuid}),
      );

      if (response.statusCode == 200) {
        //print("Success");
        //final data = jsonDecode(response.body);
        return true; // Ensure API returns this key
      }
    } catch (e) {
      print("Error checking profile: $e");
    }

    return false;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "Unknown";
    try {
      final dateTime = DateTime.parse(dateStr);
      return "${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}";
    } catch (e) {
      return "Invalid Date";
    }
  }

  void _showProfileIncompleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Complete Your Profile"),
          content: Text(
            "You need to complete your profile before you can create or join a game.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProfile()),
                );
              },
              child: Text("Go to Profile"),
            ),
          ],
        );
      },
    );
  }

  void _showJoinDialog(Map<String, String> game) async {
    bool profileComplete = await _isProfileComplete();

    if (!profileComplete) {
      _showProfileIncompleteDialog();
      return;
    }

    if (game["visibility"] == "private") {
      _askForInvitationCode(game);
    } else {
      _showRoleSelectionDialog(game);
    }
  }

  void _askForInvitationCode(Map<String, String> game) {
    TextEditingController codeController = TextEditingController();
    String gameId = game["uuid"] ?? "";
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Center(
            child: Text(
              "Enter Invitation Code",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: InputDecoration(
                  hintText: "Enter Code",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  String enteredCode = codeController.text;

                  if (enteredCode.isEmpty || gameId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Invalid input! Try again.")),
                    );
                    return;
                  }

                  bool isValid =
                      await _verifyInvitationCode(enteredCode, gameId);

                  if (isValid) {
                    Navigator.pop(context); // Close the dialog
                    _showRoleSelectionDialog(
                        game); // Proceed with role selection
                  } else {
                    //print(gameId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Invalid code! Try again.")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(120, 50),
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  "Submit",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _verifyInvitationCode(String code, String gameId) async {
    final Uri url =
        Uri.parse("${ApiConstants.baseUrl}/api/game/verify-game-code");
    bool valid = false;

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"joinCode": code, "gameId": gameId}),
      );

      if (response.statusCode == 200) {
        print(gameId);
        // final data = jsonDecode(response.body);
        valid = true;
        return valid;
      }
    } catch (e) {
      print("Error verifying code: $e");
    }
    return false;
  }

  void _showRoleSelectionDialog(Map<String, String> game) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Center(
            child: Text(
              "Join Game",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text(
              "Choose how you want to join this game.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Check if opponent joining is allowed
            if (game["isOpponent"] == "true")
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (game["opponentTeamId"] != "0") {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text(
                              "Opponent Already Selected",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            content: const Text(
                                "An opponent has already been selected for this game."),
                            actions: <Widget>[
                              TextButton(
                                child: const Text("OK"),
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                },
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GameJoiningPage(
                            gameDetails: game,
                            role: "opponentTeam",
                            uuid: game["uuid"] ?? "",
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    "Join as an Opponent",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),

            const SizedBox(height: 10),

            // Check if team player joining is allowed
            if (game["isTeamPlayer"] == "true")
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (game["hostTeamSize"] == game["joinedPlayers"]) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Team Full",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            content: const Text(
                                "The host team is already full for this game."),
                            actions: <Widget>[
                              TextButton(
                                child: const Text("OK"),
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                },
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GameJoiningPage(
                            gameDetails: game,
                            role: "hostTeam",
                            uuid: game["uuid"] ?? "", // Pass the UUID
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    "Join as a Player",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
          ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Adjust breakpoint as needed

    return DefaultTabController(
      length: 2,
      initialIndex: selectedTab,
      child: Scaffold(
        backgroundColor: backgroundGrey,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text(
            "Let's Play",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationPage()),
                );
              },
              icon: Icon(Icons.notifications, color: Colors.black),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
              icon: Icon(Icons.person, color: Colors.black),
            ),
          ],
          bottom: TabBar(
            indicatorColor: Colors.green,
            labelColor: Colors.green,
            unselectedLabelColor: Colors.black,
            tabs: [
              Tab(text: "Games"),
              Tab(text: "My Sports"),
            ],
            labelPadding: isSmallScreen
                ? EdgeInsets.symmetric(
                    horizontal: 16) // Adjust padding for smaller screens
                : null, // Default padding for larger screens
          ),
        ),
        body: TabBarView(
          children: [
            _buildGamesTab(),
            _buildMySportsTab(),
          ],
        ),
        bottomNavigationBar: BottomNavbar(),
      ),
    );
  }

  void _searchGames(Map<String, String> filters) async {
    String baseUrl = '${ApiConstants.baseUrl}/api/game/search';
    String queryString = filters.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final url = Uri.parse('$baseUrl?$queryString');

    print('Calling: $url');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> gamesData = decoded['games'];

        // Convert each game to Map<String, String>
        final List<Map<String, String>> convertedGames = [];

        for (var game in gamesData) {
          if ((game as Map<String, dynamic>)['visibility'] == 'public') {
            final convertedGame = <String, String>{};
            game.forEach((key, value) {
              convertedGame[key] = value?.toString() ?? '';
            });
            convertedGames.add(convertedGame);
          }
        }

        setState(() {
          publicGames = convertedGames;
        });
      } else {
        print('Failed to load games: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching games: $e');
    }
  }

  void _searchPrivateGames(Map<String, String> filters) async {
    String baseUrl = '${ApiConstants.baseUrl}/api/game/search';
    String queryString = filters.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final url = Uri.parse('$baseUrl?$queryString');

    print('Calling: $url');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> gamesData = decoded['games'];

        final List<Map<String, String>> convertedGames = [];

        for (var game in gamesData) {
          // Ensure the game is private
          if ((game as Map<String, dynamic>)['visibility'] == 'private') {
            final convertedGame = <String, String>{};
            game.forEach((key, value) {
              convertedGame[key] = value?.toString() ?? '';
            });
            convertedGames.add(convertedGame);
          }
        }

        setState(() {
          privateGames = convertedGames;
        });
      } else {
        print('Failed to load games: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching games: $e');
    }
  }

  Widget _buildGamesTab() {
    final now = DateTime.now();

// Filter games whose date has not passed
    final upcomingGames = publicGames.where((game) {
      final gameDateStr = game["gameDate"];
      if (gameDateStr == null) return false;

      try {
        final gameDate = DateTime.parse(gameDateStr);
        return gameDate.isAfter(now) || _isSameDay(gameDate, now);
      } catch (_) {
        return false;
      }
    }).toList();

    return Column(
      children: [
        // 🔍 Search Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 40, // Smaller width
              height: 40, // Smaller height
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SportFilterPage()),
                  ).then((filters) {
                    if (filters != null && filters is Map<String, String>) {
                      _searchGames(filters); // Send full filters to the API
                    }
                  });
                },
                mini: true, // Makes the FAB smaller
                backgroundColor: Colors.green,
                child: const Icon(Icons.filter_alt_rounded,
                    color: Colors.white, size: 20),
                tooltip: 'Filter Games',
              ),
            ),
          ],
        ),

        // 📄 Games List
        Expanded(
          child: publicGames.isEmpty
              ? Center(
                  child: Text(
                    "No public games created yet",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                )
              : ListView.builder(
                  itemCount: upcomingGames.length,
                  itemBuilder: (context, index) {
                    final game = upcomingGames[index];
                    final String? uu = game["uuid"];
                    print(uu);

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ViewGameDetails(gameId: uu ?? "0"),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                Colors.green,
                                Colors.purpleAccent.shade200
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.sports_soccer,
                                          color: Colors.white, size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        game["sportType"] ?? "Unknown Sport",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.more_vert,
                                        color: Colors.white70, size: 18),
                                    onPressed: () =>
                                        _showGameOptionsDialog(game),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Game Details
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          color: Colors.white70, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Venue: ${game["venueName"] ?? "Unknown"}",
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          color: Colors.white70, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(game["gameDate"]),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.people_outline,
                                          color: Colors.white70, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Required players: ${game["hostTeamSize"] ?? "0"}",
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.group,
                                          color: Colors.white70, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        "No of players joined: ${game["joinedPlayers"] ?? "0"}",
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70),
                                      ),
                                    ],
                                  ),

                                  // Visibility
                                ],
                              ),
                              const SizedBox(height: 8),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.visibility,
                                          color: Colors.white70, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        game["visibility"] ?? "Unknown",
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                  game["isOpponent"] == "true"
                                      ? Row(
                                          children: [
                                            const Icon(Icons.sports_kabaddi,
                                                color: Colors.white70,
                                                size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              "Opponent Required: ${game["opponentDifficulty"] ?? "0"}",
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white70),
                                            ),
                                          ],
                                        )
                                      : const SizedBox.shrink(),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Game info rows (same as before)
                              // ...
                              // Join Button
                              Center(
                                child: ElevatedButton(
                                  onPressed: () => _showJoinDialog(game),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 3,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (game["visibility"] == "private")
                                        const Icon(Icons.lock,
                                            size: 18, color: Colors.black),
                                      const SizedBox(width: 5),
                                      const Text(
                                        "JOIN",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildGameDetail(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            "$label: ${value ?? "Unknown"}",
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showGameOptionsDialog(Map<String, dynamic> game) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.cancel, color: Colors.red),
              title:
                  Text("Leave This Game", style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context); // Close modal
                _leaveGame(game["uuid"] ?? "0");
              },
            ),
          ],
        );
      },
    );
  }

  void _leaveGame(String gameId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString("userUuid");

    final url = Uri.parse("${ApiConstants.baseUrl}/api/game/leavegame/$gameId");
    final response = await http.delete(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userId": userId}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You have left the game successfully.")),
      );

      // If you have a list like `publicGames`, remove the game from it
      setState(() {
        publicGames.removeWhere((game) => game["gameId"] == gameId);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Failed to leave as you are not part of this game.")),
      );
    }
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Widget _buildMySportsTab() {
    final now = DateTime.now();

// Filter games whose date has not passed
    final upcomingGames = privateGames.where((game) {
      final gameDateStr = game["gameDate"];
      if (gameDateStr == null) return false;

      try {
        final gameDate = DateTime.parse(gameDateStr);
        return gameDate.isAfter(now) || _isSameDay(gameDate, now);
      } catch (_) {
        return false;
      }
    }).toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 40, // Smaller width
              height: 40, // Smaller height
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SportFilterPage()),
                  ).then((filters) {
                    if (filters != null && filters is Map<String, String>) {
                      _searchPrivateGames(
                          filters); // Send full filters to the API
                    }
                  });
                },
                mini: true, // Makes the FAB smaller
                backgroundColor: Colors.green,
                child: const Icon(Icons.filter_alt_rounded,
                    color: Colors.white, size: 20),
                tooltip: 'Filter Games',
              ),
            ),
          ],
        ),
        Expanded(
          child: privateGames.isEmpty
              ? Center(
                  child: Text(
                    "Get started by creating your first private game!",
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: upcomingGames.length,
                  itemBuilder: (context, index) {
                    final game = upcomingGames[index];
                    final String? uu = game["uuid"];

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    ViewGameDetails(gameId: uu ?? "0")));
                      },
                      child: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                Colors.green,
                                Colors.purpleAccent.shade200,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Game Type & Options Icon
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.sports_soccer,
                                          color: Colors.white, size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        game["sportType"] ?? "Unknown Sport",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.more_vert,
                                        color: Colors.white70, size: 18),
                                    onPressed: () =>
                                        _showGameOptionsDialog(game),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Game Details
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          color: Colors.white70, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(game["gameDate"]),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.people_outline,
                                          color: Colors.white70, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Required players: ${game["hostTeamSize"] ?? "0"}",
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.group,
                                          color: Colors.white70, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        "No of players joined: ${game["joinedPlayers"] ?? "0"}",
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70),
                                      ),
                                    ],
                                  ),

                                  // Visibility
                                ],
                              ),
                              const SizedBox(height: 8),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.visibility,
                                          color: Colors.white70, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        game["visibility"] ?? "Unknown",
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                  game["isOpponent"] == "true"
                                      ? Row(
                                          children: [
                                            const Icon(Icons.sports_kabaddi,
                                                color: Colors.white70,
                                                size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              "Opponent Required: ${game["opponentDifficulty"] ?? "0"}",
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white70),
                                            ),
                                          ],
                                        )
                                      : const SizedBox.shrink(),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Join Button
                              Center(
                                child: ElevatedButton(
                                  onPressed: () => _showJoinDialog(game),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 3,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (game["visibility"] == "private")
                                        const Icon(Icons.lock,
                                            size: 18, color: Colors.black),
                                      const SizedBox(width: 5),
                                      const Text(
                                        "JOIN",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        SizedBox(height: 20),
        SafeArea(
          child: ElevatedButton(
            onPressed: () async {
              bool profileComplete = await _isProfileComplete();

              if (!profileComplete) {
                _showProfileIncompleteDialog();
                return;
              }

              final Map<String, String>? newGame = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateGame()),
              );

              if (newGame != null) {
                _fetchAllGames();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: Text("Create a Game", style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
