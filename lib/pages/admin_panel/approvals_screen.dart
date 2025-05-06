// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, library_private_types_in_public_api, avoid_print

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportify_final/pages/utility/api_constants.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  _ApprovalsScreenState createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  bool isLoading = false;
  String? email = "";
  List<Map<String, dynamic>> bookings = [];

  @override
  void initState() {
    super.initState();
    _loademail();
    //  fetchBookings();
  }

  Future<void> _loademail() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    email = prefs.getString('email');
    print(email);
    if (email!.isNotEmpty) {
      fetchBookings();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchBookings() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/booking/getadminbookings/$email'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (responseData.containsKey('Bookings')) {
        setState(() {
          // ✅ Filter only pending bookings
          bookings = List<Map<String, dynamic>>.from(responseData['Bookings'])
              .where(
                (booking) => booking['status'] == 'Pending',
              ) // ✅ Keep only pending ones
              .toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid API response structure")),
        );
      }
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to fetch bookings")));
    }
  }

  void showConfirmationDialog(
    BuildContext context,
    String action,
    String bookingUuid,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm $action"),
          content: Text("Are you sure you want to $action this booking?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                processApproval(action, bookingUuid); // ✅ Send UUID here
              },
              child: Text(
                action,
                style: TextStyle(
                  color: action == 'Approve' ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void processApproval(String action, String bookingUuid) async {
    final apiUrl =
        "${ApiConstants.baseUrl}/api/booking/confirmbooking/$bookingUuid";

    final response = await http.put(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "status": action, // ✅ Send status directly
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        // ✅ Create a new list excluding the updated booking
        bookings = bookings
            .where((booking) => booking['uuid'] != bookingUuid)
            .toList();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Booking $action successfully")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update booking status")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.grey[200],
                  elevation: 3,
                  margin: EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "User: ${booking['fullName']}",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text("Venue: ${booking['venueName']}"),
                        Text("Booking Time: ${booking['bookingTime']}"),
                        Text("Date: ${booking['bookingDate'].split('T')[0]}"),
                        Text("Price: ${booking['totalAmount']}"),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () => showConfirmationDialog(
                                context,
                                "Confirmed",
                                booking['uuid'], // ✅ Pass UUID
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: Text(
                                "Approve",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () => showConfirmationDialog(
                                context,
                                "Rejected",
                                booking['uuid'], // ✅ Pass UUID
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: Text(
                                "Reject",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
