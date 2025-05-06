import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sportify_final/pages/utility/api_constants.dart';

class VenueSearchField extends StatefulWidget {
  final Function(String venueName, double latitude, double longitude)
      onVenueSelected;
  final String? initialValue;

  const VenueSearchField({
    Key? key,
    required this.onVenueSelected,
    this.initialValue,
  }) : super(key: key);

  @override
  State<VenueSearchField> createState() => _VenueSearchFieldState();
}

class _VenueSearchFieldState extends State<VenueSearchField> {
  final TextEditingController _venueController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _venues = [];
  bool _isLoading = false;
  bool _showDropdown = false;
  double? _selectedLat;
  double? _selectedLon;
  String? _selectedVenueName;

  // Debounce timer to avoid excessive API calls
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      _venueController.text = widget.initialValue!;
      _selectedVenueName = widget.initialValue;
    }

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _showDropdown = true;
        });
      } else {
        // Delay hiding to allow selection
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _showDropdown = false;
            });
          }
        });
      }
    });

    _venueController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _venueController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _venueController.text;
      if (query.isNotEmpty && query.length >= 3) {
        _searchVenues(query);
      } else {
        setState(() {
          _venues = [];
        });
      }
    });
  }

  Future<void> _searchVenues(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/api/venue/places?q=$query'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _venues = List<Map<String, dynamic>>.from(data['places']);
          _isLoading = false;
          _showDropdown = _venues.isNotEmpty;
        });
      } else {
        setState(() {
          _venues = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error searching venues: $e');
      setState(() {
        _venues = [];
        _isLoading = false;
      });
    }
  }

  void _selectVenue(Map<String, dynamic> venue) {
    final name = venue['name'] as String;
    final neighborhood = venue['address']['neighbourhood'] as String? ?? '';
    final displayName = neighborhood.isNotEmpty ? '$name, $neighborhood' : name;

    _venueController.text = displayName;
    _selectedVenueName = displayName;
    _selectedLat = double.parse(venue['lat']);
    _selectedLon = double.parse(venue['lon']);

    widget.onVenueSelected(displayName, _selectedLat!, _selectedLon!);

    setState(() {
      _showDropdown = false;
    });

    // Remove focus to dismiss keyboard
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _venueController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: 'Select Venue',
            hintText: 'Start typing to search venues...',
            prefixIcon: const Icon(Icons.location_on),
            suffixIcon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : _venueController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _venueController.clear();
                          setState(() {
                            _venues = [];
                            _selectedLat = null;
                            _selectedLon = null;
                            _selectedVenueName = null;
                          });
                        },
                      )
                    : null,
          ),
          validator: (value) =>
              value == null || value.isEmpty || _selectedLat == null
                  ? 'Please select a venue from the dropdown'
                  : null,
        ),
        if (_showDropdown && _venues.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 250),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _venues.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final venue = _venues[index];
                final name = venue['name'] as String;
                final neighborhood =
                    venue['address']['neighbourhood'] as String? ?? '';
                final city = venue['address']['city'] as String? ??
                    venue['address']['town'] as String? ??
                    '';

                return ListTile(
                  dense: true,
                  title: Text(name),
                  subtitle: Text(
                    [
                      if (neighborhood.isNotEmpty) neighborhood,
                      if (city.isNotEmpty) city,
                    ].join(', '),
                    style: const TextStyle(fontSize: 12),
                  ),
                  leading: const Icon(Icons.location_on, size: 20),
                  onTap: () => _selectVenue(venue),
                );
              },
            ),
          ),
        if (_selectedLat != null && _selectedLon != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Location: ${_selectedLat!.toStringAsFixed(6)}, ${_selectedLon!.toStringAsFixed(6)}',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
