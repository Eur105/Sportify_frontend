import 'package:flutter/material.dart';
//import 'package:sportify_final/pages/utility/location_service.dart';
import 'package:sportify_final/pages/utility/locationservice.dart';

class LocationAppBarWidget extends StatefulWidget {
  final Function(String, String?)? onLocationChanged;

  const LocationAppBarWidget({super.key, this.onLocationChanged});

  @override
  State<LocationAppBarWidget> createState() => LocationAppBarWidgetState();
}

class LocationAppBarWidgetState extends State<LocationAppBarWidget> {
  final LocationService _locationService = LocationService();
  bool _isLoading = false;
  String _locationText = 'Getting location...';
  String _fullLocationDetails = '';

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.onLocationChanged != null) {
          widget.onLocationChanged!(
              _fullLocationDetails, _locationService.locationName);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              size: 16,
              color: Colors.blue[700],
            ),
            const SizedBox(width: 4),
            if (_isLoading)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.blue[700],
                ),
              )
            else
              Flexible(
                child: Text(
                  _locationText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[900],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: Colors.blue[700],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getLocation() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _locationText = 'Getting location...';
    });

    bool success = await _locationService.getCurrentLocation();

    if (success && mounted) {
      // Use the location name from the geocoding API
      _locationText = _locationService.locationName ?? 'Unknown location';

      // Create full location details for display in expanded view
      _fullLocationDetails =
          'Location: ${_locationService.latitude?.toStringAsFixed(6)}, ${_locationService.longitude?.toStringAsFixed(6)}';

      // Notify parent widget if callback is provided
      if (widget.onLocationChanged != null) {
        widget.onLocationChanged!(
            _fullLocationDetails, _locationService.locationName);
      }
    } else {
      _locationText = 'Location unavailable';
      _fullLocationDetails =
          _locationService.errorMessage ?? 'Failed to get location';
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Method to refresh location that can be called from outside
  Future<void> refreshLocation() async {
    await _getLocation();
  }
}
