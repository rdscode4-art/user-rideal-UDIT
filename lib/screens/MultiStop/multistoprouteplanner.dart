import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:rideal/authservices.dart';
import 'package:rideal/screens/MultiStop/multistopbook.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui';

// ---------------- GOOGLE PLACES SERVICE ----------------
class PlacesService {
  final String apiKey;

  PlacesService(this.apiKey);

  Future<List<Map<String, String>>> getSuggestions(String input) async {
    if (input.isEmpty) return [];

    // FIXED: Proper URL construction with ? for first parameter
    final String url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json"
        "?input=${Uri.encodeComponent(input)}" // Use ? for first parameter
        "&key=$apiKey" // Use & for subsequent parameters
        "&components=country:in" // Restrict to India
        "&types=establishment|geocode"
        "&language=en";

    print("🔗 Places API URL: $url"); // Debug log

    try {
      final response = await http.get(Uri.parse(url));
      
      print("📬 Response Status: ${response.statusCode}"); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("📊 Response Data: $data"); // Debug log

        if (data["status"] == "OK") {
          final List predictions = data["predictions"] as List;

          return predictions
              .map((p) => {
                    "description": p["description"] as String,
                    "place_id": p["place_id"] as String,
                  })
              .toList();
        } else {
          print("❌ Google API error: ${data["status"]} - ${data["error_message"] ?? 'Unknown error'}");
          return [];
        }
      } else {
        print("❌ HTTP Error: ${response.statusCode} - ${response.body}");
        throw Exception("Failed to fetch suggestions: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Exception in getSuggestions: $e");
      throw Exception("Failed to fetch suggestions: $e");
    }
  }

  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    // FIXED: Proper URL construction
    final String url =
        "https://maps.googleapis.com/maps/api/place/details/json"
        "?place_id=$placeId" // Use ? for first parameter
        "&key=$apiKey" // Use & for subsequent parameters
        "&fields=name,formatted_address,geometry"; // Specify required fields
    
    print("🔗 Place Details URL: $url"); // Debug log

    try {
      final response = await http.get(Uri.parse(url));
      
      print("📬 Details Response Status: ${response.statusCode}"); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("📊 Details Response: $data"); // Debug log

        if (data["status"] == "OK") {
          final loc = data["result"]["geometry"]["location"];
          return {
            "lat": loc["lat"],
            "lng": loc["lng"],
            "address": data["result"]["formatted_address"],
          };
        } else {
          print("❌ Google API error (details): ${data["status"]} - ${data["error_message"] ?? 'Unknown error'}");
          return null;
        }
      } else {
        print("❌ HTTP Error (details): ${response.statusCode} - ${response.body}");
        throw Exception("Failed to fetch place details: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Exception in getPlaceDetails: $e");
      throw Exception("Failed to fetch place details: $e");
    }
  }
}

// ---------------- MULTI STOP PLANNER ----------------
class MultiStopRoutePlanner extends StatefulWidget {
  const MultiStopRoutePlanner({super.key});

  @override
  _MultiStopRoutePlannerState createState() => _MultiStopRoutePlannerState();
}

class _MultiStopRoutePlannerState extends State<MultiStopRoutePlanner> {
  final PlacesService placesService =
      PlacesService("AIzaSyBQx7m5RcWfgRtYZzvwxRLcMa3Ks-Z0xUI"); // Replace with valid key

  List<TextEditingController> controllers = [];
  List<Map<String, dynamic>> stops = [];
  List<List<Map<String, String>>> predictions = [];
  bool _isLoading = false;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    // Initialize with empty pickup location
    controllers = [TextEditingController(text: "Getting current location...")];
    stops = [{"name": "", "lat": null, "lng": null, "address": null}];
    predictions = [[]];
    
    // Automatically get current location when screen loads
    _setCurrentLocationAsPickup();
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _setCurrentLocationAsPickup() async {
    setState(() {
      _isLoadingLocation = true;
      controllers[0].text = "Getting current location...";
    });

    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          controllers[0].text = "Location service disabled";
          _isLoadingLocation = false;
        });
        _showLocationServiceDialog();
        return;
      }

      // Check & request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            controllers[0].text = "Location permission denied";
            _isLoadingLocation = false;
          });
          _showPermissionDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          controllers[0].text = "Location permission permanently denied";
          _isLoadingLocation = false;
        });
        _showPermissionDialog();
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocode to get detailed address
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        // Combine all non-empty parts into a full address
        String address = [
          p.name,
          p.street,
          p.subLocality,
          p.locality,
          p.subAdministrativeArea,
          p.administrativeArea,
          p.postalCode,
          p.country,
        ].where((part) => part != null && part.trim().isNotEmpty).join(", ");

        if (address.isEmpty) {
          address =
              "${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
        }

        setState(() {
          controllers[0].text = address;
          stops[0] = {
            "name": address,
            "lat": position.latitude,
            "lng": position.longitude,
            "address": address,
          };
          _isLoadingLocation = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Current location set as pickup"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("Error getting current location: $e");
      setState(() {
        controllers[0].text = "Tap to set pickup location";
        _isLoadingLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to get location: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Location Service Disabled"),
          content: Text("Please enable location services to automatically set your pickup location."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  controllers[0].text = "Enter pickup location manually";
                });
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
                // Retry after user returns from settings
                _setCurrentLocationAsPickup();
              },
              child: Text("Open Settings"),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Location Permission Required"),
          content: Text("Location permission is needed to automatically set your pickup location. You can grant permission or enter the location manually."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  controllers[0].text = "Enter pickup location manually";
                });
              },
              child: Text("Enter Manually"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openAppSettings();
              },
              child: Text("Open Settings"),
            ),
          ],
        );
      },
    );
  }

  void addStop() {
    // Backend requires: pickup + exactly 3 additional stops = 4 total max
    if (controllers.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Maximum 3 additional stops allowed"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      controllers.add(TextEditingController());
      stops.add({"name": "", "lat": null, "lng": null, "address": null});
      predictions.add([]);
    });
  }

  void removeStop(int index) {
    if (index == 0) return; // Can't remove pickup location
    
    setState(() {
      controllers[index].dispose();
      controllers.removeAt(index);
      stops.removeAt(index);
      predictions.removeAt(index);
    });
  }

  Future<void> _onSearchChanged(String value, int index) async {
    if (value.isEmpty) {
      setState(() {
        predictions[index] = [];
      });
      return;
    }

    try {
      final result = await placesService.getSuggestions(value);
      if (mounted) {
        setState(() {
          predictions[index] = result;
        });
      }
    } catch (e) {
      print("Error fetching suggestions: $e");
      // Show user-friendly error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to search places: ${e.toString()}"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _selectPlace(Map<String, String> place, int index) async {
    try {
      final details = await placesService.getPlaceDetails(place["place_id"]!);
      if (details != null && mounted) {
        setState(() {
          controllers[index].text = place["description"]!;
          stops[index] = {
            "name": place["description"],
            "lat": details["lat"],
            "lng": details["lng"],
            "address": details["address"] ?? place["description"],
          };
          predictions[index] = [];
        });
      }
    } catch (e) {
      print("Error getting place details: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to get location details"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _validateStops() {
    // Filter out stops with valid coordinates
    final validStops = stops.where((s) => 
      s["lat"] != null && 
      s["lng"] != null && 
      s["address"] != null
    ).toList();

    // Need at least pickup + 1 destination (2 total minimum)
    if (validStops.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please add at least one destination"),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    // Check if pickup location is set
    if (stops[0]["lat"] == null || stops[0]["lng"] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please set your pickup location"),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    return true;
  }

  List<Map<String, dynamic>> _prepareStopsForAPI() {
    // Filter valid stops and ensure proper formatting
    final validStops = stops.where((s) => 
      s["lat"] != null && 
      s["lng"] != null && 
      s["address"] != null
    ).map((s) => {
      "name": s["address"] ?? s["name"],
      "lat": (s["lat"] as num).toDouble(),
      "lng": (s["lng"] as num).toDouble(),
    }).toList();

    return validStops;
  }

  Future<void> startRoute() async {
    if (_isLoading) return;
    
    if (!_validateStops()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final preparedStops = _prepareStopsForAPI();
      
      print("Sending ${preparedStops.length} stops to API:");
      for (int i = 0; i < preparedStops.length; i++) {
        print("  Stop $i: ${preparedStops[i]}");
      }

      final result = await Authservices.createMultiStopRide(preparedStops);

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Multi-stop route created successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MultipleBook(
              stops: preparedStops,
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to create route. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error creating route: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildStopInput(int index) {
    final isPickup = index == 0;
    final hasValidLocation = stops[index]["lat"] != null && stops[index]["lng"] != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
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
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: hasValidLocation ? const Color(0xFF0F9D58).withOpacity(0.3) : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controllers[index],
                          onChanged: (value) => _onSearchChanged(value, index),
                          enabled: !(_isLoadingLocation && isPickup),
                          textAlignVertical: TextAlignVertical.center,
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: isPickup ? "Pickup location" : "Destination ${index}",
                            hintStyle: TextStyle(color: Colors.black38, fontSize: 14.sp),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14.w),
                            isDense: true,
                            prefixIcon: _isLoadingLocation && isPickup
                                ? Padding(
                                    padding: EdgeInsets.all(14.w),
                                    child: SizedBox(
                                      width: 16.w,
                                      height: 16.w,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F9D58)),
                                    ),
                                  )
                                : Icon(
                                    isPickup ? Icons.circle : Icons.location_on,
                                    size: isPickup ? 12 : 16,
                                    color: isPickup ? const Color(0xFF0F9D58) : Colors.redAccent,
                                  ),
                          ),
                        ),
                      ),
                      if (hasValidLocation)
                        Padding(
                          padding: EdgeInsets.only(right: 12.w),
                          child: Icon(Icons.check_circle, color: Color(0xFF0F9D58), size: 16),
                        ),
                      if (isPickup && !_isLoadingLocation)
                        IconButton(
                          icon: Icon(Icons.my_location, color: Colors.blueAccent, size: 18),
                          onPressed: _setCurrentLocationAsPickup,
                          tooltip: "Use current location",
                        ),
                      if (!isPickup)
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.black45, size: 18),
                          onPressed: () => removeStop(index),
                          tooltip: "Remove stop",
                        ),
                    ],
                  ),
                ),
              ),
              
              // Suggestions dropdown
              if (predictions[index].isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade100)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: predictions[index].length > 5 ? 5 : predictions[index].length,
                    separatorBuilder: (context, idx) => Divider(height: 1.w, color: Colors.grey.shade100),
                    itemBuilder: (context, idx) {
                      final prediction = predictions[index][idx];
                      return ListTile(
                        visualDensity: VisualDensity.compact,
                        leading: Icon(Icons.location_on_outlined, color: Colors.black54, size: 18),
                        title: Text(
                          prediction["description"] ?? "",
                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
                        ),
                        onTap: () => _selectPlace(prediction, index),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Custom Header
                Padding(
                  padding: EdgeInsets.only(top: 8.w, left: 16.w, right: 16.w, bottom: 20.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: EdgeInsets.all(8.w),
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
                              child: Icon(Icons.arrow_back, color: Colors.black87, size: 18),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            "Multi-Stop Route",
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          "${controllers.length}/4 Stops",
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.only(bottom: 120.w),
                    itemCount: controllers.length,
                    itemBuilder: (context, index) => _buildStopInput(index),
                  ),
                ),
              ],
            ),
            
            // Floating Frosted Bottom Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: EdgeInsets.only(
                      top: 16.w,
                      left: 20.w,
                      right: 20.w,
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (controllers.length < 4)
                          GestureDetector(
                            onTap: addStop,
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 12.w),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle, color: Color(0xFF0F9D58), size: 20),
                                  SizedBox(width: 8.w),
                                  Text(
                                    "Add another stop (${controllers.length - 1}/3)",
                                    style: TextStyle(
                                      color: Color(0xFF0F9D58),
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        GestureDetector(
                          onTap: _isLoading ? null : startRoute,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 14.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F9D58),
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F9D58).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _isLoading
                                ? Center(
                                    child: SizedBox(
                                      width: 20.w,
                                      height: 20.w,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.route, color: Colors.white, size: 18),
                                      SizedBox(width: 8.w),
                                      Text(
                                        "Review Route",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w700,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}