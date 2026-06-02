import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rideal/authservices.dart';
import 'package:rideal/screens/transport/confirmpickup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:math';

class RideType {
  final String type;
  final int farePerKm;
  final int avgSpeed;
  final String? imageUrl;
  final int? minFare;
   final String originalKey;  // ADD THIS LINE
  final int? freeWaitMin;
  final int? waitChargePerMin;
  final int? nightChargePercent;

  RideType({
    required this.type,
    required this.farePerKm,
    required this.avgSpeed,
    this.imageUrl,
    this.minFare,
    required this.originalKey,
    this.freeWaitMin,
    this.waitChargePerMin,
    this.nightChargePercent,
  });

  // Helper method to safely parse values to int
  static int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory RideType.fromJson(String key, dynamic value, Map<String, dynamic>? vehicleImages) {
    // Convert key to display name
    String displayType = key
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');

    // Get average speed based on vehicle type
    int speed;
    String lowerKey = key.toLowerCase();
    if (lowerKey.contains('bike')) {
      speed = 25;
    } else if (lowerKey.contains('sedan')) {
      speed = 35;
    } else if (lowerKey.contains('suv')) {
      speed = 30;
    } else if (lowerKey.contains('ev')) {
      speed = 28;
    } else if (lowerKey.contains('auto')) {
      speed = 20;
    } else {
      speed = 30; // fallback
    }

    // Parse fare structure - handle both nested and simple formats
    int perKmRate;
    int? minFare;
    int? freeWaitMin;
    int? waitChargePerMin;
    int? nightChargePercent;

    if (value is Map<String, dynamic>) {
      // Nested structure (like bike)
      perKmRate = _parseToInt(value['perKmRate']) ?? 0;
      minFare = _parseToInt(value['minFare']);
      freeWaitMin = _parseToInt(value['freeWaitMin']);
      waitChargePerMin = _parseToInt(value['waitChargePerMin']);
      nightChargePercent = _parseToInt(value['nightChargePercent']);
    } else if (value is Map) {
      // Handle dynamic Map
      perKmRate = _parseToInt(value['perKmRate']) ?? 0;
      minFare = _parseToInt(value['minFare']);
      freeWaitMin = _parseToInt(value['freeWaitMin']);
      waitChargePerMin = _parseToInt(value['waitChargePerMin']);
      nightChargePercent = _parseToInt(value['nightChargePercent']);
    } else {
      // Simple structure (just perKmRate as int)
      perKmRate = _parseToInt(value) ?? 0;
    }

    // Get image URL
    String? imageUrl;
    if (vehicleImages != null) {
      imageUrl = vehicleImages[displayType] ?? vehicleImages[key];
      if (imageUrl == null) {
        vehicleImages.forEach((k, v) {
          if (k.toLowerCase() == displayType.toLowerCase()) {
            imageUrl = v;
          }
        });
      }
    }

    return RideType(
      type: displayType,
      farePerKm: perKmRate,
      avgSpeed: speed,
      imageUrl: imageUrl,
      minFare: minFare,
      originalKey: key,  // ADD THIS LINE - store the original key
      freeWaitMin: freeWaitMin,
      waitChargePerMin: waitChargePerMin,
      nightChargePercent: nightChargePercent,
    );
  }
}
class MultipleBook extends StatefulWidget {
  const MultipleBook({super.key, required this.stops});
  final List<Map<String, dynamic>> stops;
  
  @override
  State<MultipleBook> createState() => _MultipleBookState();
}

class _MultipleBookState extends State<MultipleBook> {
  Set<Marker> markers = {};
  final Set<Polyline> _polylines = {};
  List<LatLng> polylineCoordinates = [];
  final polylinePoints = PolylinePoints(
    apiKey: "AIzaSyBQx7m5RcWfgRtYZzvwxRLcMa3Ks-Z0xUI",
  );
  
  List<RideType> rideTypes = [];
  int selectedIndex = -1;
  bool isLoading = true;
  bool isBooking = false;
  double distanceInKm = 0.0;
  GoogleMapController? _controller;

  // Add method to get image for ride type
  String getImageForRideType(String type, RideType? rideTypeObj) {
    const String baseUrl = 'https://backend.ridealmobility.com';
    
    // First check if backend image URL is available
    if (rideTypeObj?.imageUrl != null && rideTypeObj!.imageUrl!.isNotEmpty) {
      // Check if the URL is already complete
      if (rideTypeObj.imageUrl!.startsWith('http://') || 
          rideTypeObj.imageUrl!.startsWith('https://')) {
        return rideTypeObj.imageUrl!;
      }
      
      // Extract the path from full server path
      String path = rideTypeObj.imageUrl!;
      
      // If path contains full server path, extract only from 'uploads' onwards
      if (path.contains('/uploads/')) {
        int uploadsIndex = path.indexOf('/uploads/');
        path = path.substring(uploadsIndex);
      } else if (!path.startsWith('/')) {
        // If it doesn't start with /, add it
        path = '/$path';
      }
      
      return '$baseUrl$path';
    }
    
    // Fallback to local assets based on type name
    final lowerType = type.toLowerCase();
    
    if (lowerType.contains('sedan') || lowerType.contains('car')) {
      return 'assets/images/taxi.png';
    } else if (lowerType.contains('suv')) {
      return 'assets/images/suv.png';
    } else if (lowerType.contains('ev') || lowerType.contains('electric')) {
      return 'assets/images/ev.png';
    } else if (lowerType.contains('bike') || lowerType.contains('motorcycle')) {
      return 'assets/images/bike.png';
    } else if (lowerType.contains('auto') || lowerType.contains('rickshaw')) {
      return 'assets/images/auto.png';
    } else {
      return 'assets/images/bike.png'; // default fallback
    }
  }
double calculateFare(RideType ride, double distanceInKm) {
  if (distanceInKm == 0) return 0;
  
  // Calculate base fare
  double baseFare = ride.farePerKm * distanceInKm;
  
  // Apply minimum fare if available
  if (ride.minFare != null && baseFare < ride.minFare!) {
    baseFare = ride.minFare!.toDouble();
  }
  
  // Optional: Add night charges if it's night time (between 10 PM and 6 AM)
  if (ride.nightChargePercent != null) {
    DateTime now = DateTime.now();
    if (now.hour >= 22 || now.hour < 6) {
      baseFare += baseFare * (ride.nightChargePercent! / 100);
    }
  }
  
  return baseFare;
}

  String calculateDropTime(RideType ride) {
    if (distanceInKm == 0) return "—";

    double hours = distanceInKm / ride.avgSpeed;
    int travelMinutes = (hours * 60).round();

    DateTime now = DateTime.now();
    DateTime dropTime = now.add(Duration(minutes: travelMinutes));

    String period = dropTime.hour >= 12 ? "PM" : "AM";
    int displayHour = dropTime.hour > 12 ? dropTime.hour - 12 : 
                     (dropTime.hour == 0 ? 12 : dropTime.hour);

    return "$displayHour:${dropTime.minute.toString().padLeft(2, '0')} $period";
  }

  double _calculatePolylineDistance(List<LatLng> coords) {
    double distance = 0.0;
    for (int i = 0; i < coords.length - 1; i++) {
      distance += _coordinateDistance(
        coords[i].latitude,
        coords[i].longitude,
        coords[i + 1].latitude,
        coords[i + 1].longitude,
      );
    }
    return distance;
  }

  double _coordinateDistance(lat1, lon1, lat2, lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  void setMarkers() {
    markers.clear();
    for (int i = 0; i < widget.stops.length; i++) {
      final stop = widget.stops[i];
      final lat = stop["lat"];
      final lng = stop["lng"];
      
      if (lat != null && lng != null) {
        markers.add(
          Marker(
            markerId: MarkerId("stop_$i"),
            position: LatLng(lat.toDouble(), lng.toDouble()),
            infoWindow: InfoWindow(
              title: i == 0
                  ? "Pickup"
                  : (i == widget.stops.length - 1 ? "Drop" : "Stop $i"),
              snippet: stop["name"] ?? "Stop location",
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              i == 0
                  ? BitmapDescriptor.hueGreen
                  : (i == widget.stops.length - 1
                      ? BitmapDescriptor.hueRed
                      : BitmapDescriptor.hueBlue),
            ),
          ),
        );
      }
    }
    setState(() {});
  }

  Future<void> _getRoutesForStops() async {
    if (widget.stops.length < 2) return;

    try {
      polylineCoordinates.clear();
      _polylines.clear();
      double totalDistance = 0.0;

      for (int i = 0; i < widget.stops.length - 1; i++) {
        final start = widget.stops[i];
        final end = widget.stops[i + 1];

        final startLat = start["lat"];
        final startLng = start["lng"];
        final endLat = end["lat"];
        final endLng = end["lng"];

        if (startLat == null || startLng == null || endLat == null || endLng == null) {
          print("❌ Missing coordinates for route segment $i");
          continue;
        }

        PolylineRequest request = PolylineRequest(
          origin: PointLatLng(startLat.toDouble(), startLng.toDouble()),
          destination: PointLatLng(endLat.toDouble(), endLng.toDouble()),
          mode: TravelMode.driving,
        );

        PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
          request: request,
        );

        if (result.points.isNotEmpty) {
          final coords = result.points
              .map((p) => LatLng(p.latitude, p.longitude))
              .toList();
          polylineCoordinates.addAll(coords);

          _polylines.add(
            Polyline(
              polylineId: PolylineId("segment_$i"),
              points: coords,
              color: Colors.blue,
              width: 4,
              patterns: i == 0 ? [] : [PatternItem.dash(10), PatternItem.gap(5)],
            ),
          );

          totalDistance += _calculatePolylineDistance(coords);
        }
      }

      if (mounted) {
        setState(() {
          distanceInKm = totalDistance;
        });
        _fitMapToBounds();
      }
    } catch (e) {
      print("❌ Error getting multi-stop route: $e");
    }
  }

  void _fitMapToBounds() {
    if (_controller == null || widget.stops.isEmpty) return;

    final firstStop = widget.stops.first;
    final firstLat = firstStop["lat"];
    final firstLng = firstStop["lng"];
    
    if (firstLat == null || firstLng == null) return;

    double minLat = firstLat.toDouble();
    double maxLat = firstLat.toDouble();
    double minLng = firstLng.toDouble();
    double maxLng = firstLng.toDouble();

    for (var stop in widget.stops) {
      final lat = stop["lat"];
      final lng = stop["lng"];
      
      if (lat != null && lng != null) {
        final latDouble = lat.toDouble();
        final lngDouble = lng.toDouble();
        
        minLat = latDouble < minLat ? latDouble : minLat;
        maxLat = latDouble > maxLat ? latDouble : maxLat;
        minLng = lngDouble < minLng ? lngDouble : minLng;
        maxLng = lngDouble > maxLng ? lngDouble : maxLng;
      }
    }

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _controller!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

 Future<void> loadRideTypes() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      setState(() => isLoading = false);
      return;
    }
for (var ride in rideTypes) {
  print("✅ Ride: ${ride.type}, Fare: ₹${ride.farePerKm}/km, MinFare: ${ride.minFare ?? 'N/A'}, ImageUrl: ${ride.imageUrl}");
}
    final response = await http.get(
      Uri.parse("https://backend.ridealmobility.com/api/fare"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Extract fareRates and vehicleImages from the response
      final Map<String, dynamic> fareRates = data["fareRates"];
      final Map<String, dynamic>? vehicleImages = data["vehicleImages"];
      
      // Debug print to see what we got
      print("🔍 Fare Rates: $fareRates");
      print("🔍 Vehicle Images: $vehicleImages");
      
      if (mounted) {
        setState(() {
          // Convert fareRates map to list of RideType objects
          rideTypes = fareRates.entries
              .map((entry) => RideType.fromJson(
                    entry.key,           // e.g., "bike", "suv_ac"
                    entry.value,         // e.g., 9, 35
                    vehicleImages,       // the entire vehicleImages map
                  ))
              .toList();
          
          // Debug print to see parsed ride types
          for (var ride in rideTypes) {
            print("✅ Ride: ${ride.type}, Fare: ₹${ride.farePerKm}, ImageUrl: ${ride.imageUrl}");
          }
          
          isLoading = false;
        });
      }
    } else {
      print("❌ API Error: ${response.statusCode} - ${response.body}");
      if (mounted) setState(() => isLoading = false);
    }
  } catch (e) {
    print("❌ Error loading ride types: $e");
    if (mounted) setState(() => isLoading = false);
  }
}
  Map<String, dynamic> _formatStopForBooking(Map<String, dynamic> stop, int index) {
    return {
      "lat": (stop["lat"] as num).toDouble(),
      "lng": (stop["lng"] as num).toDouble(),
      "address": stop["name"] ?? stop["address"] ?? "Stop ${index + 1}",
      if (index == 0) "type": "pickup",
      if (index == widget.stops.length - 1) "type": "dropoff",
    };
    
  }

  Future<void> _bookMultiStopRide() async {
    if (selectedIndex == -1) return;
    
    setState(() => isBooking = true);

    try {
      final ride = rideTypes[selectedIndex];
      final pickup = widget.stops.first;
      final drop = widget.stops.last;
      
      // Validate coordinates
      final pickupLat = pickup['lat'];
      final pickupLng = pickup['lng'];
      final dropLat = drop['lat'];
      final dropLng = drop['lng'];

      if (pickupLat == null || pickupLng == null || 
          dropLat == null || dropLng == null) {
        throw Exception("Invalid coordinates for booking");
      }

      // Format all stops for the API
      final List<Map<String, dynamic>> formattedStops = widget.stops
    .sublist(1, widget.stops.length - 1) // intermediate stops
    .asMap()
    .entries
    .map((entry) => {
          "lat": (entry.value["lat"] as num).toDouble(),
          "lng": (entry.value["lng"] as num).toDouble(),
          "address": entry.value["name"] ?? entry.value["address"] ?? "Stop ${entry.key + 1}",
          "type": "stop",
        })
    .toList();

      final response = await Authservices.bookMultiRide(
  pickup: {
    "lat": pickupLat.toDouble(),
    "lng": pickupLng.toDouble(),
    "address": pickup['name'] ?? pickup['address'] ?? "$pickupLat,$pickupLng",
  },
  drop: {
    "lat": dropLat.toDouble(),
    "lng": dropLng.toDouble(),
    "address": drop['name'] ?? drop['address'] ?? "$dropLat,$dropLng",
  },
  stops: widget.stops,
  type: ride.originalKey,  // CHANGE FROM ride.type TO ride.originalKey
 fare: calculateFare(ride, distanceInKm),
);
print("✅ Ride booked: $response");

      if (response != null && mounted) {
        if (response.containsKey('error')) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['error']),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => Confirm(
              pickupLocation: pickup['name'] ?? pickup['address'] ?? "Pickup Location",
              dropoffLocation: drop['name'] ?? drop['address'] ?? "Drop Location",
              rideType: ride.type,
              originalRideType: ride.type,
              pickupLat: pickupLat.toDouble(),
              pickupLng: pickupLng.toDouble(),
              dropLat: dropLat.toDouble(),
              dropLng: dropLng.toDouble(),
              autoBook: false, // Multi-stop booking handled before navigation
            ),
          ),
        );
      } else {
        throw Exception("Booking failed - no response from server");
      }
    } catch (e) {
      print("❌ Booking error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Booking failed: ${e.toString()}"),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: "Retry",
              textColor: Colors.white,
              onPressed: _bookMultiStopRide,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isBooking = false);
    }
  }

  @override
  void initState() {
    super.initState();
    loadRideTypes();
    setMarkers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getRoutesForStops();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stops.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("No stops provided")),
      );
    }

    final firstStop = widget.stops.first;
    final firstLat = firstStop["lat"];
    final firstLng = firstStop["lng"];

    if (firstLat == null || firstLng == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Invalid coordinates for first stop")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text("Multi-Stop Booking"),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                "${widget.stops.length} stops",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Map Section
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    firstLat.toDouble(),
                    firstLng.toDouble(),
                  ),
                  zoom: 12,
                ),
                myLocationEnabled: true,
                markers: markers,
                polylines: _polylines,
                onMapCreated: (GoogleMapController controller) {
                  _controller = controller;
                  Future.delayed(const Duration(milliseconds: 500), () {
                    _fitMapToBounds();
                  });
                },
              ),
            ),

            // Route Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.route, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Text(
                        "Route Summary",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        "${distanceInKm.toStringAsFixed(1)} km",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "${widget.stops.length} stops",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Ride Types List
            Expanded(
              child: isLoading || distanceInKm == 0.0
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text("Loading ride options..."),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: rideTypes.length,
                      itemBuilder: (BuildContext context, int index) {
                        final ride = rideTypes[index];
                        final imagePath = getImageForRideType(ride.type, ride);
                        final price = calculateFare(ride, distanceInKm).toStringAsFixed(0);
                        final estimatedTime = (distanceInKm / ride.avgSpeed * 60)
                            .round();
                        
                        return TransportContainer(
                          imagePath,
                          ride.type,
                          "$estimatedTime mins away",
                          calculateDropTime(ride),
                          price,
                          "${distanceInKm.toStringAsFixed(1)} km",
                          selectedIndex == index,
                          () {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                        );
                      },
                    ),
            ),

            // Book Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (selectedIndex == -1 || isBooking) ? null : _bookMultiStopRide,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: isBooking
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.book_online, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              selectedIndex == -1
                                  ? "Select a ride type"
                                  : "Book ${rideTypes[selectedIndex].type}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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

Widget TransportContainer(
  String imageTransportContainer,
  String nameTransportContainer,
  String timeTransportContainer,
  String dropTimeTransportContainer,
  String priceTransportContainer,
  String distanceTransportContainer,
  bool isSelected,
  VoidCallback onTap,
) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.green.shade700 : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: Colors.green.shade200,
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          else
            const BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Vehicle Image - Updated to support both network and asset images
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageTransportContainer.startsWith('http')
                    ? Image.network(
                        imageTransportContainer,
                        width: 60,
                        height: 60,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.directions_car,
                              color: Colors.grey.shade500,
                              size: 30,
                            ),
                          );
                        },
                      )
                    : Image.asset(
                        imageTransportContainer,
                        width: 60,
                        height: 60,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.directions_car,
                              color: Colors.grey.shade500,
                              size: 30,
                            ),
                          );
                        },
                      ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Vehicle Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nameTransportContainer,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeTransportContainer,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Drop at $dropTimeTransportContainer",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Price and Distance
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₹$priceTransportContainer",
                  style: TextStyle(
                    color: isSelected ? Colors.green.shade700 : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  distanceTransportContainer,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            if (isSelected) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}