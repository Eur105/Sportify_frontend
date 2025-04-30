// ignore_for_file: use_build_context_synchronously, prefer_const_constructors, unnecessary_brace_in_string_interps, use_super_parameters

import 'package:flutter/material.dart';
//import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sportify_final/pages/notification_page.dart';
import 'package:sportify_final/pages/utility/api_constants.dart';
import 'package:sportify_final/pages/utility/bottom_navbar.dart';
import 'package:sportify_final/pages/utility/profile.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({Key? key}) : super(key: key);

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final Color backgroundGrey = const Color(0xFFF5F5F5);
  final TextEditingController dateController = TextEditingController();
  final TextEditingController venueController = TextEditingController();
  final TextEditingController timeSlotController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  String _formattedTimeSlot = "";
  bool isBooking = false;
  int price = 0;

  List<String> venues = [
    "Umar Minhas futsal ground",
    "Kokan ground",
    "spiritfield ground"
  ];
  List<String> timeSlots = ["9 AM to 11 AM", "1 PM - 3 PM", "5 PM - 7 PM"];

  Future<void> _selectDate() async {
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

  void _updateTimeSlot() {
    if (startTimeController.text.isNotEmpty &&
        endTimeController.text.isNotEmpty) {
      setState(() {
        _formattedTimeSlot =
            "${startTimeController.text}-${endTimeController.text}";
      });
    }
  }

  Future<void> _selectTime(BuildContext context,
      TextEditingController controller, String type) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      final String formattedTime = pickedTime.format(context);

      if (type == "end" && startTimeController.text.isNotEmpty) {
        final start = _parseTimeOfDay(startTimeController.text);
        final end = pickedTime;

        if (_isBefore(end, start)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("End time cannot be before start time."),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (type == "start" && endTimeController.text.isNotEmpty) {
        final start = pickedTime;
        final end = _parseTimeOfDay(endTimeController.text);

        if (_isBefore(end, start)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Start time cannot be after end time."),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      controller.text = formattedTime;
      _updateTimeSlot();
    }
  }

  TimeOfDay _parseTimeOfDay(String timeString) {
    final parts = timeString.split(RegExp('[: ]'));
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    String period = parts[2].toLowerCase();

    if (period == 'pm' && hour != 12) hour += 12;
    if (period == 'am' && hour == 12) hour = 0;

    return TimeOfDay(hour: hour, minute: minute);
  }

  DateTime _timeOfDayToDateTime(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  bool _isBefore(TimeOfDay t1, TimeOfDay t2) {
    final dt1 = _timeOfDayToDateTime(t1);
    final dt2 = _timeOfDayToDateTime(t2);
    return dt1.isBefore(dt2);
  }

  Future<void> _bookVenue() async {
    if (dateController.text.isEmpty ||
        venueController.text.isEmpty ||
        startTimeController.text.isEmpty ||
        endTimeController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Incomplete Selection"),
          content: const Text("Please select a date, venue, and time slot."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userEmail = prefs.getString('email');
    String? firstName = prefs.getString('firstName');
    String? lastName = prefs.getString('lastName');
    String? contactNo = prefs.getString('phoneNo');
    String fullName = "$firstName $lastName";

    Map<String, dynamic> bookingData = {
      "userEmail": userEmail,
      "fullName": fullName,
      "contactNo": contactNo,
      "bookingDate": dateController.text,
      "bookingTime": _formattedTimeSlot,
      "venueName": venueController.text,
    };

    setState(() => isBooking = true);

    try {
      var response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}:5000/api/booking/addnewbooking"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(bookingData),
      );

      if (response.statusCode == 200) {
        var responseBody = jsonDecode(response.body);

        // ✅ Extract the venueId from the response
        String venueId = responseBody['message']['venueId'];
        debugPrint("Extracted venueId: $venueId");

        // ✅ Now you can use this venueId if needed
        useVenueId(venueId); // Example usage right after booking

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Booking Request Sent"),
            content: Text(
              "Booking Request For ${venueController.text} on ${dateController.text} from ${startTimeController.text}-${endTimeController.text} has been sent successfully. \nYou will receive a confirmation email shortly.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Booking Failed"),
            content: Text(
              "An error occurred while processing your booking. Please try again. \n\nDetails: ${response.body}",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
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
          title: const Text("Error"),
          content: Text("An unexpected error occurred: $e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } finally {
      setState(() => isBooking = false);
    }
  }

  Future<void> useVenueId(String venueId) async {
    try {
      var response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}:5000/api/venue/getvenue/$venueId"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);

        // Extracting the price from the response
        var venueData = responseData['Venue'];
        price = venueData['price'];

        debugPrint(
            "Successfully fetched venue price: $price for venueId: $venueId");

        // Now you can use the price variable as needed
        // Example: you can store it, return it, or pass it to another function
      } else {
        debugPrint(
            "Failed to fetch data for venueId: $venueId. Status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error while fetching venue details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Adjust breakpoint as needed

    return Scaffold(
      backgroundColor: backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Venue Booking',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => NotificationPage()));
            },
            icon: const Icon(Icons.notifications),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ProfilePage()));
            },
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text("Book a Venue",
                    style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 22,
                        fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: isSmallScreen ? 15 : 20), // Responsive spacing
              TextField(
                controller: dateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Select Date",
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _selectDate),
                ),
              ),
              SizedBox(height: isSmallScreen ? 15 : 20), // Responsive spacing
              DropdownButtonFormField<String>(
                value:
                    venueController.text.isEmpty ? null : venueController.text,
                items: venues.map((venue) {
                  return DropdownMenuItem(
                    value: venue,
                    child: Text(venue),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    venueController.text = value ?? "";
                  });
                },
                decoration: const InputDecoration(
                  labelText: "Select Venue",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: isSmallScreen ? 15 : 20), // Responsive spacing
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: startTimeController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Start Time',
                        border: OutlineInputBorder(),
                      ),
                      onTap: () =>
                          _selectTime(context, startTimeController, "start"),
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 10), // Responsive spacing
                  Expanded(
                    child: TextFormField(
                      controller: endTimeController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'End Time',
                        border: OutlineInputBorder(),
                      ),
                      onTap: () =>
                          _selectTime(context, endTimeController, "end"),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 25 : 30), // Responsive spacing
              Center(
                child: isBooking
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _bookVenue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: isSmallScreen ? 30 : 50,
                          ),
                        ),
                        child: const Text(
                          "Book Venue",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavbar(),
    );
  }
}
