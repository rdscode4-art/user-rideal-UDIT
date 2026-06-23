import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rideal/screens/RideHistory/ridehistory.dart';
import 'package:rideal/screens/transport/confirmpickup.dart';
import 'package:flutter/material.dart';
import 'package:rideal/authservices.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geocoding/geocoding.dart'as geo;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
class RideType {
  final String type;
  final int farePerKm;
  final int avgSpeed;

  RideType({
    required this.type,
    required this.farePerKm,
    required this.avgSpeed,
  });

  factory RideType.fromJson(Map<String, dynamic> json) {
    String rideType = json['type'].toString().toLowerCase();

    int speed;
    switch (rideType) {
      case 'bike':
        speed = 25;
        break;
      case 'sedan':
        speed = 35;
        break;
      case 'suv':
        speed = 30;
        break;
      case 'ev':
        speed = 28;
        break;
      default:
        speed = 30; // fallback
    }

    return RideType(
      type: json['type'],
      farePerKm: json['farePerKm'],
      avgSpeed: speed,
    );
  }
}

class RideDetailScreen extends StatefulWidget {
  final String rideId;

  const RideDetailScreen({super.key, required this.rideId});

  @override
  State<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends State<RideDetailScreen> {
  bool _isRebooking = false;
  bool _isDisposed = false;
@override
  void initState() {
  super.initState();
  Authservices.debugSpecificRide(widget.rideId);
}
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  
  String formatTime(String dateTimeString) {
  try {
    // Parse as UTC and convert to local time
    DateTime dateTime = DateTime.parse(dateTimeString).toLocal();
    String period = dateTime.hour >= 12 ? "PM" : "AM";
    int hour = dateTime.hour == 0
        ? 12
        : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    String minute = dateTime.minute.toString().padLeft(2, '0');
    return "$hour:$minute $period";
  } catch (e) {
    return "Unknown Time";
  }
}

String formatDate(String dateTimeString) {
  try {
    // Parse as UTC and convert to local time
    DateTime dateTime = DateTime.parse(dateTimeString).toLocal();
    return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
  } catch (e) {
    return "Unknown Date";
  }
}
  // ✅ Relative time
  String getRelativeTime(String dateTimeString) {
    try {
      DateTime rideTime = DateTime.parse(dateTimeString);
      Duration diff = DateTime.now().difference(rideTime);

      if (diff.inDays > 0) return "${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago";
      if (diff.inHours > 0) return "${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago";
      if (diff.inMinutes > 0) return "${diff.inMinutes} min${diff.inMinutes == 1 ? '' : 's'} ago";
      return "Just now";
    } catch (e) {
      print("❌ Relative time error: $e");
      return "Unknown time";
    }
  }

  // ✅ Enhanced address getter with better error handling
  Future<String> getAddress(Stop stop) async {
    print("🔍 Getting address for stop: ${stop.toString()}");
    
    // First, check if we have a valid pre-existing address
    if (stop.address.isNotEmpty && 
        stop.address != "Unknown" && 
        stop.address != "Location Not Available" &&
        !_isCoordinateString(stop.address)) {
      print("✅ Using existing address: ${stop.address}");
      return stop.address;
    }

    // Try to use coordinates for reverse geocoding
    if (stop.lat != 0 && stop.lng != 0) {
      print("🔍 Attempting reverse geocoding for: ${stop.lat}, ${stop.lng}");
      try {
        final address = await _reverseGeocode(stop.lat, stop.lng);
        print("✅ Reverse geocoding successful: $address");
        return address;
      } catch (e) {
        print("❌ Reverse geocoding failed: $e");
      }
    }

    // Try to parse coordinate string from address field
    if (stop.address.isNotEmpty && _isCoordinateString(stop.address)) {
      print("🔍 Parsing coordinate string: ${stop.address}");
      final coords = _parseCoordinates(stop.address);
      if (coords != null) {
        try {
          final address = await _reverseGeocode(coords['lat']!, coords['lng']!);
          print("✅ Coordinate parsing successful: $address");
          return address;
        } catch (e) {
          print("❌ Coordinate parsing failed: $e");
        }
      }
    }

    print("❌ No valid address data found for stop");
    return "Location Not Available";
  }

  bool _isCoordinateString(String address) {
    final coordinateRegex = RegExp(r'^-?\d+\.?\d*\s*,\s*-?\d+\.?\d*$');
    return coordinateRegex.hasMatch(address.trim());
  }

  Map<String, double>? _parseCoordinates(String coordinateString) {
    try {
      final parts = coordinateString.split(',');
      if (parts.length == 2) {
        final lat = double.parse(parts[0].trim());
        final lng = double.parse(parts[1].trim());
        return {'lat': lat, 'lng': lng};
      }
    } catch (e) {
      print("❌ Coordinate parsing error: $e");
    }
    return null;
  }
Future<bool> _hasActiveRide() async {
  final prefs = await SharedPreferences.getInstance();

  final singleRideId = prefs.getString('rideId');
  final multipleRideIds = prefs.getStringList('ongoingRideIds') ?? [];

  List<String> allRideIds = [];
  if (singleRideId != null) allRideIds.add(singleRideId);
  allRideIds.addAll(multipleRideIds);
  allRideIds = allRideIds.toSet().toList();

  for (String rideId in allRideIds) {
    try {
      final rideStatus = await Authservices.getRideStatus(rideId);
      final status = rideStatus?['status']?.toString().toLowerCase();
      if (status == 'pending' || status == 'accepted' || status == 'ongoing') {
        return true; // Block rebooking
      }
    } catch (_) {
      continue; // Ignore errors
    }
  }
  return false;
}

  Future<String> _reverseGeocode(double lat, double lng) async {
    if (lat == 0 && lng == 0) {
      return "Invalid Location";
    }

    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        
        List<String> addressParts = [];
        if (p.name?.isNotEmpty == true && p.name != "Unnamed Road") {
          addressParts.add(p.name!);
        }
        if (p.street?.isNotEmpty == true && p.street != p.name) {
          addressParts.add(p.street!);
        }
        if (p.locality?.isNotEmpty == true) {
          addressParts.add(p.locality!);
        }
        if (p.subAdministrativeArea?.isNotEmpty == true) {
          addressParts.add(p.subAdministrativeArea!);
        }
        
        return addressParts.isNotEmpty 
            ? addressParts.join(', ')
            : "${p.locality ?? 'Unknown'}, ${p.administrativeArea ?? 'Unknown'}";
      }
    } catch (e) {
      print("❌ Geocoding API error: $e");
    }
    return "Location ($lat, $lng)";
  }

  // ✅ Add debug method to check ride data structure
  void _debugRideData(Ride ride) {
    print("🔍 DEBUG: Ride Data Structure");
    print("  Ride ID: ${ride.id}");
    print("  Status: ${ride.status}");
    print("  Created: ${ride.createdAt}");
    print("  Type: ${ride.type}");
    print("  Stops Count: ${ride.stops.length}");
    
    for (int i = 0; i < ride.stops.length; i++) {
      final stop = ride.stops[i];
      print("  Stop $i: ${stop.toString()}");
    }
    
    print("  Pickup Stop: ${ride.pickupStop.toString()}");
    print("  Dropoff Stop: ${ride.dropoffStop.toString()}");
  }

  // ✅ NEW: Determine if this is a multi-stop ride
  bool _isMultiStopRide(Ride ride) {
    // Count intermediate stops only
    return ride.stops.length > 2;
  }

  // ✅ NEW: Handle rebook functionality for both normal and multi-stop rides
 Future<void> _handleRebook(Ride ride, String fromAddress, String toAddress) async {
  bool hasActiveRide = await _hasActiveRide();
  if (hasActiveRide) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ You already have an active ride. Cannot rebook.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
    return;
  }

  // ✅ NEW: Check if ride type is unknown and handle it
  String rideType = ride.type;
  
  if (rideType == 'unknown' || rideType.isEmpty) {
    print("⚠️ Ride type is unknown, checking stored types...");
    
    // Try to get stored ride type
    final storedType = await Authservices.getStoredRideType(ride.id);
    
    if (storedType != null && storedType != 'unknown') {
      rideType = storedType;
      print("✅ Retrieved stored ride type: $rideType");
    } else {
      // ✅ Show ride type selector dialog
      final selectedType = await _showRideTypeSelector(context);
      
      if (selectedType == null) {
        print("❌ User cancelled ride type selection");
        return;
      }
      
      rideType = selectedType;
      print("✅ User selected ride type: $rideType");
    }
  }

  _safeSetState(() {
    _isRebooking = true;
  });

  try {
    print("🚀 Starting rebook with type: $rideType");
    print("📱 Current Ride ID: ${ride.id}");
    print("🔍 Is Multi-Stop: ${_isMultiStopRide(ride)}");
    
    Map<String, dynamic>? result;

    if (_isMultiStopRide(ride)) {
      result = await _rebookMultiRide(ride, rideType);
    } else {
      result = await _rebookNormalRide(ride, fromAddress, toAddress, rideType);
    }

    print("🔍 Final rebook result: $result");

    if (result != null && !result.containsKey('error')) {
      String? rideId = result['rideId'] ?? result['ride']?['_id'];
      
      if (rideId != null && rideId.isNotEmpty) {
        print("✅ Rebook successful! New Ride ID: $rideId");
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Ride rebooked successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Confirm(
                pickupLocation: fromAddress,
                dropoffLocation: toAddress,
                rideType: rideType,
                originalRideType: ride.type, // ✅ Pass backend key
                pickupLat: ride.pickupStop.lat,
                pickupLng: ride.pickupStop.lng,
                dropLat: ride.dropoffStop.lat,
                dropLng: ride.dropoffStop.lng,
                autoBook: false, // Don't re-book
              ),
            ),
          );
        }
      } else {
        throw Exception("No ride ID in response");
      }
    } else {
      final errorMsg = result?['error'] ?? result?['msg'] ?? "Booking failed";
      throw Exception(errorMsg);
    }
  } catch (e) {
    print("❌ Rebook error: $e");
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    _safeSetState(() {
      _isRebooking = false;
    });
  }
}

  
  Future<String?> _showRideTypeSelector(BuildContext context) async {
  final List<Map<String, dynamic>> rideTypes = [
    {
      'type': 'bike',
      'name': 'Bike',
      'icon': Icons.two_wheeler,
      'color': Colors.orange,
      'description': '₹10-15/km'
    },
    {
      'type': 'sedan',
      'name': 'Sedan',
      'icon': Icons.directions_car,
      'color': Colors.blue,
      'description': '₹15-20/km'
    },
    {
      'type': 'suv',
      'name': 'SUV',
      'icon': Icons.local_taxi,
      'color': Colors.green,
      'description': '₹20-25/km'
    },
    {
      'type': 'ev',
      'name': 'EV',
      'icon': Icons.electric_car,
      'color': Colors.teal,
      'description': '₹12-18/km'
    },
  ];

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.directions_car, color: Colors.blue),
            SizedBox(width: 8.w),
            Text('Select Ride Type'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: rideTypes.map((rideType) {
            return Card(
              margin: EdgeInsets.symmetric(vertical: 4.w),
              child: ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: rideType['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    rideType['icon'],
                    color: rideType['color'],
                    size: 24,
                  ),
                ),
                title: Text(
                  rideType['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
                subtitle: Text(
                  rideType['description'],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12.sp,
                  ),
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(dialogContext).pop(rideType['type']);
                },
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: Text('Cancel'),
          ),
        ],
      );
    },
  );
}
  // ✅ NEW: Rebook normal ride
Future<Map<String, dynamic>?> _rebookNormalRide(

    Ride ride, String fromAddress, String toAddress,String rideType, ) async {
  print("🔄 Rebooking normal ride...");
  double? pickupLat, pickupLng, dropLat, dropLng;

  try {
    final pickupLocations = await geo.locationFromAddress(fromAddress);
    final dropLocations = await geo.locationFromAddress(toAddress);

    if (pickupLocations.isNotEmpty && dropLocations.isNotEmpty) {
      pickupLat = pickupLocations.first.latitude;
      pickupLng = pickupLocations.first.longitude;
      dropLat = dropLocations.first.latitude;
      dropLng = dropLocations.first.longitude;

      print("✅ Coordinates resolved:");
      print("  Pickup: $pickupLat, $pickupLng");
      print("  Dropoff: $dropLat, $dropLng");
    }
  } catch (e) {
    print("❌ Geocoding failed: $e");
  }

  if (pickupLat == null || pickupLng == null || dropLat == null || dropLng == null) {
    print("❌ Could not resolve coordinates for rebooking");
    return null;
  }

  // Calculate estimated fare based on distance
  double distance = _calculateDistance(pickupLat, pickupLng, dropLat, dropLng);
  double estimatedFare = _calculateFare(distance, rideType);
  
  print("📏 Distance: ${distance.toStringAsFixed(2)} km");
  print("💰 Estimated Fare: ₹${estimatedFare.toStringAsFixed(2)}");

  try {
    final result = await Authservices.bookRide(
      pickupLocation: fromAddress,
      dropoffLocation: toAddress,
      rideType: ride.type,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropLat: dropLat,
      dropLng: dropLng,
      fare: estimatedFare, // Add fare parameter
    );
    return result;
  } catch (e) {
    print("❌ Booking API call failed: $e");
    return null;
  }
}

// Add distance calculation using Haversine formula
double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371; // Radius in kilometers
  
  double dLat = _toRadians(lat2 - lat1);
  double dLon = _toRadians(lon2 - lon1);
  
  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
      sin(dLon / 2) * sin(dLon / 2);
  
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  
  return earthRadius * c;
}

double _toRadians(double degree) {
  return degree * pi / 180;
}

// Add fare calculation based on ride type
double _calculateFare(double distanceKm, String rideType) {
  double baseFare;
  double perKmRate;
  
  switch (rideType.toLowerCase()) {
    case 'economy':
      baseFare = 50.0;
      perKmRate = 10.0;
      break;
    case 'premium':
      baseFare = 100.0;
      perKmRate = 15.0;
      break;
    case 'luxury':
      baseFare = 150.0;
      perKmRate = 20.0;
      break;
    default:
      baseFare = 50.0;
      perKmRate = 10.0;
  }
  
  return baseFare + (distanceKm * perKmRate);
}
  // ✅ NEW: Rebook multi-stop ride
  Future<Map<String, dynamic>?> _rebookMultiRide(Ride ride,String rideType, ) async {
    print("🔄 Rebooking multi-stop ride...");
    print("🚗 Ride Type: ${ride.type}");
    print("📍 Total Stops: ${ride.stops.length}");
    
    try {
      // Prepare pickup data
      final pickupAddress = await getAddress(ride.pickupStop);
      final pickup = {
        "address": pickupAddress,
        "lat": ride.pickupStop.lat,
        "lng": ride.pickupStop.lng,
      };
      print("🏁 Pickup: $pickup");

      // Prepare drop data
      final dropAddress = await getAddress(ride.dropoffStop);
      final drop = {
        "address": dropAddress,
        "lat": ride.dropoffStop.lat,
        "lng": ride.dropoffStop.lng,
      };
      print("🏁 Drop: $drop");

      // Prepare intermediate stops (exclude pickup and dropoff)
      List<Map<String, dynamic>> stops = [];
      for (int i = 1; i < ride.stops.length - 1; i++) {
        final stop = ride.stops[i];
        final stopAddress = await getAddress(stop);
        final stopData = {
          "address": stopAddress,
          "lat": stop.lat,
          "lng": stop.lng,
          "order": i,
        };
        stops.add(stopData);
        print("🛑 Stop $i: $stopData");
      }

      // Validate data before API call
      if (pickupAddress == "Location Not Available" || pickupAddress == "Unknown Location") {
        throw Exception("Unable to resolve pickup address");
      }

      if (dropAddress == "Location Not Available" || dropAddress == "Unknown Location") {
        throw Exception("Unable to resolve drop address");
      }

      if (pickup["lat"] == 0.0 && pickup["lng"] == 0.0) {
        throw Exception("Invalid pickup coordinates");
      }

      if (drop["lat"] == 0.0 && drop["lng"] == 0.0) {
        throw Exception("Invalid drop coordinates");
      }

      // Calculate estimated fare - basic calculation
      double estimatedFare = 50.0 + (stops.length * 15.0); // Base fare + per stop
      print("💰 Estimated Fare: $estimatedFare");
      
      // Validate ride type
     
      print("📤 Calling bookMultiRide API with:");
      print("  - Pickup: $pickup");
      print("  - Drop: $drop");
      print("  - Stops: $stops");
      print("  - Type: $rideType");
      print("  - Fare: $estimatedFare");
      
      final result = await Authservices.bookMultiRide(
        pickup: pickup,
        drop: drop,
        stops: stops,
        type: rideType,
        fare: estimatedFare,
      );
      
      print("📬 Multi Rebook Result: $result");
      return result;
    } catch (e) {
      print("❌ Multi-rebook preparation error: $e");
      rethrow; // Re-throw to be caught by the caller
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug the API response structure
    Authservices.debugRideStructure(widget.rideId);
    
    return Scaffold(
      appBar: AppBar(title: Text("Ride Details"), centerTitle: true),
      body: FutureBuilder<Ride?>(
        future: Authservices.getRideDetail(widget.rideId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            print("❌ Ride detail fetch error: ${snapshot.error}");
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16.w),
                  Text("Error loading ride details"),
                  SizedBox(height: 8.w),
                  Text("${snapshot.error}", style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 16.w),
                  ElevatedButton(
                    onPressed: () => _safeSetState(() {}),
                    child: Text("Retry"),
                  ),
                ],
              ),
            );
          }
          
          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16.w),
                  Text("Ride not found"),
                ],
              ),
            );
          }

          final ride = snapshot.data!;
          
          // Debug the ride data
          _debugRideData(ride);
          
          // Check if we have valid stops
          if (ride.stops.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 64, color: Colors.orange),
                  SizedBox(height: 16.w),
                  Text("No location data available"),
                  SizedBox(height: 8.w),
                  Text("Ride ID: ${ride.id}", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final pickupStop = ride.pickupStop;
          final dropStop = ride.dropoffStop;
          final isMultiStop = _isMultiStopRide(ride);

          return FutureBuilder(
            future: Future.wait([
              getAddress(pickupStop), 
              getAddress(dropStop)
            ]),
            builder: (context, AsyncSnapshot<List<String>> addrSnapshot) {
               
              if (addrSnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16.w),
                      Text("Loading location details..."),
                    ],
                  ),
                );
              }

              if (addrSnapshot.hasError) {
                print("❌ Address fetch error: ${addrSnapshot.error}");
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_disabled, size: 64, color: Colors.red),
                      SizedBox(height: 16.w),
                      Text("Failed to load addresses"),
                      SizedBox(height: 8.w),
                      Text("${addrSnapshot.error}", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              final fromAddress = addrSnapshot.data?[0] ?? "Unknown Location";
              final toAddress = addrSnapshot.data?[1] ?? "Unknown Location";

              return _buildContent(ride, isMultiStop, fromAddress, toAddress, pickupStop, dropStop);
            },
          );
        },
      ),
    );
  }

  // Add this method to your _RideDetailScreenState class
// Add this method to your _RideDetailScreenState class
Widget _buildContent(Ride ride, bool isMultiStop, String fromAddress, String toAddress, Stop pickupStop, Stop dropStop) {
  return LayoutBuilder(
    builder: (context, constraints) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight - 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trip Status Card
              Card(
                color: _getStatusColor(ride.status),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    children: [
                      Icon(
                        _getStatusIcon(ride.status),
                        color: Colors.white,
                        size: 32,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Ride Status",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14.sp,
                              ),
                            ),
                            Text(
                              ride.status.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.w),

              // Driver Details Card (if driver assigned)
              if (ride.driver != null) ...[
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, color: Colors.blue),
                            SizedBox(width: 8.w),
                            Text(
                              "Driver Information",
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.w),
                        _buildDetailRow("Driver Name", ride.driver!.name),
                        _buildDetailRow("Driver Phone", ride.driver!.phone),
                        if (ride.vehicleNumber != null && ride.vehicleNumber!.isNotEmpty)
                          _buildDetailRow("Vehicle Number", ride.vehicleNumber!),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.w),
              ],

              // Trip Info Card
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange),
                          SizedBox(width: 8.w),
                          Text(
                            "Trip Information",
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Spacer(),
                          if (isMultiStop)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.w,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                "Multi-Stop",
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 12.w),
                      _buildDetailRow("Date", formatDate(ride.createdAt)),
                      _buildDetailRow("Time", formatTime(ride.createdAt)),
                      _buildDetailRow("Booked", getRelativeTime(ride.createdAt)),
                      _buildDetailRow("Ride Type", ride.type.toUpperCase()),
                      if (ride.rating != null)
                        _buildRatingRow("Your Rating", ride.rating!),
                      if (isMultiStop)
                        _buildDetailRow("Total Stops", "${ride.stops.length}"),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.w),

              // Route Info Card
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.route, color: Colors.green),
                          SizedBox(width: 8.w),
                          Text(
                            "Route Information",
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.w),
                      
                      _buildLocationRow(
                        Icons.location_on,
                        Colors.green,
                        "Pickup Location",
                        fromAddress,
                        pickupStop,
                      ),
                      
                      if (isMultiStop) ...[
                        SizedBox(height: 16.w),
                        _buildIntermediateStops(ride),
                      ],
                      
                      SizedBox(height: 16.w),
                      _buildLocationRow(
                        Icons.location_on,
                        Colors.red,
                        "Drop Location",
                        toAddress,
                        dropStop,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.w),

              // Additional Details Card
              if (ride.feedback.isNotEmpty || ride.rebookedFrom != null) ...[
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.notes, color: Colors.purple),
                            SizedBox(width: 8.w),
                            Text(
                              "Additional Details",
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.w),
                        if (ride.feedback.isNotEmpty)
                          _buildDetailRow("Feedback", ride.feedback),
                        if (ride.rebookedFrom != null)
                          _buildDetailRow("Rebooked From", ride.rebookedFrom!),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.w),
              ],
              
              // Rebook Button
              if (_shouldShowRebookButton(fromAddress, toAddress, ride))
                _buildRebookButton(ride, fromAddress, toAddress, isMultiStop),
            ],
          ),
        ),
      );
    },
  );
}

// Helper method for status colors
Color _getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return Colors.green;
    case 'ongoing':
      return Colors.blue;
    case 'cancelled':
      return Colors.red;
    case 'accepted':
      return Colors.orange;
    case 'pending':
      return Colors.grey;
    default:
      return Colors.grey;
  }
}

// Helper method for status icons
IconData _getStatusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return Icons.check_circle;
    case 'ongoing':
      return Icons.directions_car;
    case 'cancelled':
      return Icons.cancel;
    case 'accepted':
      return Icons.thumb_up;
    case 'pending':
      return Icons.hourglass_empty;
    default:
      return Icons.info;
  }
}

// Helper method for rating display
Widget _buildRatingRow(String label, int rating) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 4.w),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100.w,
          child: Text("$label:", style: TextStyle(color: Colors.grey)),
        ),
        Expanded(
          child: Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 20,
              );
            }),
          ),
        ),
      ],
    ),
  );
}
  Widget _buildLocationRow(IconData icon, Color color, String title, String address, Stop stop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(height: 4.w),
              Text(address, style: TextStyle(color: Colors.grey[600])),
              if (stop.lat != 0 && stop.lng != 0) ...[
                SizedBox(height: 2.w),
                Text(
                  "(${stop.lat.toStringAsFixed(4)}, ${stop.lng.toStringAsFixed(4)})",
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIntermediateStops(Ride ride) {
    final intermediateStops = ride.stops.sublist(1, ride.stops.length - 1);
    
    return FutureBuilder<List<String>>(
      future: Future.wait(intermediateStops.map((s) => getAddress(s))),
      builder: (context, stopsSnapshot) {
        if (stopsSnapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(8.0.w),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (!stopsSnapshot.hasData) {
          return SizedBox.shrink();
        }
        
        final intermediateAddresses = stopsSnapshot.data!;
        
        return Column(
          children: List.generate(intermediateAddresses.length, (i) {
            final stop = intermediateStops[i];
            final stopAddress = intermediateAddresses[i];
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 8.w),
              child: _buildLocationRow(
                Icons.stop_circle,
                Colors.orange,
                "Stop ${i + 1}",
                stopAddress,
                stop,
              ),
            );
          }),
        );
      },
    );
  }

  bool _shouldShowRebookButton(String fromAddress, String toAddress, Ride ride) {
    return fromAddress != "Location Not Available" && 
           toAddress != "Location Not Available" &&
           ride.pickupStop.lat != 0.0 && 
           ride.pickupStop.lng != 0.0 &&
           ride.dropoffStop.lat != 0.0 && 
           ride.dropoffStop.lng != 0.0;
  }

  Widget _buildRebookButton(Ride ride, String fromAddress, String toAddress, bool isMultiStop) {
    return SizedBox(
      width: double.infinity,
      height: 50.w,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
        onPressed: _isRebooking 
          ? null 
          : () => _handleRebook(ride, fromAddress, toAddress),
        child: _isRebooking
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  isMultiStop ? "Rebooking Multi-Stop..." : "Rebooking...",
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ],
            )
          : Text(
              isMultiStop ? "Rebook Multi-Stop Ride" : "Rebook Ride",
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding:  EdgeInsets.symmetric(vertical: 4.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text("$label:", style: TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}