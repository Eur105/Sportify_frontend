// ignore_for_file: curly_braces_in_flow_control_structures, unused_import, unused_field, prefer_const_constructors, unused_element, use_key_in_widget_constructors, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SportFilterPage extends StatefulWidget {
  @override
  _SportFilterPageState createState() => _SportFilterPageState();
}

class _SportFilterPageState extends State<SportFilterPage> {
  String? _selectedSport;
  String? _selectedDifficulty;
  String? _venueName;
  DateTime? _selectedDate;

  final List<String> sports = ['Football', 'Cricket', 'Badminton'];
  final List<String> difficulties = ['Beginner', 'Average', 'Strong', 'Pro'];

  final TextEditingController _venueController = TextEditingController();

  void _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: 1)),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _applyFilters() {
    Map<String, String> filters = {};

    if (_selectedSport != null) filters['sportType'] = _selectedSport!;
    if (_selectedDifficulty != null)
      filters['opponentDifficulty'] = _selectedDifficulty!;
    if (_venueController.text.isNotEmpty)
      filters['venueName'] = _venueController.text;

    Navigator.pop(context, filters);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Filter Games",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Sport Type",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: sports
                  .map((sport) => DropdownMenuItem(
                        value: sport,
                        child: Text(sport),
                      ))
                  .toList(),
              value: _selectedSport,
              onChanged: (value) => setState(() => _selectedSport = value),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Opponent Difficulty",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: difficulties
                  .map((level) => DropdownMenuItem(
                        value: level,
                        child: Text(level),
                      ))
                  .toList(),
              value: _selectedDifficulty,
              onChanged: (value) => setState(() => _selectedDifficulty = value),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _venueController,
              decoration: InputDecoration(
                labelText: "Venue Name",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 16),
            Spacer(),
            ElevatedButton.icon(
              onPressed: _applyFilters,
              icon: Icon(Icons.filter_alt),
              label: Text("Apply Filters"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: StadiumBorder(),
              ),
            )
          ],
        ),
      ),
    );
  }
}
