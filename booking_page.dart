// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? selectedDate;
  String? selectedVenue;
  String? selectedTimeSlot;

  // List of venues and time slots for selection
  List<String> venues = ["Indoor Court", "Outdoor Field", "Swimming Pool"];
  List<String> timeSlots = ["9 AM - 11 AM", "1 PM - 3 PM", "5 PM - 7 PM"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
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
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heading text
              Center(
                child: Text(
                  "Book a Venue",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 20),

              // Date picker
              Text(
                "Select Date:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 10),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedDate != null
                            ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                            : "Choose a date",
                        style: TextStyle(fontSize: 16),
                      ),
                      Icon(Icons.calendar_today, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Venue type Autocomplete
              Text(
                "Select Venue:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 10),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<String>.empty();
                  }
                  return venues.where((String option) {
                    return option
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  setState(() {
                    selectedVenue = selection;
                  });
                },
                fieldViewBuilder: (BuildContext context,
                    TextEditingController textEditingController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted) {
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    onFieldSubmitted: (String value) {
                      onFieldSubmitted();
                      setState(() {
                        selectedVenue = value;
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      hintText: "Choose a venue",
                    ),
                  );
                },
                // Allow the user to enter any text, even if it's not in the suggestions
                displayStringForOption: (String option) => option,
              ),
              SizedBox(height: 20),

              // Time slot dropdown
              Text(
                "Select Time Slot:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedTimeSlot,
                items: timeSlots.map((slot) {
                  return DropdownMenuItem(
                    value: slot,
                    child: Text(slot),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedTimeSlot = value;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                ),
                hint: Text("Choose a time slot"),
              ),
              SizedBox(height: 30),

              // Book Venue Button
              Center(
                child: ElevatedButton(
                  onPressed: _bookVenue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                  child: Text(
                    "Book Venue",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Reset and Filter Buttons
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 78,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(Icons.home, 'Home', () {
              // Navigate to Home
            }),
            _buildBottomNavItem(Icons.people_alt, 'Play', () {
              // Navigate to Play
            }),
            _buildBottomNavItem(Icons.book_online, 'Book', () {
              // Navigate to Book
            }),
            _buildBottomNavItem(Icons.chat, 'Chat', () {
              // Navigate to Chat
            }),
            _buildBottomNavItem(Icons.school, 'Learn', () {
              // Navigate to Learn
            }),
          ],
        ),
      ),
    );
  }

  // Helper method to build bottom navigation items
  Widget _buildBottomNavItem(IconData icon, String label, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onTap,
        ),
        Text(label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // Function to show date picker
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2021),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // Function to handle the "Book Venue" button press
  void _bookVenue() {
    if (selectedDate == null ||
        selectedVenue == null ||
        selectedVenue!.trim().isEmpty ||
        selectedTimeSlot == null) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Incomplete Selection"),
            content:
                Text("Please select a date, venue, and time slot to proceed."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    } else {
      // Venue booking logic goes here
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Booking Successful"),
            content: Text(
                "You have successfully booked the \"$selectedVenue\" on ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year} from $selectedTimeSlot."),
          );
        },
      );
    }
  }
}
