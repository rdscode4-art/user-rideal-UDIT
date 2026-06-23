import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:rideal/authservices.dart';
import 'package:rideal/screens/RideHistory/ridehistoryspecific.dart';
import 'package:rideal/widget/rideoptioncard.dart';
import 'package:geocoding/geocoding.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {

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
  Future<String> getAddressFromLatLng(double lat, double lng) async {
    if (lat == 0 && lng == 0) return "Location Not Available";

    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        List<String> addressParts = [];
        if (place.name?.isNotEmpty == true && place.name != "Unnamed Road") {
          addressParts.add(place.name!);
        }
        if (place.street?.isNotEmpty == true) addressParts.add(place.street!);
        if (place.locality?.isNotEmpty == true) addressParts.add(place.locality!);
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
      return "Location ($lat, $lng)";
    }
  }

  Future<String> getAddressFromStop(Stop stop) async {
    if (stop.address.isNotEmpty &&
        stop.address != "Unknown" &&
        !_isCoordinateString(stop.address)) {
      return stop.address;
    }
    if (stop.lat != 0 && stop.lng != 0) {
      return await getAddressFromLatLng(stop.lat, stop.lng);
    }
    if (stop.address.isNotEmpty && _isCoordinateString(stop.address)) {
      final coords = _parseCoordinates(stop.address);
      if (coords != null) {
        return await getAddressFromLatLng(coords['lat']!, coords['lng']!);
      }
    }
    return "";
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
    } catch (e) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Floating Header
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                    ),
                  ),
                  Text(
                    "Ride History",
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(width: 40.w), // Balance the row
                ],
              ),
            ),
            
            Expanded(
              child: FutureBuilder<List<Ride>>(
                future: Authservices.fetchRideHistory(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F9D58))));
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: Colors.grey)));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade300),
                          SizedBox(height: 16.w),
                          Text("No rides found", style: TextStyle(color: Colors.grey.shade500, fontSize: 16.sp, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  } else {
                    final rides = snapshot.data!;

                    return ListView.builder(
                      padding: EdgeInsets.only(bottom: 24.w),
                      itemCount: rides.length,
                      itemBuilder: (context, index) {
                        final ride = rides[index];

                        return FutureBuilder<List<String>>(
                          future: Future.wait([
                            getAddressFromStop(ride.pickupStop),
                            getAddressFromStop(ride.dropoffStop),
                          ]),
                          builder: (context, addressSnapshot) {
                            // Show loading state while addresses are being resolved
                            if (addressSnapshot.connectionState == ConnectionState.waiting) {
                              return RideOptionCard(
                                screenWidget: RideDetailScreen(rideId: ride.id),
                                rideId: ride.id,
                                startTime: formatTime(ride.createdAt),
                                from: "Loading...",
                                to: "Loading...",
                                isBus: false,
                                subtitle: ride.status.isNotEmpty ? ride.status : "",
                                extraWidget: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Loading route details...", 
                                        style: TextStyle(fontSize: 12.sp, color: Colors.grey, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              );
                            }

                            // Use resolved addresses or fallback
                            final fromAddress = addressSnapshot.data?[0] ?? "Location unavailable";
                            final toAddress = addressSnapshot.data?[1] ?? "Location unavailable";

                            return RideOptionCard(
                              screenWidget: RideDetailScreen(rideId: ride.id),
                              rideId: ride.id,
                              startTime: formatTime(ride.createdAt),
                              from: fromAddress,
                              to: toAddress,
                              subtitle: ride.status.isNotEmpty ? ride.status : "",
                              extraWidget: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: ride.stops.asMap().entries.map((entry) {
                                  int i = entry.key;
                                  Stop stop = entry.value;
                                  return FutureBuilder<String>(
                                    future: getAddressFromStop(stop),
                                    builder: (context, snapshot) {
                                      String address = snapshot.data ?? "Loading...";
                                      String label;
                                      if (stop.type == 'pickup') {
                                        label = "Pickup";
                                      } else if (stop.type == 'dropoff') {
                                        label = "Dropoff";
                                      } else {
                                        label = "Stop $i";
                                      }
                                      return Padding(
                                        padding: EdgeInsets.only(top: 4.0.w),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("$label:", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                                            SizedBox(width: 4.w),
                                            Expanded(child: Text(address, style: TextStyle(fontSize: 12.sp, color: Colors.black87))),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Updated Ride Model with all fields from API
class Ride {
  final String id;
  final String status;
  final String createdAt;
  final String type;
  final String feedback;
  final String? rebookedFrom;
  final List<Stop> stops;
  
  // NEW: Additional fields from API
  final Driver? driver;
  final String? vehicleNumber;
  final int? rating;
  final Riderr? riderr;

  Ride({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.type,
    required this.feedback,
    this.rebookedFrom,
    required this.stops,
    this.driver,
    this.vehicleNumber,
    this.rating,
    this.riderr,
  });

  Stop get pickupStop => stops.firstWhere(
        (s) => s.type == 'pickup',
        orElse: () => stops.isNotEmpty ? stops.first : Stop.unknown(type: 'pickup'),
      );
      
  Stop get dropoffStop => stops.lastWhere(
        (s) => s.type == 'dropoff',
        orElse: () => stops.length > 1 ? stops.last : Stop.unknown(type: 'dropoff'),
      );

  factory Ride.fromJson(Map<String, dynamic> json) {
  print('🔍 Parsing Ride from JSON keys: ${json.keys.toList()}');
  
  List<Stop> stops = [];

  // STEP 1: Add pickup location from 'pickup' key (always first)
  if (json.containsKey('pickup') && json['pickup'] is Map) {
    print('🔍 Found "pickup" object');
    final pickupData = json['pickup'] as Map<String, dynamic>;
    final pickupStop = Stop.fromJson({
      ...pickupData,
      'type': 'pickup',
      '_id': pickupData['_id'] ?? 'pickup_${DateTime.now().millisecondsSinceEpoch}',
    });
    stops.add(pickupStop);
    print('✅ Added pickup stop: ${pickupStop.address} (${pickupStop.lat}, ${pickupStop.lng})');
  }

  // STEP 2: Parse ALL items in 'stops' array as intermediate stops
  // NOTE: These are waypoints/intermediate stops, regardless of their 'type' field
  if (json['stops'] is List && (json['stops'] as List).isNotEmpty) {
    print('🔍 Found stops array with ${(json['stops'] as List).length} items');
    
    for (int i = 0; i < (json['stops'] as List).length; i++) {
      final stopData = json['stops'][i];
      if (stopData == null || stopData is! Map<String, dynamic>) continue;
      
      // ALL items in stops array are intermediate stops, override the type
      final intermediateStop = Stop.fromJson({
        ...stopData,
        'type': 'stop', // Force to 'stop' type for intermediate locations
      });
      
      stops.add(intermediateStop);
      print('✅ Added intermediate stop ${i + 1}: ${intermediateStop.address} (${intermediateStop.lat}, ${intermediateStop.lng})');
    }
  }

  // STEP 3: Add the final dropoff location from 'drop' key (always last)
  if (json.containsKey('drop') && json['drop'] is Map) {
    print('🔍 Found "drop" object');
    final dropData = json['drop'] as Map<String, dynamic>;
    final dropoffStop = Stop.fromJson({
      ...dropData,
      'type': 'dropoff',
      '_id': dropData['_id'] ?? 'drop_${DateTime.now().millisecondsSinceEpoch}',
    });
    stops.add(dropoffStop);
    print('✅ Added final dropoff: ${dropoffStop.address} (${dropoffStop.lat}, ${dropoffStop.lng})');
  }

  // STEP 4: Final validation and fallback
  if (stops.isEmpty || !stops.any((s) => s.type == 'pickup')) {
    print('⚠️ No valid stops found, creating fallback stops');
    // Create fallback stops if needed
    if (json.containsKey('pickupLocation') || json.containsKey('pickupLat')) {
      stops.insert(0, Stop(
        id: 'pickup_fallback',
        address: json['pickupLocation']?.toString() ?? 'Pickup Location',
        lat: _toDoubleSafe(json['pickupLat']),
        lng: _toDoubleSafe(json['pickupLng']),
        type: 'pickup',
      ));
    }
    
    if (json.containsKey('dropLocation') || json.containsKey('dropLat')) {
      stops.add(Stop(
        id: 'drop_fallback',
        address: json['dropLocation']?.toString() ?? 'Drop Location',
        lat: _toDoubleSafe(json['dropLat']),
        lng: _toDoubleSafe(json['dropLng']),
        type: 'dropoff',
      ));
    }
  }

  // STEP 5: Ensure we have at least pickup and dropoff
  if (!stops.any((s) => s.type == 'dropoff') && stops.length >= 2) {
    // If last stop isn't marked as dropoff, mark it
    final lastStop = stops.removeLast();
    stops.add(lastStop.copyWith(type: 'dropoff'));
    print('⚠️ Corrected last stop to dropoff type');
  }

  // Final summary
  print('📊 Final stops structure (${stops.length} total stops):');
  for (int i = 0; i < stops.length; i++) {
    final stop = stops[i];
    String label = stop.type == 'pickup' ? 'PICKUP' : 
                   stop.type == 'dropoff' ? 'DROP' : 
                   'STOP $i';
    print('  [$i] $label: ${stop.address} (${stop.lat}, ${stop.lng})');
  }

  // Validate coordinates
  int invalidCoords = 0;
  for (var stop in stops) {
    if (stop.lat == 0.0 && stop.lng == 0.0) {
      print('⚠️ WARNING: Stop has invalid coordinates: ${stop.address}');
      invalidCoords++;
    }
  }
  
  if (invalidCoords > 0) {
    print('⚠️ Total stops with invalid coordinates: $invalidCoords');
  }

  // Determine if multi-stop
  final intermediateStopsCount = stops.where((s) => s.type == 'stop').length;
  if (intermediateStopsCount > 0) {
    print('🛑 Multi-stop ride detected with $intermediateStopsCount intermediate stop(s)');
  }

  // Extract basic fields
  final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
  final status = json['status']?.toString() ?? '';
  final createdAt = json['createdAt']?.toString() ?? DateTime.now().toIso8601String();
  
  // Extract ride type
  String rideType = 'unknown';
  
  // Try API fields first
  if (json['rideType'] != null && json['rideType'].toString().isNotEmpty) {
    rideType = json['rideType'].toString().toLowerCase();
    print('✅ Found rideType from API: $rideType');
  } else if (json['type'] != null && json['type'].toString().isNotEmpty) {
    rideType = json['type'].toString().toLowerCase();
    print('✅ Found type from API: $rideType');
  } else if (json['vehicleType'] != null && json['vehicleType'].toString().isNotEmpty) {
    rideType = json['vehicleType'].toString().toLowerCase();
    print('✅ Found vehicleType from API: $rideType');
  } else {
    // ✅ Fallback: Try to get from local storage
    print('⚠️ No ride type in API response for ride $id');
    print('Available keys: ${json.keys.toList()}');
    
    // We'll handle this asynchronously in the widget
    rideType = 'unknown';
  }
  
  
  final feedback = json['feedback']?.toString() ?? '';
  final rebookedFrom = json['rebookedFrom']?.toString();
  
  // Parse driver
  Driver? driver;
  if (json['driver'] != null && json['driver'] is Map) {
    driver = Driver.fromJson(json['driver'] as Map<String, dynamic>);
    print('✅ Parsed driver: ${driver.name}');
  }
  
  // Parse vehicle number
  final vehicleNumber = json['vehicleNumber']?.toString();
  
  // Parse rating
  final rating = json['rating'] != null ? int.tryParse(json['rating'].toString()) : null;
  
  // Parse rider
  Riderr? rider;
  if (json['rider'] != null && json['rider'] is Map) {
    rider = Riderr.fromJson(json['rider'] as Map<String, dynamic>);
    print('✅ Parsed rider: ${rider.name}');
  }

  final ride = Ride(
    id: id,
    status: status,
    createdAt: createdAt,
    type: rideType,
    feedback: feedback,
    rebookedFrom: rebookedFrom,
    stops: stops,
    driver: driver,
    vehicleNumber: vehicleNumber,
    rating: rating,
    riderr: rider,
  );

  print('✅ Created Ride: id=$id, status=$status, type=$rideType, totalStops=${stops.length}, intermediateStops=$intermediateStopsCount, driver=${driver?.name ?? "none"}');
  return ride;
}

static double _toDoubleSafe(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
  @override
  String toString() {
    return 'Ride(id: $id, status: $status, type: $type, stops: ${stops.length}, driver: ${driver?.name ?? "none"})';
  }
}

// NEW: Driver model
class Driver {
  final String id;
  final String name;
  final String phone;

  Driver({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Driver',
      phone: json['phone']?.toString() ?? 'N/A',
    );
  }

  @override
  String toString() => 'Driver(name: $name, phone: $phone)';
}

// NEW: Rider model
class Riderr {
  final String id;
  final String name;
  final String phone;

  Riderr({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory Riderr.fromJson(Map<String, dynamic> json) {
    return Riderr(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Rider',
      phone: json['phone']?.toString() ?? 'N/A',
    );
  }

  @override
  String toString() => 'Rider(name: $name, phone: $phone)';
}

// Stop model remains the same as your original
class Stop {
  final String id;
  final String address;
  final double lat;
  final double lng;
  final String type;

  Stop({
    required this.id,
    required this.address,
    required this.lat,
    required this.lng,
    required this.type,
  });

  factory Stop.fromJson(Map<String, dynamic> json) {
    print("🔍 Parsing Stop from JSON: $json");

    double lat = _extractCoordinate(json, ['lat', 'latitude', 'y']);
    double lng = _extractCoordinate(json, ['lng', 'longitude', 'lon', 'x']);
    String address = _extractAddress(json);
    String id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    String type = json['type']?.toString() ?? '';

    final stop = Stop(
      id: id,
      address: address.isNotEmpty ? address : 'Unknown',
      lat: lat,
      lng: lng,
      type: type,
    );

    print("✅ Created Stop: $stop");
    return stop;
  }

  static double _extractCoordinate(Map<String, dynamic> json, List<String> keys) {
    for (String key in keys) {
      if (json.containsKey(key)) {
        final value = json[key];
        if (value != null) {
          return _toDoubleSafe(value);
        }
      }
    }
    return 0.0;
  }

  static String _extractAddress(Map<String, dynamic> json) {
    final addressKeys = ['address', 'name', 'description', 'location', 'title'];
    
    for (String key in addressKeys) {
      if (json.containsKey(key)) {
        final value = json[key]?.toString() ?? '';
        if (value.isNotEmpty && value.toLowerCase() != 'null') {
          return value;
        }
      }
    }
    
    return '';
  }

  factory Stop.unknown({String type = ''}) => Stop(
        id: '',
        address: 'Unknown Location',
        lat: 0.0,
        lng: 0.0,
        type: type,
      );

  Stop copyWith({
    String? id,
    String? address,
    double? lat,
    double? lng,
    String? type,
  }) {
    return Stop(
      id: id ?? this.id,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      type: type ?? this.type,
    );
  }

  static double _toDoubleSafe(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  String toString() {
    return 'Stop(id: "$id", address: "$address", lat: $lat, lng: $lng, type: "$type")';
  }
}