// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportify_final/pages/utility/api_constants.dart';
import 'package:sportify_final/pages/utility/venuelocation.dart';

class CreateGame extends StatefulWidget {
  const CreateGame({super.key});

  @override
  State<CreateGame> createState() => _CreateGameState();
}

class _CreateGameState extends State<CreateGame> {
  final _formKey = GlobalKey<FormState>();
  String? selectedGame;
  TextEditingController venueController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController startTimeController = TextEditingController();
  TextEditingController endTimeController = TextEditingController();
  TextEditingController playersNeededController = TextEditingController();
  TextEditingController opponentController = TextEditingController();

  bool isPublicGame = true;
  bool lookingForOpponent = false;
  bool needPlayers = false;
  bool isLoading = false;

  String? userEmail;
  String fullName = "";
  String? selectedSkillLevel;
  final List<String> gameTypes = ['Football', 'Cricket', 'Badminton'];
  TimeOfDay? startTime;

  String? venueName;
  double? venueLatitude;
  double? venueLongitude;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString("email") ?? "";
      String firstName = prefs.getString("firstName") ?? "Unknown";
      String lastName = prefs.getString("lastName") ?? "";
      fullName = "$firstName $lastName".trim();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        String month = picked.month.toString().padLeft(2, '0');
        String day = picked.day.toString().padLeft(2, '0');
        dateController.text = "${picked.year}-$month-$day";
      });
    }
  }

  Future<void> _selectTime(
    BuildContext context,
    TextEditingController controller,
    TimeOfDay? startTime,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (startTime != null && picked.hour < startTime.hour ||
          (picked.hour == startTime!.hour &&
              picked.minute < startTime.minute)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("End time cannot be before start time."),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        controller.text = picked.format(context);
      }
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startTimeController.text = picked.format(context);
        startTime = picked;
      });
    }
  }

  Future<void> _createGame() async {
    if (!_formKey.currentState!.validate()) return;
    if (userEmail == null || userEmail!.isEmpty) {
      _showError("User email not found. Please log in again.");
      return;
    }

    String visibility = isPublicGame ? "public" : "private";
    var url = Uri.parse("${ApiConstants.baseUrl}/api/game/addnewgame");

    Map<String, String> body = {
      "gameName": selectedGame!,
      "fullName": fullName,
      "userEmail": userEmail!,
      "sportType": selectedGame!,
      "gameDate": dateController.text,
      "gameTime": "${startTimeController.text} - ${endTimeController.text}",
      "visibility": visibility,
      "venueName": venueName!,
      "hostTeamSize": playersNeededController.text,
      "opponentDifficulty": selectedSkillLevel ?? "",
      "isOpponent": lookingForOpponent.toString(),
      "isTeamPlayer": needPlayers.toString(),
      "latitude": venueLatitude.toString(),
      "longitude": venueLongitude.toString()
    };

    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        _showNotification("Game Created!",
            "Your game for $selectedGame has been successfully created!");

        Navigator.pop(context, body);
      } else {
        _showError("Failed to create game. Please try again.");
      }
    } catch (e) {
      _showError("Error connecting to server.");
    } finally {
      setState(() => isLoading = false); // Reset loader
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Adjust breakpoint as needed

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Create Game',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12, blurRadius: 8, spreadRadius: 2)
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration:
                          const InputDecoration(labelText: 'Select Game'),
                      value: selectedGame,
                      items: gameTypes.map((String game) {
                        return DropdownMenuItem<String>(
                          value: game,
                          child: Text(game),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedGame = newValue;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Select a game' : null,
                    ),
                    SizedBox(
                        height: isSmallScreen ? 12 : 16), // Responsive spacing
                    VenueSearchField(
                      onVenueSelected: (name, lat, lon) {
                        setState(() {
                          venueName = name;
                          venueLatitude = lat;
                          venueLongitude = lon;
                          print(
                              'Selected venue: $venueName at $venueLatitude, $venueLongitude');
                        });
                      },
                    ),
                    SizedBox(
                        height: isSmallScreen ? 12 : 16), // Responsive spacing
                    TextFormField(
                      controller: dateController,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Date'),
                      onTap: () => _selectDate(context),
                    ),
                    SizedBox(
                        height: isSmallScreen ? 12 : 16), // Responsive spacing
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: startTimeController,
                            readOnly: true,
                            decoration:
                                const InputDecoration(labelText: 'Start Time'),
                            onTap: () => _selectStartTime(context),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: endTimeController,
                            readOnly: true,
                            decoration:
                                const InputDecoration(labelText: 'End Time'),
                            onTap: () => _selectTime(
                                context, endTimeController, startTime),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                        height: isSmallScreen ? 15 : 20), // Responsive spacing
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Looking for Opponent?",
                                style: TextStyle(fontSize: 16)),
                            Switch(
                              value: lookingForOpponent,
                              onChanged: (value) {
                                setState(() {
                                  lookingForOpponent = value;
                                  if (!lookingForOpponent) {
                                    selectedSkillLevel = null;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        if (lookingForOpponent) ...[
                          SizedBox(
                              height:
                                  isSmallScreen ? 8 : 10), // Responsive spacing
                          const Text(
                            "Select Opponent Level:",
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Column(
                            children: ["Beginner", "Average", "Strong", "Pro"]
                                .map((level) {
                              return RadioListTile<String>(
                                title: Text(level),
                                value: level,
                                groupValue: selectedSkillLevel,
                                onChanged: (String? value) {
                                  setState(() {
                                    selectedSkillLevel = value;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(
                        height: isSmallScreen ? 12 : 16), // Responsive spacing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Need Players for Your Team?",
                            style: TextStyle(fontSize: 16)),
                        Switch(
                          value: needPlayers,
                          onChanged: (value) {
                            setState(() {
                              needPlayers = value;
                              if (!needPlayers) {
                                playersNeededController.clear();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(
                        height: isSmallScreen ? 12 : 16), // Responsive spacing
                    if (needPlayers)
                      TextFormField(
                        controller: playersNeededController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Number of Players Required'),
                        validator: (value) {
                          if (needPlayers && (value == null || value.isEmpty)) {
                            return 'Enter number of players needed';
                          }
                          return null;
                        },
                      ),
                    SizedBox(
                        height: isSmallScreen ? 15 : 20), // Responsive spacing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                setState(() => isPublicGame = true),
                            icon: const Icon(Icons.public),
                            label: const Text("Public"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isPublicGame
                                  ? Colors.green
                                  : Colors.grey[300],
                              foregroundColor:
                                  isPublicGame ? Colors.white : Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                setState(() => isPublicGame = false),
                            icon: const Icon(Icons.lock),
                            label: const Text("Invite Only"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !isPublicGame
                                  ? Colors.green
                                  : Colors.grey[300],
                              foregroundColor:
                                  !isPublicGame ? Colors.white : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                        height: isSmallScreen ? 20 : 24), // Responsive spacing
                    isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: () {
                              if (lookingForOpponent == true ||
                                  needPlayers == true) {
                                setState(() => isLoading = true);
                                _createGame();
                              } else {
                                _showErrorDialog(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 40),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Create Game',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _showErrorDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Action Required"),
        content: const Text(
            "Either choose an Opponent or Get Team Players before creating a game."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      );
    },
  );
}

Future<void> _showNotification(String title, String body) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'game_creation_channel',
    'Game Creation Notifications',
    channelDescription: 'Notifications for game creation',
    importance: Importance.high,
    priority: Priority.high,
    ticker: 'ticker',
  );

  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidDetails);

  await FlutterLocalNotificationsPlugin()
      .show(0, title, body, notificationDetails);
}

class Venue {
  final String name;
  final String neighbourhood;
  final String lat;
  final String lon;

  Venue({
    required this.name,
    required this.neighbourhood,
    required this.lat,
    required this.lon,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      name: json['name'] ?? '',
      neighbourhood: json['address']['neighbourhood'] ?? '',
      lat: json['lat'],
      lon: json['lon'],
    );
  }

  @override
  String toString() => '$name (${neighbourhood})';
}
