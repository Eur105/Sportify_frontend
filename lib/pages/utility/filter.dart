// ignore_for_file: curly_braces_in_flow_control_structures, unused_import, unused_field, prefer_const_constructors, unused_element, use_key_in_widget_constructors, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
  int? _selectedDistance;
  final List<int> _distanceOptions = [1, 5, 10, 15, 25];

  // double _distance = 5.0; // default nearby distance
  String _locationStatus = '';
  double? _latitude;
  double? _longitude;

  Future<bool> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationStatus =
              'Location services are disabled. Please enable them.';
        });
        return false;
      }

      // Check location permission
      permission = await Geolocator.checkPermission();

      // Handle denied permission
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationStatus = 'Location permissions are denied.';
          });
          return false;
        }
      }

      // Handle permanently denied permission
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatus =
              'Location permissions are permanently denied. Please enable them in settings.';
        });
        return false;
      }

      // Get position if permission is granted
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationStatus = 'Location fetched successfully!';
        print("lat is $_latitude and long is $_longitude");
      });
      return true;
    } catch (e) {
      setState(() {
        _locationStatus = 'Error fetching location: $e';
      });
      return false;
    }
  }

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
    Map<String, dynamic> filters = {};

    if (_selectedSport != null) filters['sportType'] = _selectedSport!;
    if (_selectedDifficulty != null)
      filters['opponentDifficulty'] = _selectedDifficulty!;
    if (_venueController.text.isNotEmpty)
      filters['venueName'] = _venueController.text;
    if (_latitude != null && _longitude != null && _selectedDistance != null) {
      filters['latitude'] = _latitude;
      filters['longitude'] = _longitude;
      filters['distance'] = _selectedDistance! * 1000;
    }

    Navigator.pop(context, filters);
  }

  @override
  void initState() {
    super.initState();
    // Call location function when the page initializes
    _getCurrentLocation();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Filter Games",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
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
            // if (_latitude != null && _longitude != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: "Distance (km)",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  value: _selectedDistance,
                  items: _distanceOptions.map((distance) {
                    return DropdownMenuItem<int>(
                      value: distance,
                      child: Text("$distance km"),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDistance = value;
                    });
                  },
                ),
              ],
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
