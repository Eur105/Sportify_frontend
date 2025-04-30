// ignore_for_file: prefer_const_constructors, prefer_const_declarations, avoid_print, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportify_final/pages/utility/api_constants.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int) onNavigate;
  final int selectedIndex;
  const DashboardScreen({
    super.key,
    required this.onNavigate,
    required this.selectedIndex,
  });

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int bookingCountTotal = 0;
  int bookingCountPending = 0;
  bool isLoading = true;
  String? email = "";

  @override
  void initState() {
    super.initState();
    _loademail();
  }

  Future<void> _loademail() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    email = prefs.getString('email');
    print(email);
    if (email!.isNotEmpty) {
      fetchBookingCounts();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchBookingCounts() async {
    final apiUrl =
        "${ApiConstants.baseUrl}:5000/api/booking/getbookingcount/$email";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          bookingCountTotal = data['BookingCountTotal'] ?? 0;
          bookingCountPending = data['bookingCountPending'] ?? 0;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch data");
      }
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome, Admin!",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          isLoading
              ? Center(child: CircularProgressIndicator())
              : SizedBox(
                  height: screenHeight * 0.75,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDashboardCard(
                            Icons.book,
                            "Bookings",
                            "$bookingCountTotal",
                            "Recent bookings",
                            Colors.green,
                            context,
                            screenHeight,
                            0.6,
                            () => widget.onNavigate(1),
                          ),
                          _buildDashboardCard(
                            Icons.insert_chart,
                            "Approvals",
                            "$bookingCountPending",
                            "Pending Approvals",
                            Colors.orange,
                            context,
                            screenHeight,
                            0.4,
                            () => widget.onNavigate(2),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      _buildLargeDashboardCard(
                        Icons.settings,
                        "Settings",
                        "System preferences",
                        Colors.purple,
                        context,
                        screenHeight,
                        () => widget.onNavigate(3),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    IconData icon,
    String title,
    String count,
    String subtitle,
    Color color,
    BuildContext context,
    double screenHeight,
    double progress,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.45,
        height: screenHeight * 0.35,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 6,
          shadowColor: color.withOpacity(0.5),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [color.withOpacity(0.8), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.white, size: 40),
                SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                Divider(color: Colors.white.withOpacity(0.5)),
                Text(
                  count,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLargeDashboardCard(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    BuildContext context,
    double screenHeight,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        height: screenHeight * 0.25,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 6,
          shadowColor: color.withOpacity(0.5),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [color.withOpacity(0.8), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.white, size: 40),
                SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
