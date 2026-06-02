import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rideal/screens/FutureRides/FutureRidesList.dart';
import 'package:rideal/authservices.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rideal/screens/FutureRides/futurerideshistory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class FutureRides extends StatefulWidget {
  const FutureRides({super.key});

  @override
  State<FutureRides> createState() => _FutureRidesState();
}

class _FutureRidesState extends State<FutureRides> {
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();
  final TextEditingController _personsController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  
  // For storing coordinates
  double? pickupLat, pickupLng, dropLat, dropLng;
  
  // For place suggestions
  List<Map<String, dynamic>> _pickupSuggestions = [];
  List<Map<String, dynamic>> _dropSuggestions = [];
  bool _showPickupSuggestions = false;
  bool _showDropSuggestions = false;
  
  static const String baseUrl = "https://backend.ridealmobility.com";
  
  // Add your Google Places API key here
  static const String googlePlacesApiKey = "AIzaSyBQx7m5RcWfgRtYZzvwxRLcMa3Ks-Z0xUI";

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Automatically get location when screen loads
  }

  @override
  void dispose() {
    _timeController.dispose();
    _dateController.dispose();
    _pickupController.dispose();
    _dropController.dispose();
    _personsController.dispose();
    super.dispose();
  }

  // Get user's current location
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permissions are denied', isError: true);
          setState(() => _isLoadingLocation = false);
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('Location permissions are permanently denied', isError: true);
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Convert coordinates to address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = "${place.name}, ${place.locality}, ${place.administrativeArea}";
        
        setState(() {
          _pickupController.text = address;
          pickupLat = position.latitude;
          pickupLng = position.longitude;
        });
        
        _showSnackBar('Current location loaded', isError: false);
      }
    } catch (e) {
      _showSnackBar('Failed to get location: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  // Search places using Google Places API
  Future<void> _searchPlaces(String query, bool isPickup) async {
    if (query.length < 3) {
      setState(() {
        if (isPickup) {
          _pickupSuggestions.clear();
          _showPickupSuggestions = false;
        } else {
          _dropSuggestions.clear();
          _showDropSuggestions = false;
        }
      });
      return;
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(query)}'
        '&key=$googlePlacesApiKey'
        '&components=country:in' // Restrict to India
        '&types=establishment|geocode',
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          final suggestions = predictions.map((prediction) => {
            'place_id': prediction['place_id'],
            'description': prediction['description'],
          }).toList();

          setState(() {
            if (isPickup) {
              _pickupSuggestions = suggestions;
              _showPickupSuggestions = true;
            } else {
              _dropSuggestions = suggestions;
              _showDropSuggestions = true;
            }
          });
        }
      }
    } catch (e) {
      print('Error searching places: $e');
    }
  }

  // Get place details from place_id
  Future<void> _getPlaceDetails(String placeId, bool isPickup) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&key=$googlePlacesApiKey'
        '&fields=name,formatted_address,geometry',
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final result = data['result'];
          final geometry = result['geometry']['location'];
          final address = result['formatted_address'];
          
          setState(() {
            if (isPickup) {
              _pickupController.text = address;
              pickupLat = geometry['lat'];
              pickupLng = geometry['lng'];
              _showPickupSuggestions = false;
            } else {
              _dropController.text = address;
              dropLat = geometry['lat'];
              dropLng = geometry['lng'];
              _showDropSuggestions = false;
            }
          });
        }
      }
    } catch (e) {
      print('Error getting place details: $e');
    }
  }

  Future<void> _searchFutureRides() async {
    final validationError = Authservices.validateRideData(
      pickupLocation: _pickupController.text,
      dropoffLocation: _dropController.text,
      date: _dateController.text,
      time: _timeController.text,
      numberOfPersons: _personsController.text,
    );

    if (validationError != null) {
      _showSnackBar(validationError, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      // Convert to 24-hour format
      final time24Hour = Authservices.convertTo24HourFormat(_timeController.text);

      // Use stored coordinates or fallback to geocoding
      double fromLat = pickupLat ?? 0;
      double fromLng = pickupLng ?? 0;
      double toLat = dropLat ?? 0;
      double toLng = dropLng ?? 0;

      // Fallback to geocoding if coordinates not available
      if (fromLat == 0 || fromLng == 0) {
        final pickupLocations = await locationFromAddress(_pickupController.text.trim());
        if (pickupLocations.isNotEmpty) {
          fromLat = pickupLocations.first.latitude;
          fromLng = pickupLocations.first.longitude;
        }
      }

      if (toLat == 0 || toLng == 0) {
        final dropLocations = await locationFromAddress(_dropController.text.trim());
        if (dropLocations.isNotEmpty) {
          toLat = dropLocations.first.latitude;
          toLng = dropLocations.first.longitude;
        }
      }

      if (fromLat == 0 || fromLng == 0 || toLat == 0 || toLng == 0) {
        _showSnackBar("Invalid pickup or drop address.", isError: true);
        return;
      }

      // Try multiple search strategies
      Map<String, dynamic>? searchResult;
      
      // Strategy 1: Broad city-based search
      searchResult = await _trySearch(
        fromAddress: "Noida",
        toAddress: "Delhi",
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: toLat,
        toLng: toLng,
        date: _dateController.text.trim(),
        time: time24Hour,
        passengers: _personsController.text.trim(),
        token: token!,
      );

      // Strategy 2: If no results, try with exact addresses
      if (searchResult == null || (searchResult['rides']?.length ?? 0) == 0) {
        searchResult = await _trySearch(
          fromAddress: _pickupController.text.trim(),
          toAddress: _dropController.text.trim(),
          fromLat: fromLat,
          fromLng: fromLng,
          toLat: toLat,
          toLng: toLng,
          date: _dateController.text.trim(),
          time: time24Hour,
          passengers: _personsController.text.trim(),
          token: token,
        );
      }

      // Strategy 3: If still no results, try without coordinates
      if (searchResult == null || (searchResult['rides']?.length ?? 0) == 0) {
        searchResult = await _trySearch(
          fromAddress: "Noida",
          toAddress: "Delhi",
          date: _dateController.text.trim(),
          time: time24Hour,
          passengers: _personsController.text.trim(),
          token: token,
          skipCoordinates: true,
        );
      }

      if (searchResult != null) {
        final ridesCount = searchResult['rides']?.length ?? 0;
        
        if (ridesCount > 0) {
          _showSnackBar("Found $ridesCount rides!", isError: false);
          print("Number of rides found: $ridesCount");
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RideList(rides: searchResult!['rides']),
            ),
          );
        } else {
          _showSnackBar("No rides found for your route and time. Try adjusting your search criteria.", isError: true);
          _showSearchSuggestions();
        }
      } else {
        _showSnackBar("Search failed. Please try again.", isError: true);
      }
    } catch (e) {
      _showSnackBar("Error: ${e.toString()}", isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>?> _trySearch({
    required String fromAddress,
    required String toAddress,
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
    required String date,
    required String time,
    required String passengers,
    required String token,
    bool skipCoordinates = false,
  }) async {
    try {
      String urlString = "$baseUrl/api/future-rides/user/search"
          "?fromAddress=${Uri.encodeComponent(fromAddress)}"
          "&toAddress=${Uri.encodeComponent(toAddress)}"
          "&date=$date"
          "&time=$time"
          "&numOfPassengers=$passengers";

      if (!skipCoordinates && fromLat != null && fromLng != null && toLat != null && toLng != null) {
        urlString += "&fromLat=$fromLat&fromLng=$fromLng&toLat=$toLat&toLng=$toLng";
      }

      final url = Uri.parse(urlString);

      print("🔗 Trying search: $url");

      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      print("📬 Response Status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("📊 Response: $data");
        return data;
      }
      
      return null;
    } catch (e) {
      print("❌ Search attempt failed: $e");
      return null;
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  void _showSearchSuggestions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("No Rides Found"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Try these suggestions:"),
            SizedBox(height: 8),
            Text("• Adjust your departure time"),
            Text("• Try a different date"),
            Text("• Consider nearby pickup/drop locations"),
            Text("• Reduce number of passengers"),
            Text("• Check again later as new rides are added"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _timeController.clear();
    _dateController.clear();
    _pickupController.clear();
    _dropController.clear();
    _personsController.clear();
    pickupLat = pickupLng = dropLat = dropLng = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Hero image — top portion only
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.32,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/future.jpg',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.45),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main scrollable content
          SafeArea(
            child: Column(
              children: [
                // Floating Header over image
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const Text(
                        'Future Rides',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 8,
                              color: Colors.black38,
                            )
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => FutureRidesHistory()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.history_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 0.16),

                        // Search Form Card
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Pickup
                                _buildPickupRow(),
                                Divider(
                                    height: 1,
                                    color: Colors.grey.shade100,
                                    indent: 20,
                                    endIndent: 20),
                                if (_showPickupSuggestions)
                                  _buildSuggestionsList(true),

                                // Drop
                                _buildDropRow(),
                                Divider(
                                    height: 1,
                                    color: Colors.grey.shade100,
                                    indent: 20,
                                    endIndent: 20),
                                if (_showDropSuggestions)
                                  _buildSuggestionsList(false),

                                // Persons
                                buildInputRow(
                                  _personsController,
                                  Icons.person_rounded,
                                  const Color(0xFF0F9D58),
                                  "Number of persons",
                                  keyboardType: TextInputType.number,
                                ),
                                Divider(
                                    height: 1,
                                    color: Colors.grey.shade100,
                                    indent: 20,
                                    endIndent: 20),

                                // Date
                                buildDatePickerRow(context),
                                Divider(
                                    height: 1,
                                    color: Colors.grey.shade100,
                                    indent: 20,
                                    endIndent: 20),

                                // Time
                                buildTimePickerRow(context),

                                const SizedBox(height: 6),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Search button
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          child: SizedBox(
                            height: 56,
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F9D58),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    Colors.grey.shade200,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : _searchFutureRides,
                              child: _isLoading
                                  ? const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Searching...',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.search_rounded, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Search Rides',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Info chips row
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              _infoChip(Icons.verified_user_outlined,
                                  'Safe rides'),
                              const SizedBox(width: 8),
                              _infoChip(
                                  Icons.savings_rounded, 'Save money'),
                              const SizedBox(width: 8),
                              _infoChip(Icons.eco_rounded, 'Go green'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF0F9D58)),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickupRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F9D58).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on_rounded,
                color: Color(0xFF0F9D58), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _pickupController,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: "Pickup location",
                hintStyle:
                    TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: InputBorder.none,
                suffixIcon: _isLoadingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF0F9D58))),
                        ),
                      )
                    : null,
              ),
              onChanged: (value) => _searchPlaces(value, true),
              onTap: () {
                if (_pickupSuggestions.isNotEmpty) {
                  setState(() => _showPickupSuggestions = true);
                }
              },
            ),
          ),
          GestureDetector(
            onTap: _getCurrentLocation,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.my_location_rounded,
                  color: Colors.blue, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_on_rounded,
                color: Colors.red.shade400, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _dropController,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: "Drop location",
                hintStyle:
                    TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: InputBorder.none,
              ),
              onChanged: (value) => _searchPlaces(value, false),
              onTap: () {
                if (_dropSuggestions.isNotEmpty) {
                  setState(() => _showDropSuggestions = true);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(bool isPickup) {
    final suggestions = isPickup ? _pickupSuggestions : _dropSuggestions;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: suggestions.length > 5 ? 5 : suggestions.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return InkWell(
            onTap: () => _getPlaceDetails(suggestion['place_id'], isPickup),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.place_rounded,
                      size: 15, color: Colors.grey.shade400),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      suggestion['description'],
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildInputRow(
    TextEditingController? controller,
    IconData icon,
    Color iconColor,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle:
                    TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDatePickerRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_month_rounded,
                color: Colors.orange, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _dateController,
              readOnly: true,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: "Select date",
                hintStyle:
                    TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: InputBorder.none,
              ),
              onTap: () async {
                FocusScope.of(context).unfocus();
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF0F9D58),
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  final formattedDate =
                      "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                  _dateController.text = formattedDate;
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTimePickerRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.access_time_rounded,
                color: Colors.purple, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _timeController,
              readOnly: true,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: "Select time",
                hintStyle:
                    TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: InputBorder.none,
              ),
              onTap: () async {
                FocusScope.of(context).unfocus();
                TimeOfDay? time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF0F9D58),
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (time != null) {
                  _timeController.text = time.format(context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}