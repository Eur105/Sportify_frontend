// ignore_for_file: avoid_print, prefer_const_constructors, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportify_final/pages/utility/api_constants.dart';
// import 'package:sportify_final/pages/admin_panel/dashboard_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  _BookingsScreenState createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  List<Map<String, dynamic>> bookings = [];
  String selectedFilter = 'Confirmed'; // Default tab
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;
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
      fetchBookings(selectedFilter);
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchBookings(String status) async {
    setState(() {
      isLoading = true;
    });

    try {
      String url =
          "${ApiConstants.baseUrl}/api/booking/getbookingbystatus/$email/?status=$status";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          bookings = List<Map<String, dynamic>>.from(data['Bookings']);
        });
      } else {
        print("Failed to load bookings");
      }
    } catch (e) {
      print("Error: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> cancelBookingAdmin(int index, String bookingid) async {
    print(bookingid);
    final url =
        "${ApiConstants.baseUrl}/api/booking/cancelbookingadmin/$bookingid";

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'adminEmail': email}),
      );

      if (response.statusCode == 200) {
        setState(() {
          bookings[index]['status'] = 'Cancelled';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Booking cancelled successfully")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BookingsScreen(),
          ),
        );
      } else {
        print("Failed to cancel booking: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to cancel booking")),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred")),
      );
    }
  }

  void showConfirmationDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Cancellation"),
          content: Text("Are you sure you want to cancel this booking?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("No"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // cancelBooking(index);
              },
              child: Text("Yes", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void showAdminCancelDialog(
      BuildContext context, int index, String bookingid) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Admin Cancellation"),
          content: Text("Do you want to cancel this booking as admin?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("No"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                cancelBookingAdmin(index, bookingid);
              },
              child: Text("Yes", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // void cancelBooking(int index) {
  //   setState(() {
  //     bookings[index]['status'] = 'Cancelled';
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Bookings")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                filterChip("Confirmed"),
                filterChip("Rejected"),
                filterChip("Pending"),
              ],
            ),
          ),
          isLoading
              ? Center(
                  child: CircularProgressIndicator(),
                ) // Show loading spinner
              : Expanded(
                  child: ListView.builder(
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];

                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                BookingDetailsScreen(booking: booking),
                          ),
                        ),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          margin:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        booking['fullName'],
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    statusLabel(booking['status']),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_outlined,
                                        size: 20, color: Colors.grey[700]),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        booking['venueName'],
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.access_time,
                                        size: 20, color: Colors.grey[700]),
                                    SizedBox(width: 6),
                                    Text(
                                      booking['bookingTime'],
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        size: 18, color: Colors.grey[700]),
                                    SizedBox(width: 6),
                                    Text(
                                      booking['bookingDate'].split('T')[0],
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                // Row(
                                //   children: [
                                //     Icon(Icons.attach_money,
                                //         size: 20, color: Colors.grey[700]),
                                //     SizedBox(width: 6),
                                //     Text(
                                //       booking['totalAmount'].toString(),
                                //       style: TextStyle(fontSize: 16),
                                //     ),
                                //   ],
                                // ),
                                if (selectedFilter == 'Confirmed') ...[
                                  SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      onPressed: () => showAdminCancelDialog(
                                        context,
                                        index,
                                        booking['uuid'],
                                      ),
                                      icon: Icon(Icons.cancel,
                                          color: Colors.white),
                                      label: Text("Cancel Booking"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                      ),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget filterChip(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(color: Colors.black)),
        selected: selectedFilter == label,
        selectedColor: Colors.blue,
        onSelected: (bool selected) {
          setState(() {
            selectedFilter = label;
            fetchBookings(selectedFilter);
          });
        },
      ),
    );
  }

  Widget statusLabel(String status) {
    Color color = status == 'Confirmed'
        ? Colors.green
        : status == 'Cancelled'
            ? Colors.red
            : Colors.blue;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status, style: TextStyle(color: Colors.white)),
    );
  }
}

// Booking Details Page
class BookingDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> booking;
  const BookingDetailsScreen({required this.booking, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Booking Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "User Name: ${booking['fullName']}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  "Venue: ${booking['venueName']}",
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  "Booking Time: ${booking['bookingTime']}",
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  "Date: ${booking['bookingDate'].split('T')[0]}",
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  "Price: ${booking['totalAmount']}",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 12),
                _statusLabel(booking['status']),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusLabel(String status) {
    Color color = status == 'Confirmed'
        ? Colors.green
        : status == 'Cancelled'
            ? Colors.red
            : Colors.blue;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status, style: TextStyle(color: Colors.white)),
    );
  }
}
