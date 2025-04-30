// ignore_for_file: override_on_non_overriding_member, unused_element, use_build_context_synchronously, prefer_const_constructors

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:sportify_final/pages/utility/api_constants.dart';

class ViewAllBooking extends StatefulWidget {
  const ViewAllBooking({super.key});

  @override
  State<ViewAllBooking> createState() => _ViewAllBookingState();
}

class _ViewAllBookingState extends State<ViewAllBooking> {
  String? userEmail;
  List<Map<String, dynamic>> bookings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userEmail = prefs.getString("email") ?? "";
    print(userEmail);

    if (userEmail!.isNotEmpty) {
      _fetchUserBookings();
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _cancelBookingUser(
      BuildContext context, String uuid, String email) async {
    final url = Uri.parse(
        "${ApiConstants.baseUrl}:5000/api/booking/cancelbookinguser/$uuid");

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userEmail": email}),
      );

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Success"),
            content: const Text("Booking cancelled successfully."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _fetchUserBookings(); // Refresh booking list
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Error"),
            content: const Text("This booking is already been cancelled."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Something went wrong"),
          content: Text("Error: $e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _fetchUserBookings() async {
    try {
      var url = Uri.parse(
          "${ApiConstants.baseUrl}:5000/api/booking/getuserbookings/$userEmail");
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        if (jsonResponse['Bookings'] is List) {
          setState(() {
            bookings =
                List<Map<String, dynamic>>.from(jsonResponse['Bookings']);
            isLoading = false;
          });
        } else {
          print("Invalid bookings format");
          setState(() => isLoading = false);
        }
      } else {
        print("Error fetching bookings: ${response.body}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Adjust breakpoint as needed

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Venue Bookings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookings.isEmpty
              ? Center(
                  child: Padding(
                    // Added padding for better readability
                    padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
                    child: Text(
                      "You have not made any bookings yet.",
                      style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey),
                      textAlign: TextAlign.center, // Center text horizontally
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(
                      vertical:
                          isSmallScreen ? 8.0 : 12.0), // Added vertical padding
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return Padding(
                      // Added padding around each BookingCard
                      padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8.0 : 12.0,
                          vertical: isSmallScreen ? 4.0 : 6.0),
                      child: BookingCard(
                        booking: booking,
                        onCancel: (uuid, email) =>
                            _cancelBookingUser(context, uuid, email),
                      ),
                    );
                  },
                ),
    );
  }
}

class BookingCard extends StatefulWidget {
  final Map<String, dynamic> booking;
  final Function(String uuid, String email) onCancel;

  const BookingCard({
    super.key,
    required this.booking,
    required this.onCancel,
  });

  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard> {
  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Booking"),
        content: const Text("Are you sure you want to cancel this booking?"),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBookingUser(String uuid, String email) async {
    print(email);
    final url = Uri.parse(
        "${ApiConstants.baseUrl}:5000/api/booking/cancelbookinguser/$uuid");

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userEmail": email}),
      );

      if (response.statusCode == 200) {
        // Success Dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Success"),
            content: Text("Booking cancelled successfully."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  // _fetchUserBookings(); // Refresh list
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
      } else {
        // Error Dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Error"),
            content: Text("This booking is already been cancelled"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Network/Error Dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Something went wrong"),
          content: Text("Error: $e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Venue Name
            Row(
              children: [
                const Icon(Icons.sports_soccer, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.booking["venueName"] ?? "Unknown Venue",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Booking Info
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text("Date: ${_formatDate(widget.booking["bookingDate"])}"),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text("Time: ${widget.booking["bookingTime"] ?? "N/A"}"),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  widget.booking["status"] == "Pending"
                      ? Icons.hourglass_empty
                      : widget.booking["status"] == "Confirmed"
                          ? Icons.check_circle
                          : Icons.cancel,
                  size: 18,
                  color: widget.booking["status"] == "Confirmed"
                      ? Colors.green
                      : widget.booking["status"] == "Rejected"
                          ? Colors.red
                          : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text("Status: ${widget.booking["status"] ?? "Pending"}"),
              ],
            ),

            const SizedBox(height: 16),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    bool confirm = await _showConfirmationDialog(context);
                    if (confirm) {
                      widget.onCancel(
                          widget.booking['uuid'], widget.booking['userEmail']);
                    }
                  },
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text(
                    "Cancel Booking",
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
