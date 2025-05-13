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
import 'package:url_launcher/url_launcher.dart';

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
  final TextEditingController priceController = TextEditingController();
  String _formattedTimeSlot = "";
  bool isBooking = false;
  int price = 0;

  List<String> venues = [
    "Umar Minhas futsal ground",
    "Kokan ground",
    "spiritfield ground"
  ];
  List<String> timeSlots = ["9 AM to 11 AM", "1 PM - 3 PM", "5 PM - 7 PM"];

  final Map<String, String> venueMapLinks = {
    "Umar Minhas futsal ground": "https://maps.app.goo.gl/YmzxqZSsz5dpi66k9",
    "Kokan ground": "https://maps.app.goo.gl/zWmz71W5qXUT7rMt9",
    "spiritfield ground": "https://maps.app.goo.gl/BEH8GEueQTcC82g49",
  };

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

  Future _selectTime(BuildContext context, TextEditingController controller,
      String type) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        // Remove the 24-hour format to ensure AM/PM is available
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      // Format time with AM/PM
      final String formattedTime = _formatTimeWithAmPm(pickedTime, context);

      if (type == "end" && startTimeController.text.isNotEmpty) {
        final start = _parseTimeOfDay(startTimeController.text);
        final end = pickedTime;

        // Handle time range validation with special handling for overnight bookings
        if (!_isValidTimeRange(start, end)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Invalid time range. For overnight bookings, start time should be in the evening and end time in the morning."),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (type == "start" && endTimeController.text.isNotEmpty) {
        final start = pickedTime;
        final end = _parseTimeOfDay(endTimeController.text);

        // Handle time range validation with special handling for overnight bookings
        if (!_isValidTimeRange(start, end)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Invalid time range. For overnight bookings, start time should be in the evening and end time in the morning."),
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

// Format time with explicit AM/PM
  String _formatTimeWithAmPm(TimeOfDay time, BuildContext context) {
    // Use the hour and minute values to create a custom format with AM/PM
    final int hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final String minute = time.minute.toString().padLeft(2, '0');
    final String period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  TimeOfDay _parseTimeOfDay(String timeString) {
    final parts = timeString.split(RegExp('[: ]'));
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    String period = parts[2].toUpperCase();

    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;

    return TimeOfDay(hour: hour, minute: minute);
  }

// Convert TimeOfDay to DateTime for easier comparison
  DateTime _timeOfDayToDateTime(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

// Check if a time range is valid, with special handling for overnight bookings
  bool _isValidTimeRange(TimeOfDay start, TimeOfDay end) {
    DateTime dtStart = _timeOfDayToDateTime(start);
    DateTime dtEnd = _timeOfDayToDateTime(end);

    // If end time is earlier than start time, we need to check if it's a reasonable overnight booking
    if (dtEnd.isBefore(dtStart) || dtEnd.isAtSameMomentAs(dtStart)) {
      // For overnight bookings, typically the end time should be within a reasonable
      // timeframe after midnight (e.g., 11 PM to 2 AM makes sense, but 9 PM to 8 PM doesn't)

      // Convert to minutes since midnight for easier comparison
      int startMinutes = start.hour * 60 + start.minute;
      int endMinutes = end.hour * 60 + end.minute;

      // Check if start time is in the evening (after 6 PM) and end time is in the morning (before noon)
      bool startInEvening = startMinutes >= 18 * 60; // After 6 PM
      bool endInMorning = endMinutes < 12 * 60; // Before noon

      // For a valid overnight booking: start should be evening, end should be morning
      return startInEvening && endInMorning;
    }

    // Normal same-day booking where end is after start
    return dtEnd.isAfter(dtStart);
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
        Uri.parse("${ApiConstants.baseUrl}/api/booking/addnewbooking"),
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
              "A booking already exists in this time frame",
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
          content: Text("An unexpected error occurred"),
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
        Uri.parse("${ApiConstants.baseUrl}/api/venue/getvenue/$venueId"),
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
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          'Venue Booking',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => NotificationPage()));
            },
            icon: const Icon(
              Icons.notifications,
              color: Colors.black,
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ProfilePage()));
            },
            icon: const Icon(
              Icons.person,
              color: Colors.black,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                "Book a Venue",
                style: TextStyle(
                  fontSize: isSmallScreen ? 20 : 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: dateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: "Select Date",
                          prefixIcon: const Icon(Icons.date_range),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: _selectDate),
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: venueController.text.isEmpty
                            ? null
                            : venueController.text,
                        items: venues.map((venue) {
                          return DropdownMenuItem(
                            value: venue,
                            child: Text(venue),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            venueController.text = value ?? "";
                            if (value == "Umar Minhas futsal ground") {
                              priceController.text = "5000";
                            } else if (value == "Kokan ground") {
                              priceController.text = "4000";
                            } else if (value == "spiritfield ground") {
                              priceController.text = "3500";
                            } else {
                              priceController.text = "";
                            }
                          });
                        },
                        decoration: InputDecoration(
                          labelText: "Select Venue",
                          prefixIcon: const Icon(Icons.sports_soccer),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      if (venueController.text.isNotEmpty)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () async {
                              final url = venueMapLinks[venueController.text];
                              if (url != null &&
                                  await canLaunchUrl(Uri.parse(url))) {
                                await launchUrl(Uri.parse(url),
                                    mode: LaunchMode.externalApplication);
                              }
                            },
                            icon: const Icon(Icons.map, color: Colors.green),
                            label: const Text("View on Map"),
                          ),
                        ),
                      if (venueController.text.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 16, bottom: 12),
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: AssetImage(
                                  "assets/picture/${venueController.text.toLowerCase().replaceAll(' ', '_')}.jpg"),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      TextField(
                        controller: priceController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: "Price per Hour",
                          // prefixIcon: const Icon(Icons.attach_money),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: startTimeController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Start Time',
                                prefixIcon: const Icon(Icons.access_time),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onTap: () => _selectTime(
                                  context, startTimeController, "start"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: endTimeController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'End Time',
                                prefixIcon: const Icon(Icons.access_time),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onTap: () => _selectTime(
                                  context, endTimeController, "end"),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      Center(
                        child: isBooking
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _bookVenue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30)),
                                  padding: EdgeInsets.symmetric(
                                    vertical: 15,
                                    horizontal: isSmallScreen ? 30 : 50,
                                  ),
                                  elevation: 4,
                                ),
                                child: const Text(
                                  "Book Venue",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
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
      bottomNavigationBar: BottomNavbar(),
    );
  }
}
