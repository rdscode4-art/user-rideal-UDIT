import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:rideal/authservices.dart';
import 'package:rideal/screens/home/book.dart';
import 'package:rideal/screens/RideHistory/ridehistory.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SearchScreen extends StatefulWidget {
  final String? initialPickup;
  final String? initialDropoff;

  const SearchScreen({
    super.key,
    this.initialPickup,
    this.initialDropoff,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();
  final placesService = PlacesService("AIzaSyBQx7m5RcWfgRtYZzvwxRLcMa3Ks-Z0xUI");
  List<Map<String, dynamic>> _pickupSuggestions = [];
  List<Map<String, dynamic>> _dropSuggestions = [];
  List<Ride> rideHistory = [];
  bool isHistoryLoading = true;

  @override
  void initState() {
    super.initState();
    _dropController.addListener(_filterRecentPlaces);
    
    // Check if we have initial values from recent searches
    if (widget.initialPickup != null && widget.initialPickup!.isNotEmpty) {
      _pickupController.text = widget.initialPickup!;
    } else {
      _setCurrentLocationAsPickup();
    }
    
    if (widget.initialDropoff != null && widget.initialDropoff!.isNotEmpty) {
      _dropController.text = widget.initialDropoff!;
    }
    
    loadRideHistory();
  }

  Future<void> _setCurrentLocationAsPickup() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        String fullAddress = [
          if (p.name != null && p.name!.isNotEmpty && p.name != 'Unnamed Road')
            p.name,
          if (p.street != null && p.street!.isNotEmpty) p.street,
          if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality,
          if (p.subAdministrativeArea != null &&
              p.subAdministrativeArea!.isNotEmpty)
            p.subAdministrativeArea,
          if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
            p.administrativeArea,
          if (p.postalCode != null && p.postalCode!.isNotEmpty) p.postalCode,
          if (p.country != null && p.country!.isNotEmpty) p.country,
        ].join(', ');

        setState(() {
          _pickupController.text = fullAddress;
        });
        print("📍 Full detected address: $fullAddress");
      }
    } catch (e) {
      print("❌ Error getting current location: $e");
    }
  }

  void _onPickupChanged(String value) async {
    if (value.isNotEmpty) {
      final results = await placesService.getSuggestions(value);
      setState(() => _pickupSuggestions = results);
    } else {
      setState(() => _pickupSuggestions = []);
    }
  }

  void _onDropChanged(String value) async {
    if (value.isNotEmpty) {
      final results = await placesService.getSuggestions(value);
      setState(() => _dropSuggestions = results);
    } else {
      setState(() => _dropSuggestions = []);
    }
  }

  void _filterRecentPlaces() {
    final query = _dropController.text.toLowerCase();
    setState(() {
      _dropSuggestions = _dropSuggestions.where((place) {
        final desc = place['description']?.toLowerCase() ?? '';
        return desc.contains(query);
      }).toList();
    });
  }

  Future<String> getAddressFromLatLng(double lat, double lng) async {
    if (lat == 0 && lng == 0) {
      return "Location Not Available";
    }

    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        List<String> addressParts = [];

        if (place.name?.isNotEmpty == true && place.name != "Unnamed Road") {
          addressParts.add(place.name!);
        }
        if (place.street?.isNotEmpty == true) {
          addressParts.add(place.street!);
        }
        if (place.locality?.isNotEmpty == true) {
          addressParts.add(place.locality!);
        }
        if (place.subAdministrativeArea?.isNotEmpty == true) {
          addressParts.add(place.subAdministrativeArea!);
        }

        return addressParts.isNotEmpty
            ? addressParts.join(', ')
            : "${place.locality ?? 'Unknown'}, ${place.administrativeArea ?? 'Unknown'}";
      } else {
        return "Location ($lat, $lng)";
      }
    } catch (e) {
      print("❌ Reverse geocoding error: $e");
      return "Location ($lat, $lng)";
    }
  }

  Future<void> loadRideHistory() async {
    try {
      final rides = await Authservices.fetchRideHistory();
      List<Ride> updatedRides = [];
      for (var ride in rides) {
        print('🔍 Processing Ride ID: ${ride.id}');
        final pickupAddress = await getAddressFromLatLng(
          ride.pickupStop.lat,
          ride.pickupStop.lng,
        );
        print('📍 Pickup Address: $pickupAddress');
        final dropoffAddress = await getAddressFromLatLng(
          ride.dropoffStop.lat,
          ride.dropoffStop.lng,
        );
        print('📍 Dropoff Address: $dropoffAddress');

        updatedRides.add(
          Ride(
            id: ride.id,
            status: ride.status,
            createdAt: ride.createdAt,
            type: ride.type,
            feedback: ride.feedback,
            rebookedFrom: ride.rebookedFrom,
            stops: [
              ride.pickupStop.copyWith(address: pickupAddress),
              ride.dropoffStop.copyWith(address: dropoffAddress),
            ],
          ),
        );
      }

      setState(() {
        rideHistory = updatedRides;
        isHistoryLoading = false;
      });
    } catch (e) {
      print('❌ Error loading ride history: $e');
      setState(() {
        isHistoryLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to load ride history")),
      );
    }
  }

  // Save recent search to SharedPreferences
  Future<void> _saveRecentSearch(String pickup, String dropoff) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searchesJson = prefs.getStringList('recent_searches') ?? [];

      final newSearch = jsonEncode({
        'pickup': pickup,
        'dropoff': dropoff,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Remove if already exists
      searchesJson.removeWhere((search) {
        final decoded = jsonDecode(search);
        return decoded['pickup'] == pickup && decoded['dropoff'] == dropoff;
      });

      // Add to beginning
      searchesJson.insert(0, newSearch);

      // Keep only last 10
      if (searchesJson.length > 10) {
        searchesJson.removeRange(10, searchesJson.length);
      }

      await prefs.setStringList('recent_searches', searchesJson);
      print('✅ Recent search saved');
    } catch (e) {
      print('❌ Error saving recent search: $e');
    }
  }

  void _navigateToBook({String? selectedPlaceTitle}) async {
    String pickupLocation = _pickupController.text.trim();
    String dropoffLocation = '';

    if (_dropController.text.trim().isNotEmpty) {
      dropoffLocation = _dropController.text.trim();
    } else if (selectedPlaceTitle != null) {
      dropoffLocation = selectedPlaceTitle;
    }

    if (pickupLocation.isEmpty || dropoffLocation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter both pickup and drop locations')),
      );
      return;
    }

    // Save to recent searches
    await _saveRecentSearch(pickupLocation, dropoffLocation);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Book(
          pickupLocation: pickupLocation,
          dropoffLocation: dropoffLocation,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.removeListener(_filterRecentPlaces);
    _dropController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Slightly off-white modern background
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Modern Header
              Padding(
                padding: EdgeInsets.only(top: 8.w, left: 16.w, right: 16.w, bottom: 16.w),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(8.w), // Scaled down
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.arrow_back, color: Colors.black87, size: 18), // Smaller icon
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      "Route Planner",
                      style: TextStyle(
                        fontSize: 18.sp, // Scaled down
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // Floating Inputs Card
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w), // Tighter margin
                padding: EdgeInsets.all(16.w), // Scaled down
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r), // Scaled down
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Pickup Input
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: _pickupController,
                        onChanged: _onPickupChanged,
                        textAlignVertical: TextAlignVertical.center,
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.circle, color: Color(0xFF0F9D58), size: 12),
                          hintText: 'Pickup Location',
                          hintStyle: TextStyle(color: Colors.black38, fontSize: 14.sp),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14.w),
                          isDense: true,
                          suffixIcon: _pickupController.text.isNotEmpty ? IconButton(
                            icon: Icon(Icons.close, size: 16, color: Colors.black45),
                            onPressed: () {
                              _pickupController.clear();
                              setState(() => _pickupSuggestions = []);
                            },
                          ) : null,
                        ),
                      ),
                    ),
                    if (_pickupSuggestions.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(top: 8.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _pickupSuggestions.length,
                          separatorBuilder: (context, index) => Divider(height: 1.w, color: Colors.grey.shade100),
                          itemBuilder: (context, index) {
                            final suggestion = _pickupSuggestions[index];
                            return ListTile(
                              visualDensity: VisualDensity.compact,
                              leading: Icon(Icons.location_on_outlined, color: Colors.black54, size: 18),
                              title: Text(
                                suggestion["description"]!,
                                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
                              ),
                              onTap: () {
                                _pickupController.text = suggestion["description"]!;
                                setState(() => _pickupSuggestions = []);
                              },
                            );
                          },
                        ),
                      ),
                    
                    SizedBox(height: 12.w),

                    // Drop Input
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: _dropController,
                        onChanged: _onDropChanged,
                        textAlignVertical: TextAlignVertical.center,
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.location_on, color: Colors.redAccent, size: 16),
                          hintText: 'Where to?',
                          hintStyle: TextStyle(color: Colors.black38, fontSize: 14.sp),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14.w),
                          isDense: true,
                          suffixIcon: _dropController.text.isNotEmpty ? IconButton(
                            icon: Icon(Icons.close, size: 16, color: Colors.black45),
                            onPressed: () {
                              _dropController.clear();
                              setState(() => _dropSuggestions = []);
                            },
                          ) : null,
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) _navigateToBook();
                        },
                      ),
                    ),
                    if (_dropSuggestions.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(top: 8.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _dropSuggestions.length,
                          separatorBuilder: (context, index) => Divider(height: 1.w, color: Colors.grey.shade100),
                          itemBuilder: (context, index) {
                            final suggestion = _dropSuggestions[index];
                            return ListTile(
                              visualDensity: VisualDensity.compact,
                              leading: Icon(Icons.location_on_outlined, color: Colors.black54, size: 18),
                              title: Text(
                                suggestion["description"]!,
                                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
                              ),
                              onTap: () {
                                _dropController.text = suggestion["description"]!;
                                setState(() => _dropSuggestions = []);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 20.w),

              // Search Action Button
              if (_dropController.text.trim().isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: GestureDetector(
                    onTap: () => _navigateToBook(),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 14.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F9D58),
                        borderRadius: BorderRadius.circular(16.r), // Smaller radius
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F9D58).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, color: Colors.white, size: 18),
                          SizedBox(width: 6.w),
                          Text(
                            "Find Rides",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              SizedBox(height: 24.w),

              // Recent Rides Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text(
                  "Recent Destinations",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.sp,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(height: 12.w),
              
              isHistoryLoading
                  ? Center(child: Padding(padding: EdgeInsets.all(20.w), child: CircularProgressIndicator()))
                  : rideHistory.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0.w),
                            child: Column(
                              children: [
                                Icon(Icons.history_toggle_off, color: Colors.grey.shade300, size: 40),
                                SizedBox(height: 8.w),
                                Text("No recent rides", style: TextStyle(color: Colors.grey.shade400, fontSize: 13.sp, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: rideHistory.length,
                          itemBuilder: (context, index) {
                            final ride = rideHistory[index];
                            return Container(
                              margin: EdgeInsets.only(bottom: 8.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: Colors.grey.shade100),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.01),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                visualDensity: VisualDensity.compact,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.w),
                                leading: Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.history, color: Colors.black54, size: 16),
                                ),
                                title: Text(
                                  ride.dropoffStop.address,
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp, color: Colors.black87),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Icon(Icons.arrow_forward_ios, size: 10, color: Colors.black26),
                                onTap: () => _navigateToBook(
                                  selectedPlaceTitle: ride.dropoffStop.address,
                                ),
                              ),
                            );
                          },
                        ),
              SizedBox(height: 40.w),
            ],
          ),
        ),
      ),
    );
  }
}