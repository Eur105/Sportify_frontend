// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:sportify_final/pages/admin_panel/approvals_screen.dart';
import 'package:sportify_final/pages/admin_panel/bookings_screen.dart';
import 'package:sportify_final/pages/admin_panel/dashboard_screen.dart';
import 'package:sportify_final/pages/admin_panel/settings_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final String venueName = "Sportify Arena";

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      DashboardScreen(onNavigate: _onItemTapped, selectedIndex: 1),
      BookingsScreen(),
      ApprovalsScreen(),
      SettingsScreen(),
    ]);
  }

  String _getScreenTitle(int index) {
    switch (index) {
      case 0:
        return "Dashboard";
      case 1:
        return "Bookings";
      case 2:
        return "Approvals";
      case 3:
        return "Settings";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.lightBlueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              venueName,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              _getScreenTitle(_selectedIndex),
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
      body: Column(children: [Expanded(child: _screens[_selectedIndex])]),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.blue[200],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.white,
        elevation: 10,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Bookings'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Approvals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
