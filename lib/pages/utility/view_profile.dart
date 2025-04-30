// ignore_for_file: prefer_const_constructors, prefer_const_declarations

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportify_final/pages/utility/edit_profile.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';

class ViewProfile extends StatefulWidget {
  final String viewedUserId; // ID of the profile being viewed

  const ViewProfile({super.key, required this.viewedUserId});

  @override
  State<ViewProfile> createState() => _ViewProfileState();
}

class _ViewProfileState extends State<ViewProfile> {
  String? profilePicturePath,
      fullName,
      gender,
      address,
      phoneNumber,
      biodescr,
      bioskill,
      bioExperience;
  String? loggedInUserId;
  int matchesPlayed = 20;
  int wins = 12;
  int losses = 8;
  String activeLevel = "Active";
  List<String> userBadges = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchActiveLevel();
    _fetchUserBadges();
  }

  Future<void> _loadUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    loggedInUserId = prefs.getString('userUuid');

    if (widget.viewedUserId == loggedInUserId) {
      setState(() {
        String firstName = prefs.getString('firstName') ?? "";
        String lastName = prefs.getString('lastName') ?? "";
        fullName =
            "${firstName.toUpperCase()} ${lastName.toUpperCase()}".trim();
        gender = prefs.getString('gender') ?? "Unknown";
        address = prefs.getString('address') ?? "No address available";
        phoneNumber = prefs.getString('phoneNo') ?? "No phone number";
        biodescr = prefs.getString('bioDescription') ?? "No bio available";
        bioskill = prefs.getString('bioSkillLevel') ?? "No bio available";
        bioExperience = prefs.getString('bioExperience') ?? "No bio available";
        profilePicturePath = prefs.getString('profilePicture');
        isLoading = false;
      });
    } else {
      await _fetchUserProfile(widget.viewedUserId);
    }
  }

  Future<void> _fetchUserProfile(String userId) async {
    final String url = "http://localhost:5000/api/user/getuser/$userId";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          fullName =
              "${data['firstName'].toUpperCase()} ${data['lastName'].toUpperCase()}"
                  .trim();
          gender = data['gender'] ?? "Unknown";
          address = data['address'] ?? "No address available";
          phoneNumber = data['phoneNo'] ?? "No phone number";
          biodescr = data['userbio']['description'] ?? "No bio available";
          bioskill = data['userbio']['skillLevel'] ?? "No bio available";
          //bioExperience = data['userbio']['experience'] ?? "No bio available";
          profilePicturePath = data['profilePicture'] ?? "";
          isLoading = false;
        });
      } else {
        print("Failed to fetch profile: ${response.body}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching profile: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchActiveLevel() async {
    final String url =
        "http://localhost:5000/api/user/get-active-level/${widget.viewedUserId}";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          activeLevel = data['ActivityLevel'] ?? "Warming Up";
        });
      }
    } catch (e) {
      print("Error fetching active level: $e");
    }
  }

  Future<void> _fetchUserBadges() async {
    final String url =
        "http://localhost:5000/api/badge/getuserbadges/${widget.viewedUserId}";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userBadges = (data['badges'] as List)
              .map((badge) => badge['name']
                  .toString()
                  .toLowerCase()) // Extracting only names
              .toList();
        });
      } else {
        print("Failed to fetch badges: ${response.body}");
      }
    } catch (e) {
      print("Error fetching badges: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isOwnProfile = loggedInUserId == widget.viewedUserId;
    final Color backgroundGrey = const Color(0xFFF5F5F5);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Adjust breakpoint as needed

    return Scaffold(
      backgroundColor: backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: isOwnProfile
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditProfile()),
                    );
                  },
                ),
              ]
            : null,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(
                  isSmallScreen ? 12.0 : 16.0), // Responsive padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius:
                              isSmallScreen ? 40 : 50, // Responsive avatar size
                          backgroundImage: profilePicturePath != null &&
                                  profilePicturePath!.isNotEmpty
                              ? FileImage(File(profilePicturePath!))
                              : AssetImage("assets/picture/profile.png")
                                  as ImageProvider,
                        ),
                        SizedBox(
                            height:
                                isSmallScreen ? 8 : 10), // Responsive spacing
                        Text(
                          fullName ?? "User",
                          style: TextStyle(
                              fontSize: isSmallScreen ? 18 : 22,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(gender ?? ""),
                        SizedBox(
                            height:
                                isSmallScreen ? 8 : 10), // Responsive spacing
                        Text(
                          (biodescr ?? ""),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                      height: isSmallScreen ? 15 : 20), // Responsive spacing
                  _buildInfoCard(Icons.phone, "Phone", phoneNumber!),
                  _buildInfoCard(Icons.location_on, "Address", address!),
                  SizedBox(
                      height: isSmallScreen ? 12 : 16), // Responsive spacing
                  _buildDivider(),
                  SizedBox(
                      height: isSmallScreen ? 12 : 16), // Responsive spacing
                  _buildGameStatsSection(),
                  SizedBox(
                      height: isSmallScreen ? 12 : 16), // Responsive spacing
                  _buildDivider(),
                  SizedBox(
                      height: isSmallScreen ? 12 : 16), // Responsive spacing
                  _buildActiveLevelSection(),
                  SizedBox(
                      height: isSmallScreen ? 12 : 16), // Responsive spacing
                  _buildDivider(),
                  SizedBox(
                      height: isSmallScreen ? 12 : 16), // Responsive spacing
                  _buildSkillsSection(),
                  SizedBox(
                      height: isSmallScreen ? 8 : 10), // Responsive spacing
                  _buildDivider(),
                  SizedBox(
                      height: isSmallScreen ? 12 : 16), // Responsive spacing
                  _buildAchievementsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(thickness: 1, color: Colors.grey.shade400),
    );
  }

  Widget _buildSkillsSection() {
    String? userSkill = bioskill;
    // This should be dynamically set based on user data
    print(bioskill);
    List<Map<String, dynamic>> skills = [
      {"title": "Beginner", "icon": Icons.school, "color": Colors.orange},
      {"title": "Amateur", "icon": Icons.trending_up, "color": Colors.blue},
      {"title": "Expert", "icon": Icons.verified, "color": Colors.green},
      {"title": "Pro", "icon": Icons.emoji_events, "color": Colors.red},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Skills",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          physics: NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          children: skills.map((skill) {
            bool isHighlighted = skill["title"] == userSkill;

            return Column(
              children: [
                Icon(
                  skill["icon"],
                  size: 40,
                  color: isHighlighted ? skill["color"] : Colors.grey,
                ),
                Text(
                  skill["title"],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isHighlighted ? FontWeight.bold : FontWeight.normal,
                    color: isHighlighted ? Colors.black : Colors.grey,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    List<Map<String, dynamic>> badges = [
      {"title": "beginner", "icon": Icons.emoji_events},
      {"title": "engaged", "icon": Icons.favorite},
      {"title": "hyperactive", "icon": Icons.flash_on},
      {"title": "gamecreator", "icon": Icons.create},
      {"title": "firstvictory", "icon": Icons.emoji_emotions},
      {"title": "champion", "icon": Icons.sports_kabaddi},
      {"title": "legend", "icon": Icons.stars},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Achievements",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),

        /// GridView with animated badges
        LayoutBuilder(
          builder: (context, constraints) {
            return GridView.builder(
              shrinkWrap: true,
              itemCount: badges.length,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Keep 3 per row except last
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                bool isHighlighted =
                    userBadges.contains(badges[index]["title"]);

                return AnimatedContainer(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.all(8),
                  alignment: Alignment.center,
                  transform: isHighlighted
                      ? Matrix4.identity().scaled(1.2)
                      : Matrix4.identity(), // Scale effect on highlight
                  child: Column(
                    children: [
                      Icon(
                        badges[index]["icon"],
                        size: 40,
                        color: isHighlighted ? Colors.amber : Colors.grey,
                      )
                          .animate()
                          .fade(duration: 500.ms)
                          .scale(delay: 200.ms, curve: Curves.easeOut)
                          .shake(
                              hz: 3, curve: Curves.easeInOut), // Bounce effect

                      SizedBox(height: 5),
                      Text(
                        badges[index]["title"],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isHighlighted
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isHighlighted ? Colors.black : Colors.grey,
                        ),
                      )
                          .animate()
                          .fade(delay: 300.ms)
                          .slideX(begin: -0.2, end: 0, curve: Curves.easeOut),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildGameStatsSection() {
    // double winRate = wins / matchesPlayed;
    // double lossRate = losses / matchesPlayed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Game Stats",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        _buildProgressBar("Wins", wins, matchesPlayed, Colors.green),
        _buildProgressBar("Losses", losses, matchesPlayed, Colors.red),
        _buildProgressBar(
            "Total Matches", matchesPlayed, matchesPlayed, Colors.blue),
      ],
    );
  }

  Widget _buildProgressBar(String label, int value, int total, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: $value/$total",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          LinearProgressIndicator(
            value: total > 0 ? value / total : 0.0,
            backgroundColor: color.withOpacity(0.3),
            color: color,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveLevelSection() {
    List<String> levels = ["Warming Up", "Active", "Super Active", "On Fire"];
    int activeIndex = levels.indexOf(activeLevel); // Get current level index

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Active Level",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),

        /// Animated Progress Bar
        Stack(
          alignment: Alignment.center,
          children: [
            /// Lightning Bolt-Themed Progress Line
            Container(
              height: 5,
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey.withOpacity(0.3),
                    Colors.yellow.withOpacity(0.7),
                    Colors.orange.withOpacity(0.9),
                    Colors.redAccent,
                  ],
                  stops: [0.2, 0.5, 0.8, 1.0],
                ),
                borderRadius: BorderRadius.circular(5),
              ),
            )
                .animate()
                .fade(duration: 500.ms)
                .moveX(begin: -30, end: 0, curve: Curves.easeOut),

            /// Lightning Icons Connected
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(levels.length, (index) {
                bool isHighlighted = index <= activeIndex;
                return Column(
                  children: [
                    Icon(
                      Icons.bolt,
                      size: 40,
                      color: isHighlighted ? Colors.yellow : Colors.grey,
                    ).animate().scale(
                        begin:
                            isHighlighted ? Offset(1.0, 1.0) : Offset(0.8, 0.8),
                        end:
                            isHighlighted ? Offset(1.2, 1.2) : Offset(1.0, 1.0),
                        curve: Curves.easeInOut),
                    Text(
                      levels[index],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isHighlighted ? FontWeight.bold : FontWeight.normal,
                        color: isHighlighted ? Colors.black : Colors.grey,
                      ),
                    )
                  ],
                );
              }),
            ),
          ],
        ),
      ],
    );
  }
}

/*// ignore_for_file: prefer_const_constructors, prefer_const_declarations

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportify_final/pages/utility/api_constants.dart';
import 'package:sportify_final/pages/utility/edit_profile.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';

class ViewProfile extends StatefulWidget {
  final String viewedUserId; // ID of the profile being viewed

  const ViewProfile({super.key, required this.viewedUserId});

  @override
  State<ViewProfile> createState() => _ViewProfileState();
}

class _ViewProfileState extends State<ViewProfile> {
  String? profilePicturePath,
      fullName,
      gender,
      address,
      phoneNumber,
      biodescr,
      bioskill,
      bioExperience;
  String? loggedInUserId;
  int matchesPlayed = 20;
  int wins = 12;
  int losses = 8;
  String activeLevel = "Active";
  List<String> userBadges = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchActiveLevel();
    _fetchUserBadges();
  }

  Future<void> _loadUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    loggedInUserId = prefs.getString('userUuid');

    if (widget.viewedUserId == loggedInUserId) {
      setState(() {
        String firstName = prefs.getString('firstName') ?? "";
        String lastName = prefs.getString('lastName') ?? "";
        fullName =
            "${firstName.toUpperCase()} ${lastName.toUpperCase()}".trim();
        gender = prefs.getString('gender') ?? "Unknown";
        address = prefs.getString('address') ?? "No address available";
        phoneNumber = prefs.getString('phoneNo') ?? "No phone number";
        biodescr = prefs.getString('bioDescription') ?? "No bio available";
        bioskill = prefs.getString('bioSkillLevel') ?? "No bio available";
        bioExperience = prefs.getString('bioExperience') ?? "No bio available";
        profilePicturePath = prefs.getString('profilePicture');
      });
    } else {
      await _fetchUserProfile(widget.viewedUserId);
    }
  }

  Future<void> _fetchUserProfile(String userId) async {
    final String url = "${ApiConstants.baseUrl}:5000/api/user/getuser/$userId";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          fullName =
              "${data['firstName'].toUpperCase()} ${data['lastName'].toUpperCase()}"
                  .trim();
          gender = data['gender'] ?? "Unknown";
          address = data['address'] ?? "No address available";
          phoneNumber = data['phoneNo'] ?? "No phone number";
          biodescr = data['userbio']['description'] ?? "No bio available";
          bioskill = data['userbio']['skillLevel'] ?? "No bio available";
          //bioExperience = data['userbio']['experience'] ?? "No bio available";
          profilePicturePath = data['profilePicture'] ?? "";
        });
      } else {
        print("Failed to fetch profile: ${response.body}");
      }
    } catch (e) {
      print("Error fetching profile: $e");
    }
  }

  Future<void> _fetchActiveLevel() async {
    final String url =
        "${ApiConstants.baseUrl}:5000/api/user/get-active-level/${widget.viewedUserId}";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          activeLevel = data['ActivityLevel'] ?? "Warming Up";
        });
      }
    } catch (e) {
      print("Error fetching active level: $e");
    }
  }

  Future<void> _fetchUserBadges() async {
    final String url =
        "${ApiConstants.baseUrl}:5000/api/badge/getuserbadges/${widget.viewedUserId}";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userBadges = (data['badges'] as List)
              .map((badge) => badge['name']
                  .toString()
                  .toLowerCase()) // Extracting only names
              .toList();
        });
      } else {
        print("Failed to fetch badges: ${response.body}");
      }
    } catch (e) {
      print("Error fetching badges: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isOwnProfile = loggedInUserId == widget.viewedUserId;
    final Color backgroundGrey = const Color(0xFFF5F5F5);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Adjust breakpoint as needed

    return Scaffold(
      backgroundColor: backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: isOwnProfile
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditProfile()),
                    );
                  },
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding:
            EdgeInsets.all(isSmallScreen ? 12.0 : 16.0), // Responsive padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: isSmallScreen ? 40 : 50, // Responsive avatar size
                    backgroundImage: profilePicturePath != null &&
                            profilePicturePath!.isNotEmpty
                        ? FileImage(File(profilePicturePath!))
                        : AssetImage("assets/picture/profile.png")
                            as ImageProvider,
                  ),
                  SizedBox(
                      height: isSmallScreen ? 8 : 10), // Responsive spacing
                  Text(
                    fullName ?? "User",
                    style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 22,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(gender ?? ""),
                  SizedBox(
                      height: isSmallScreen ? 8 : 10), // Responsive spacing
                  Text(
                    (biodescr ?? ""),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
            ),
            SizedBox(height: isSmallScreen ? 15 : 20), // Responsive spacing
            _buildInfoCard(Icons.phone, "Phone", phoneNumber!),
            _buildInfoCard(Icons.location_on, "Address", address!),
            SizedBox(height: isSmallScreen ? 12 : 16), // Responsive spacing
            _buildDivider(),
            SizedBox(height: isSmallScreen ? 12 : 16), // Responsive spacing
            _buildGameStatsSection(),
            SizedBox(height: isSmallScreen ? 12 : 16), // Responsive spacing
            _buildDivider(),
            SizedBox(height: isSmallScreen ? 12 : 16), // Responsive spacing
            _buildActiveLevelSection(),
            SizedBox(height: isSmallScreen ? 12 : 16), // Responsive spacing
            _buildDivider(),
            SizedBox(height: isSmallScreen ? 12 : 16), // Responsive spacing
            _buildSkillsSection(),
            SizedBox(height: isSmallScreen ? 8 : 10), // Responsive spacing
            _buildDivider(),
            SizedBox(height: isSmallScreen ? 12 : 16), // Responsive spacing
            _buildAchievementsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(thickness: 1, color: Colors.grey.shade400),
    );
  }

  Widget _buildSkillsSection() {
    String? userSkill = bioskill;
    // This should be dynamically set based on user data
    print(bioskill);
    List<Map<String, dynamic>> skills = [
      {"title": "Beginner", "icon": Icons.school, "color": Colors.orange},
      {"title": "Amateur", "icon": Icons.trending_up, "color": Colors.blue},
      {"title": "Expert", "icon": Icons.verified, "color": Colors.green},
      {"title": "Pro", "icon": Icons.emoji_events, "color": Colors.red},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Skills",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          physics: NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          children: skills.map((skill) {
            bool isHighlighted = skill["title"] == userSkill;

            return Column(
              children: [
                Icon(
                  skill["icon"],
                  size: 40,
                  color: isHighlighted ? skill["color"] : Colors.grey,
                ),
                Text(
                  skill["title"],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isHighlighted ? FontWeight.bold : FontWeight.normal,
                    color: isHighlighted ? Colors.black : Colors.grey,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    List<Map<String, dynamic>> badges = [
      {"title": "beginner", "icon": Icons.emoji_events},
      {"title": "engaged", "icon": Icons.favorite},
      {"title": "hyperactive", "icon": Icons.flash_on},
      {"title": "gamecreator", "icon": Icons.create},
      {"title": "firstvictory", "icon": Icons.emoji_emotions},
      {"title": "champion", "icon": Icons.sports_kabaddi},
      {"title": "legend", "icon": Icons.stars},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Achievements",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),

        /// GridView with animated badges
        LayoutBuilder(
          builder: (context, constraints) {
            return GridView.builder(
              shrinkWrap: true,
              itemCount: badges.length,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Keep 3 per row except last
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                bool isHighlighted =
                    userBadges.contains(badges[index]["title"]);

                return AnimatedContainer(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.all(8),
                  alignment: Alignment.center,
                  transform: isHighlighted
                      ? Matrix4.identity().scaled(1.2)
                      : Matrix4.identity(), // Scale effect on highlight
                  child: Column(
                    children: [
                      Icon(
                        badges[index]["icon"],
                        size: 40,
                        color: isHighlighted ? Colors.amber : Colors.grey,
                      )
                          .animate()
                          .fade(duration: 500.ms)
                          .scale(delay: 200.ms, curve: Curves.easeOut)
                          .shake(
                              hz: 3, curve: Curves.easeInOut), // Bounce effect

                      SizedBox(height: 5),
                      Text(
                        badges[index]["title"],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isHighlighted
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isHighlighted ? Colors.black : Colors.grey,
                        ),
                      )
                          .animate()
                          .fade(delay: 300.ms)
                          .slideX(begin: -0.2, end: 0, curve: Curves.easeOut),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildGameStatsSection() {
    // double winRate = wins / matchesPlayed;
    // double lossRate = losses / matchesPlayed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Game Stats",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        _buildProgressBar("Wins", wins, matchesPlayed, Colors.green),
        _buildProgressBar("Losses", losses, matchesPlayed, Colors.red),
        _buildProgressBar(
            "Total Matches", matchesPlayed, matchesPlayed, Colors.blue),
      ],
    );
  }

  Widget _buildProgressBar(String label, int value, int total, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: $value/$total",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          LinearProgressIndicator(
            value: total > 0 ? value / total : 0.0,
            backgroundColor: color.withOpacity(0.3),
            color: color,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveLevelSection() {
    List<String> levels = ["Warming Up", "Active", "Super Active", "On Fire"];
    int activeIndex = levels.indexOf(activeLevel); // Get current level index

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Active Level",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),

        /// Animated Progress Bar
        Stack(
          alignment: Alignment.center,
          children: [
            /// Lightning Bolt-Themed Progress Line
            Container(
              height: 5,
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey.withOpacity(0.3),
                    Colors.yellow.withOpacity(0.7),
                    Colors.orange.withOpacity(0.9),
                    Colors.redAccent,
                  ],
                  stops: [0.2, 0.5, 0.8, 1.0],
                ),
                borderRadius: BorderRadius.circular(5),
              ),
            )
                .animate()
                .fade(duration: 500.ms)
                .moveX(begin: -30, end: 0, curve: Curves.easeOut),

            /// Lightning Icons Connected
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(levels.length, (index) {
                bool isHighlighted = index <= activeIndex;
                return Column(
                  children: [
                    Icon(
                      Icons.bolt,
                      size: 40,
                      color: isHighlighted ? Colors.yellow : Colors.grey,
                    ).animate().scale(
                        begin:
                            isHighlighted ? Offset(1.0, 1.0) : Offset(0.8, 0.8),
                        end:
                            isHighlighted ? Offset(1.2, 1.2) : Offset(1.0, 1.0),
                        curve: Curves.easeInOut),
                    Text(
                      levels[index],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isHighlighted ? FontWeight.bold : FontWeight.normal,
                        color: isHighlighted ? Colors.black : Colors.grey,
                      ),
                    )
                  ],
                );
              }),
            ),
          ],
        ),
      ],
    );
  }
}
*/
