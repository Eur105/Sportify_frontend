// ignore: unused_import
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Variables to store location data
  double? latitude;
  double? longitude;
  String? errorMessage;
  String? locationName;

  // Function to request permission and get current location
  Future<bool> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        errorMessage =
            'Location services are disabled. Please enable them in your device settings.';
        return false;
      }

      // Check location permission
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          errorMessage = 'Location permissions are denied';
          return false;
        }
      }

      // If permission is denied forever, show appropriate message
      if (permission == LocationPermission.deniedForever) {
        errorMessage =
            'Location permissions are permanently denied, we cannot request permissions.';
        return false;
      }

      // When we reach here, permissions are granted and we can continue
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      latitude = position.latitude;
      longitude = position.longitude;

      // Try to get location name using reverse geocoding
      await getLocationNameFromCoordinates();

      return true;
    } catch (e) {
      errorMessage = 'Error getting location: $e';
      return false;
    }
  }

  // Function to get location name from coordinates using OpenStreetMap API
  Future<void> getLocationNameFromCoordinates() async {
    if (latitude == null || longitude == null) return;

    try {
      final response = await http.get(
        Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=json'),
        headers: {
          'User-Agent':
              'Sportify App', // OpenStreetMap requires a User-Agent header
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Extract useful location information
        if (data['display_name'] != null) {
          final String fullAddress = data['display_name'];

          // Parse the address to get a more user-friendly format
          String? city, area;

          if (data['address'] != null) {
            // Try to get the most relevant part of the address
            city = data['address']['city'] ??
                data['address']['town'] ??
                data['address']['village'] ??
                data['address']['suburb'];

            area = data['address']['suburb'] ??
                data['address']['neighbourhood'] ??
                data['address']['road'];
          }

          // Create a concise location name
          if (city != null && area != null) {
            locationName = '$area, $city';
          } else if (city != null) {
            locationName = city;
          } else if (area != null) {
            locationName = area;
          } else {
            // Fallback to a shortened version of the full address
            final addressParts = fullAddress.split(',');
            if (addressParts.length > 2) {
              locationName = '${addressParts[0]}, ${addressParts[1]}';
            } else {
              locationName = fullAddress;
            }
          }
        } else {
          locationName = 'Unknown location';
        }
      } else {
        locationName = 'Location lookup failed';
      }
    } catch (e) {
      locationName = 'Error getting location name';
      print('Error getting location name: $e');
    }
  }

  // Function to get the last known position (faster but might be less accurate)
  Future<bool> getLastKnownPosition() async {
    try {
      Position? position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        latitude = position.latitude;
        longitude = position.longitude;
        await getLocationNameFromCoordinates();
        return true;
      } else {
        // If no last known position is available, get current location
        return await getCurrentLocation();
      }
    } catch (e) {
      errorMessage = 'Error getting last known location: $e';
      return false;
    }
  }

  // Function to stream location updates
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update if device moves 10 meters
      ),
    );
  }
}
