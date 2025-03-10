// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:sportify_final/pages/utility/bottom_navbar.dart';

class PlayPage extends StatefulWidget {
  const PlayPage({super.key});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  int selectedTab = 1; // Default to "My Sports"
  List<String> createdGames = []; // List of created games (initially empty)

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Number of tabs (Games, My Sports)
      initialIndex: selectedTab,
      child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.notifications, color: Colors.black),
              ),
              IconButton(
                onPressed: () {},
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
            ),
          ),
          body: TabBarView(
            children: [
              // Games Tab
              _buildGamesTab(),

              // My Sports Tab
              _buildMySportsTab(),
            ],
          ),

          // Bottom Navigation Bar
          bottomNavigationBar: BottomNavbar()),
    );
  }

  Widget _buildGamesTab() {
    return Column(
      children: [
        Expanded(
          child: createdGames.isEmpty
              ? Center(
                  child: Text(
                    "No games created yet",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                )
              : ListView.builder(
                  itemCount: createdGames.length,
                  itemBuilder: (context, index) {
                    return ListTile();
                  },
                ),
        ),
      ],
    );
  }

  // My Sports Tab - Displays a "Create Game" button and some UI text
  Widget _buildMySportsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Get started by creating your first game!",
            style: TextStyle(fontSize: 18, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Navigation to another page to create a game will be added here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: Text(
              "Create a Game",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
