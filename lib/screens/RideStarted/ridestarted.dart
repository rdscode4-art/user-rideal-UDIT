import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:rideal/authservices.dart';
import 'package:rideal/screens/AfterRide/Rating.dart';
import 'package:rideal/screens/AfterRide/payment.dart';
import 'package:rideal/screens/Complains/complain.dart';
import 'package:rideal/screens/RideHistory/ridehistory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class RideStarted extends StatefulWidget {
  const RideStarted({super.key, required this.rideId});
  final String rideId;

  @override
  State<RideStarted> createState() => _RideStartedState();
}

class _RideStartedState extends State<RideStarted> {
  StreamSubscription<Position>? _positionStream;
  GoogleMapController? _controller;
  bool _isPaid = false;
  LatLng? _userLocation;
  String? _persistentRideId;
  Future<List<Map<String, String>>> getEmergencyContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsList = prefs.getStringList('emergency_contacts') ?? [];

    return contactsList.map((contact) {
      final parts = contact.split('|');
      return {
        'name': parts.length > 1 ? parts[0] : 'Unknown',
        'number': parts.length > 1 ? parts[1] : parts[0],
      };
    }).toList();
  }

  // Dynamic destinations
  LatLng? _dropLocation;
  List<LatLng> _stops = []; // Multiple stops
  int _currentStopIndex = 0; // Track current destination
  LatLng? _currentDestination; // Current target (either stop or final drop)
   bool _isChecking = false;
  bool _isNavigated = false;
  Timer? _locationTimer;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  List<LatLng> _polylineCoordinates = [];
  String _rideType = "regular"; // "regular" or "multiple_stops"
Future<void> _cancelRide() async {
  final bool? shouldCancel = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.cancel_outlined,
              color: Colors.red.shade600,
              size: 24,
            ),
            SizedBox(width: 12.w),
            Text(
              'Cancel Ride?',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel this ride? This action cannot be undone.',
          style: TextStyle(fontSize: 16.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Keep Ride',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Cancel Ride',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    },
  );

  if (shouldCancel == true) {
    try {
      // Show loading state
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12.w),
                Text('Cancelling ride...'),
              ],
            ),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            duration: const Duration(seconds: 30),
          ),
        );
      }

      // Cancel the ride
      if (widget.rideId.isNotEmpty) {
        final result = await Authservices.cancelRide(widget.rideId);
        
        if (result != null) {
          // Clear stored data
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('rideId');
          await prefs.remove('current_ride_id');
          await prefs.remove('rideStatus');
          await prefs.remove('ongoingRideIds');
          
          // Stop all timers and streams
          _locationTimer?.cancel();
          _positionStream?.cancel();
          
          if (mounted) {
            // Hide loading snackbar
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12.w),
                    Text('Ride cancelled successfully'),
                  ],
                ),
                backgroundColor: Colors.green.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            );
            
            // Navigate back
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              Navigator.pop(context);
            }
          }
        } else {
          throw Exception('Failed to cancel ride');
        }
      }
    } catch (e) {
      print("❌ Error cancelling ride: $e");
      
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text('Failed to cancel ride. Please try again.'),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
  @override
void initState() {
  super.initState();
   _ensureRideId();
  _persistentRideId = widget.rideId;
    if (_persistentRideId!.isEmpty) {
      print("❌ CRITICAL: Empty rideId passed to RideStarted widget!");
    } else {
      print("🔒 Persistent rideId stored: $_persistentRideId");
      // Store in SharedPreferences immediately
      _storeRideId(_persistentRideId!);
    }
    _initRide();
    _fetchRidePaymentStatus(widget.rideId);
}
Future<void> _ensureRideId() async {
  final prefs = await SharedPreferences.getInstance();

  // If widget provides rideId → use it
  if (widget.rideId.isNotEmpty) {
    _persistentRideId = widget.rideId;
  }
  // Otherwise fallback to saved rideId
  else if (prefs.containsKey('rideId')) {
    _persistentRideId = prefs.getString('rideId');
  }

  print("🔥 FINAL RIDE ID LOADED: $_persistentRideId");
}

Future<void> _storeRideId(String rideId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rideId', rideId);
    await prefs.setString('current_ride_id', rideId);
    print("💾 RideId stored in preferences: $rideId");
  }
Future<void> _fetchRidePaymentStatus(String rideId) async {
  try {
    final response = await http.get(
      Uri.parse("https://backend.ridealmobility.com/rides/$rideId"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${await Authservices.getToken()}",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String status = data["paymentStatus"] ?? "unpaid";
      String rideStatus = (data["status"]?.toString() ?? "").toLowerCase();

      if (mounted) {
        setState(() {
          _isPaid = status.toLowerCase() == "paid";
        });
      }

      print("💰 Payment status: $_isPaid");
      print("🚗 Ride status: $rideStatus");
      
      // ✅ CHECK: If ride is completed, navigate immediately
      if (rideStatus == "completed" && !_isNavigated) {
        print("🎉 Ride completed detected! Navigating to rating...");
        _handleRideCompletion(rideId);
      }
    } else {
      print(
        "❌ Failed to fetch ride info. Status code: ${response.statusCode}",
      );
    }
  } catch (e) {
    print("❌ Error fetching ride info: $e");
  }
}

// ✅ Add this new method
Future<void> _handleRideCompletion(String completedRideId) async {
    if (_isNavigated) {
      print("⚠️ Already navigated");
      return;
    }
    
    print("🏁 Starting ride completion process...");
    
    setState(() {
      _isNavigated = true;
    });
    
    // Stop all timers
    _locationTimer?.cancel();
    _positionStream?.cancel();
    
    // Save completed ride ID
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('completed_ride_id', completedRideId);
    await prefs.setString('completed_ride_id', completedRideId);
// DO NOT remove rideId here

    
    print("💾 Saved completed ride ID and cleared ongoing ride data");
    
    if (!mounted) {
      print("⚠️ Widget not mounted, cannot show UI");
      return;
    }
    
    // Show completion snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              '🎉 Ride Completed Successfully!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    
    print("✅ Snackbar shown, waiting 2 seconds...");
    
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) {
      print("⚠️ Widget unmounted during delay");
      return;
    }
    
    print("🚀 Navigating to Rating Screen with rideId: $completedRideId");
    
    try {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RatingScreen(rideId: completedRideId),
        ),
      );
      print("✅✅✅ Navigation to RatingScreen SUCCESSFUL ✅✅✅");
    } catch (e) {
      print("❌ Navigation error: $e");
      if (mounted) {
        setState(() {
          _isNavigated = false;
        });
      }
    }
  }

  // ✅ FIX 7: Separate cancellation handler
  Future<void> _handleRideCancellation() async {
    _locationTimer?.cancel();
    _positionStream?.cancel();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('rideId');
    await prefs.remove('current_ride_id');
    await prefs.remove('rideStatus');
    
    if (mounted) {
      setState(() {
        _isNavigated = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.cancel, color: Colors.white),
              SizedBox(width: 12.w),
              Text('Ride was cancelled'),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
      
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pop(context);
    }
  }

  // ✅ FIX 8: Reduce polling frequency to prevent overlaps
  Future<void> _fetchLocationPeriodically() async {
    print("🚀 Starting location + status polling at ${DateTime.now()}...");
    
    await _updateUserLocation();
    await _fetchRidePaymentStatus(_persistentRideId!);   // ← ADD THIS

    // Changed from 1 second to 3 seconds to prevent overlaps
    _locationTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!_isNavigated && mounted) {
        print("⏰ Periodic check at ${DateTime.now()}");
        
        try {
          await _updateUserLocation();
        } catch (e) {
          print("⚠️ Location update failed: $e");
        }
        
        try {
          await _checkRideStatus();
        } catch (e) {
          print("⚠️ Status check failed: $e");
        }
      } else {
        print("⏸️ Polling stopped - _isNavigated: $_isNavigated, mounted: $mounted");
        _locationTimer?.cancel();
      }
    });
  }

  Future<void> _sendSOS() async {
    final contacts = await getEmergencyContacts();
    if (contacts.isEmpty) {
      print("⚠️ No emergency contacts saved");

      // Show user-friendly message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No emergency contacts found. Please add emergency contacts first.',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final location = await _getCurrentLocation();
    if (location == null) {
      print("❌ Could not get current location for SOS");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get your location for SOS message'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final message = Uri.encodeComponent(
      "🚨 SOS! I need help. My current location is: "
      "https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}",
    );

    bool anySent = false;
    for (Map<String, String> contact in contacts) {
      final number = contact['number']!;
      final name = contact['name']!;

      try {
        final uri = Uri.parse("sms:$number?body=$message");
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          anySent = true;
          print("📱 SOS message sent to $name ($number)");
        }
      } catch (e) {
        print("❌ Failed to send SOS to $name: $e");
      }
    }

    if (mounted) {
      if (anySent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'SOS messages sent to ${contacts.length} emergency contact(s)',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send SOS messages. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<LatLng?> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      print("❌ Error getting location: $e");
      return null;
    }
  }

  Future<void> _initRide() async {
    final prefs = await SharedPreferences.getInstance();
    String? rideId = prefs.getString('rideId');

    if (rideId == null) {
      print("⚠️ No ongoing ride found — closing screen");
      if (mounted) Navigator.pop(context);
      return;
    }

    // ✅ Get ride details from backend
    final rideDetails = await Authservices.getRideDetail(
      rideId,
    ); // Updated method name
    print("📬 Ride details response: $rideDetails");

    if (rideDetails == null) {
      print("⚠️ Ride not found on server, clearing rideId");
      await prefs.remove('rideId');
      if (mounted) Navigator.pop(context);
      return;
    }

    // ✅ Parse ride data from Ride object
    await _parseRideDataFromRideObject(rideDetails);

    final rideStatus = rideDetails.status.toLowerCase() ?? "";
    if (rideStatus == "completed" || rideStatus == "cancelled") {
      print("⚠️ Ride is already $rideStatus, clearing rideId");
      await prefs.remove('rideId');
      if (mounted) Navigator.pop(context);
      return;
    }

    // ✅ Ride is valid & ongoing — start location updates
    _fetchLocationPeriodically();
    _startLiveLocationUpdates();
  }

  Future<void> _parseRideDataFromRideObject(dynamic rideObj) async {
    try {
      print("🔍 Ride object type: ${rideObj.runtimeType}");
      List<Stop> allStops = rideObj.stops ?? [];

      print("🔍 Total stops in ride: ${allStops.length}");

      // --- Dropoff location ---
      final dropoffStop =
          rideObj.dropoffStop ?? (allStops.isNotEmpty ? allStops.last : null);

      if (dropoffStop != null) {
        _dropLocation = LatLng(
          dropoffStop.lat.toDouble(),
          dropoffStop.lng.toDouble(),
        );
        print(
          "🎯 Parsed drop location: $_dropLocation (${dropoffStop.address})",
        );
      }

      // --- Intermediate stops ---
      if (allStops.length > 2) {
        // Ignore first (pickup) and last (dropoff)
        List<Stop> intermediateStops = allStops.sublist(1, allStops.length - 1);

        _stops =
            intermediateStops
                .map((stop) => LatLng(stop.lat.toDouble(), stop.lng.toDouble()))
                .toList();

        _rideType = "multiple_stops";
        _currentStopIndex = 0;
        _currentDestination = _stops[0];

        print("🎯 Found ${_stops.length} intermediate stops:");
        for (int i = 0; i < intermediateStops.length; i++) {
          print("   Stop ${i + 1}: ${intermediateStops[i].address}");
        }
      } else {
        _rideType = "regular";
        _currentDestination = _dropLocation;
        print("🎯 No intermediate stops found, treating as regular ride");
      }

      print("🎯 Ride type: $_rideType");
      print("🎯 Drop location: $_dropLocation");
      print("🎯 Intermediate stops: ${_stops.length}");
      print("🎯 Current destination: $_currentDestination");

      // --- Ride flow info ---
      if (_rideType == "multiple_stops") {
        print("🛣️ Ride Flow: User → Intermediate Stops → Final Drop");
        for (int i = 0; i < _stops.length; i++) {
          print("   Stop ${i + 1}: ${_stops[i]}");
        }
        print("   Final Drop: $_dropLocation");
      } else {
        print("🛣️ Ride Flow: User → Drop ($_dropLocation)");
      }
    } catch (e) {
      print("❌ Error parsing ride data: $e");
      print("❌ Error type: ${e.runtimeType}");

      // Fallback: use last stop if available
      if (rideObj.stops != null && rideObj.stops.isNotEmpty) {
        final lastStop = rideObj.stops.last;
        _dropLocation = LatLng(
          lastStop.lat.toDouble(),
          lastStop.lng.toDouble(),
        );
        _currentDestination = _dropLocation;
        _rideType = "regular";
        print("🔄 Fallback: Set destination to last stop");
      }
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  void _startLiveLocationUpdates() {
    if (_currentDestination == null) {
      print("⚠️ No destination set, cannot start location updates");
      return;
    }

    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // update every 10 meters
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) async {
      LatLng newLocation = LatLng(position.latitude, position.longitude);

      List<LatLng> newRoute = await _getRouteCoordinates(
        newLocation,
        _currentDestination!,
      );

      setState(() {
        _userLocation = newLocation;
        _updateMarkersAndRoute(newRoute);
      });

      // Check if reached current destination
      await _checkDestinationReached(newLocation);

      // Optional: move camera to follow user
      _controller?.animateCamera(CameraUpdate.newLatLng(_userLocation!));
    });
  }

  Future<void> _checkDestinationReached(LatLng userLocation) async {
    if (_currentDestination == null) return;

    double distanceToDestination = Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      _currentDestination!.latitude,
      _currentDestination!.longitude,
    );

    // If within 50 meters of destination
    if (distanceToDestination <= 50) {
      if (_rideType == "multiple_stops") {
        // Check if this was a stop
        if (_currentStopIndex < _stops.length) {
          print("🎯 Reached stop ${_currentStopIndex + 1}");
          _currentStopIndex++;

          // Move to next stop or final destination
          if (_currentStopIndex < _stops.length) {
            _currentDestination = _stops[_currentStopIndex];
            print("🎯 Moving to next stop: $_currentDestination");
          } else {
            // All stops completed, move to drop location
            _currentDestination = _dropLocation;
            print("🎯 All stops completed, moving to drop location");
          }

          // Update route to new destination
          if (_userLocation != null && _currentDestination != null) {
            List<LatLng> newRoute = await _getRouteCoordinates(
              _userLocation!,
              _currentDestination!,
            );
            setState(() {
              _updateMarkersAndRoute(newRoute);
            });
          }
        }
      }
      // If reached final drop location, ride will be completed by backend status check
    }
  }

  void _updateMarkersAndRoute(List<LatLng> route) {
    _markers.clear();

    // User location marker
    if (_userLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId("user"),
          position: _userLocation!,
          infoWindow: const InfoWindow(title: "You"),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    // Add stop markers
    for (int i = 0; i < _stops.length; i++) {
      _markers.add(
        Marker(
          markerId: MarkerId("stop_$i"),
          position: _stops[i],
          infoWindow: InfoWindow(title: "Stop ${i + 1}"),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            i < _currentStopIndex
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueBlue,
          ),
        ),
      );
    }

    // Drop location marker
    if (_dropLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId("drop"),
          position: _dropLocation!,
          infoWindow: const InfoWindow(title: "Drop Point"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    // Update polyline
    _polylineCoordinates = route;
    _polylines.clear();
    _polylines.add(
      Polyline(
        polylineId: const PolylineId("route"),
        points: _polylineCoordinates,
        color: Colors.blue,
        width: 4.w.toInt(),
      ),
    );
  }

  
  Future<void> _updateUserLocation() async {
    if (_currentDestination == null) {
      print("⚠️ No current destination set");
      return;
    }

    try {
      print("📍 Requesting location permission...");
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print("⚠️ Location permission denied");
        return;
      }

      print("📍 Getting current position...");
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      LatLng newLocation = LatLng(position.latitude, position.longitude);
      print(
        "📍 Current location: ${newLocation.latitude}, ${newLocation.longitude}",
      );

      print("🗺️ Fetching route from current to destination...");
      List<LatLng> newRoute = await _getRouteCoordinates(
        newLocation,
        _currentDestination!,
      );

      setState(() {
        _userLocation = newLocation;
        _updateMarkersAndRoute(newRoute);
      });

      // Check if reached destination
      await _checkDestinationReached(newLocation);

      // Update camera bounds
      if (_controller != null &&
          _userLocation != null &&
          _currentDestination != null) {
        _controller!.animateCamera(
          CameraUpdate.newLatLngBounds(
            _calculateBounds(
              [_userLocation!, _currentDestination!] +
                  _stops +
                  (_dropLocation != null ? [_dropLocation!] : []),
            ),
            100,
          ),
        );
      }
    } catch (e) {
      print("❌ Error while updating location: $e");
    }
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (LatLng point in points) {
      minLat = min(minLat, point.latitude);
      maxLat = max(maxLat, point.latitude);
      minLng = min(minLng, point.longitude);
      maxLng = max(maxLng, point.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<List<LatLng>> _getRouteCoordinates(
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      const String googleAPIKey = "AIzaSyBQx7m5RcWfgRtYZzvwxRLcMa3Ks-Z0xUI";
      final String url =
          "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$googleAPIKey";

      final response = await http.get(Uri.parse(url));
      print("📡 Directions API status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'].isEmpty) {
          print("⚠️ No routes found");
          return [];
        }
        final encodedPoints = data['routes'][0]['overview_polyline']['points'];
        return _decodePolyline(encodedPoints);
      } else {
        print("❌ Failed to load directions");
        return [];
      }
    } catch (e) {
      print("❌ Error fetching directions: $e");
      return [];
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      poly.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return poly;
  }

  

// Replace your existing _checkRideStatus() method with this one
Future<void> _checkRideStatus() async {
    // Prevent multiple simultaneous checks
    if (_isChecking) {
      print("⏳ Status check already in progress, skipping...");
      return;
    }
    
    if (_isNavigated || !mounted) {
      print("⚠️ Already navigated or widget not mounted");
      return;
    }

    _isChecking = true;
    
    try {
      // ✅ FIX 5: Use multiple sources with priority order
      String? rideId = _persistentRideId; // Primary source
      
      if (rideId == null || rideId.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        rideId = prefs.getString('rideId') 
              ?? prefs.getString('current_ride_id') 
              ?? widget.rideId;
      }
      
      if (rideId.isEmpty) {
        print("❌ No rideId available from any source");
        print("   - _persistentRideId: $_persistentRideId");
        print("   - widget.rideId: ${widget.rideId}");
        return;
      }
      
      print("🔍 Checking ride status for ID: $rideId at ${DateTime.now()}");

      // Get ride status with timeout
      Map<String, dynamic>? status;
      
      try {
        status = await Authservices.getRideStatus(rideId).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print("⏰ Status check timed out");
            return null;
          },
        );
      } catch (e) {
        print("⚠️ getRideStatus failed: $e");
        return;
      }
      
      if (status == null) {
        print("⚠️ No status data received");
        return;
      }

      print("📊 Status data received: $status");

      final rideStatus = (status["status"]?.toString() ?? "").toLowerCase().trim();
      final paymentStatus = (status["paymentStatus"]?.toString() ?? "").toLowerCase().trim();
      
      print("📊 Normalized - Status: '$rideStatus', Payment: '$paymentStatus'");

      // ✅ CHECK FOR COMPLETED
      if (rideStatus == "completed" || rideStatus == "complete") {
        print("✅✅✅ RIDE IS COMPLETED ✅✅✅");
        await _handleRideCompletion(rideId);
      } else if (rideStatus == "cancelled") {
        print("⚠️ Ride cancelled");
        await _handleRideCancellation();
      } else {
        print("ℹ️ Ride ongoing - Status: '$rideStatus', Payment: '$paymentStatus'");
        // Re-store rideId to ensure it persists
        await _storeRideId(rideId);
      }
      
    } catch (e, stackTrace) {
      print("❌ Error in _checkRideStatus: $e");
      print("StackTrace: $stackTrace");
    } finally {
      _isChecking = false;
    }
  }
// Also add this method to manually trigger status check (for testing)
Future<void> _forceStatusCheck() async {
  print("🔄 Manual status check triggered");
  await _checkRideStatus();
}


  String _getCurrentDestinationText() {
    if (_rideType == "multiple_stops") {
      if (_currentStopIndex < _stops.length) {
        return "Going to Stop ${_currentStopIndex + 1} of ${_stops.length}";
      } else {
        return "Going to Final Drop Point";
      }
    }
    return "Going to Destination";
  }

  String _getRideProgressText() {
    if (_rideType == "multiple_stops") {
      int totalStops = _stops.length;
      if (_currentStopIndex < totalStops) {
        return "${_currentStopIndex + 1}/$totalStops stops remaining";
      } else {
        return "All stops completed • Final destination";
      }
    }
    return "Direct ride to destination";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body:
          _userLocation == null || _currentDestination == null
              ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade50,
                      Colors.white,
                      Colors.blue.shade50,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 24.w),
                      Text(
                        'Loading your ride details...',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : Stack(
                children: [
                  // Google Maps
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _userLocation!,
                      zoom: 14,
                    ),
                    onMapCreated: (controller) {
                      _controller = controller;
                    },
                    markers: _markers,
                    polylines: _polylines,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false, // We'll create a custom one
                    zoomControlsEnabled: false,
                    compassEnabled: false,
                    mapToolbarEnabled: false,
                    style: _mapStyle, // Add custom map style
                  ),

                  // Top Info Card
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 16.w,
                    right: 16.w,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Icon(
                                    Icons.directions_car,
                                    color: Colors.green.shade600,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Your Ride is Active",
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        "Stay safe and enjoy your journey",
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 16.w),

                            // Progress indicator
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 8.w,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.blue.shade600,
                                    size: 16,
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      _getCurrentDestinationText(),
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 8.w),

                            // Sub info
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  color: Colors.grey.shade500,
                                  size: 14,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  _getRideProgressText(),
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom Action Sheet
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(25.r),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: 0,
                            left: 20.w,
                            right: 20.w,
                            bottom: 10.w,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Handle bar
                              Container(
                                width: 40.w,
                                height: 4.w,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(2.r),
                                ),
                              ),

                              SizedBox(height: 20.w),
                              // Replace the existing paid status section with this enhanced version

SizedBox(
  height: 56.w,
  width: double.infinity,
  child: _isPaid
      ? Container(
          height: 56.w,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.shade600,
                Colors.green.shade400,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Animated shine effect
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(seconds: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              // Main content
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Payment Completed",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                        Text(
                          "Ride payment confirmed",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
      : Container(
          height: 56.w,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.shade600,
                Colors.green.shade400,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20.r),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                String? rideId = prefs.getString('rideId');
                String? userToken = await Authservices.getToken();

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PaymentScreen(
      rideId: rideId ?? "",
      userToken: userToken ?? "",
    ),
  ),
).then((result) async {
  if (result == true) {
    // Payment successful, refresh payment status
    await _fetchRidePaymentStatus(widget.rideId);
    
    // Show success snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '✅ Payment Successful!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                  Text(
                    'Ride is ongoing...',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ],
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
});
              },
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.payment,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pay Now",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                        Text(
                          "Tap to complete payment",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withOpacity(0.8),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
),
                              SizedBox(height: 20.w),
                              // Action buttons
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  // SOS Button
                                  Expanded(
                                    child: SizedBox(
                                      height: 56.w,
                                      child: ElevatedButton.icon(
                                        onPressed: _sendSOS,
                                        icon: Icon(Icons.sos, size: 22),
                                        label: Text(
                                          'SOS',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red.shade600,
                                          foregroundColor: Colors.white,
                                          elevation: 3,
                                          shadowColor: Colors.red.withOpacity(
                                            0.3,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(width: 12.w),

                                  // Report Button
                                  Expanded(
                                    child: SizedBox(
                                      height: 56.w,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          final prefs =
                                              await SharedPreferences.getInstance();
                                          String? rideId = prefs.getString(
                                            'rideId',
                                          );

                                          if (rideId != null) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) => ComplainScreen(
                                                      rideId: rideId,
                                                    ),
                                              ),
                                            );
                                          } else {
                                            print(
                                              "⚠️ Ride ID not found in SharedPreferences",
                                            );
                                          }
                                        },
                                        icon: Icon(
                                          Icons.report_problem,
                                          size: 22,
                                        ),
                                        label: Text(
                                          'Report',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.orange.shade600,
                                          foregroundColor: Colors.white,
                                          elevation: 3,
                                          shadowColor: Colors.orange
                                              .withOpacity(0.3),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 16.w),

                              // Secondary actions
                              Row(
  children: [
    // Cancel Ride Button
    Expanded(
      child: SizedBox(
        height: 56.w,
        child: ElevatedButton.icon(
          onPressed: _cancelRide,
          icon: Icon(Icons.cancel_outlined, size: 22),
          label: Text(
            'Cancel Ride',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            elevation: 3,
            shadowColor: Colors.red.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
        ),
      ),
    ),
  ],
),

SizedBox(height: 12.w),

// Other secondary actions in a row
Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    _buildSecondaryAction(
      icon: Icons.my_location,
      label: 'Center Map',
      onTap: () {
        if (_controller != null && _userLocation != null) {
          _controller!.animateCamera(
            CameraUpdate.newLatLngZoom(_userLocation!, 16),
          );
        }
      },
    ),
    _buildSecondaryAction(
      icon: Icons.route,
      label: 'View Route',
      onTap: () {
        if (_controller != null &&
            _userLocation != null &&
            _currentDestination != null) {
          _controller!.animateCamera(
            CameraUpdate.newLatLngBounds(
              _calculateBounds([
                _userLocation!,
                _currentDestination!,
              ] + _stops + (_dropLocation != null ? [_dropLocation!] : [])),
              100,
            ),
          );
        }
      },
    ),
    _buildSecondaryAction(
      icon: Icons.info_outline,
      label: 'Trip Info',
      onTap: () => _showTripInfo(),
    ),
  ],
),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Floating recenter button
                  Positioned(
                    right: 16.w,
                    bottom: 200.w,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade600,
                      elevation: 4,
                      onPressed: () {
                        if (_controller != null && _userLocation != null) {
                          _controller!.animateCamera(
                            CameraUpdate.newLatLng(_userLocation!),
                          );
                        }
                      },
                      child: Icon(Icons.gps_fixed),
                    ),
                  ),
                ],
              ),
    );
  }

  // Helper method for secondary actions
  Widget _buildSecondaryAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.w),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey.shade700, size: 20),
            SizedBox(height: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to show trip information
  void _showTripInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade600),
                      SizedBox(width: 12.w),
                      Text(
                        'Trip Information',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.w),
                  _buildInfoRow(
                    'Trip Type',
                    _rideType == "multiple_stops" ? "Multiple Stops" : "Direct",
                  ),
                  _buildInfoRow(
                    'Current Destination',
                    _getCurrentDestinationText(),
                  ),
                  _buildInfoRow('Progress', _getRideProgressText()),
                  if (_stops.isNotEmpty)
                    _buildInfoRow('Total Stops', '${_stops.length} stops'),
                  SizedBox(height: 20.w),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Add this at the top of your class as a constant
  static const String _mapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#bdbdbd"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e5e5e5"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#ffffff"
      }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#dadada"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "transit.line",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e5e5e5"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#c9c9c9"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  }
]
''';
}
