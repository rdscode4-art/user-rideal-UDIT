import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rideal/screens/RideStarted/ridestarted.dart';
import 'package:rideal/authservices.dart';
import 'package:rideal/screens/chat/chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class Confirmed extends StatefulWidget {
  final String rideType;
  const Confirmed({super.key, required this.rideType});

  @override
  State<Confirmed> createState() => _ConfirmedState();
}

class _ConfirmedState extends State<Confirmed> with TickerProviderStateMixin {
  GoogleMapController? _controller;
  final Set<Polyline> _polylines = {};
  List<LatLng> _polylineCoordinates = [];
  Map<String, dynamic>? _driverDetails;
  bool _isLoadingDetails = true;
  String? otp;
  String? rideId;
  Timer? _statusTimer;
  Timer? _driverLocationTimer;
  bool _navigated = false;
  LatLng? _currentPosition;
  LatLng? _driverPosition;
  final Set<Marker> _markers = {};
  
  BitmapDescriptor? _driverIcon;
  BitmapDescriptor? _userIcon;
  
  // Smooth Car Animation variables
  late AnimationController _carMovementController;
  late Animation<double> _carMovementAnimation;
  LatLng? _oldDriverPosition;
  double _driverBearing = 0.0;
  double _oldDriverBearing = 0.0;
  
  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  // ETA calculation
  String _estimatedArrival = "Calculating...";
  double? _distanceToDriver;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCustomMarkers();
    _initializeEverything();
  }

  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  Future<void> _loadCustomMarkers() async {
      String assetPath = 'assets/images/top_car.png';
    
    try {
      final Uint8List driverMarker = await _getBytesFromAsset(assetPath, 120);
      if (mounted) {
        setState(() {
          _driverIcon = BitmapDescriptor.fromBytes(driverMarker);
        });
      }
    } catch (e) {
      print("Error loading custom markers: $e");
    }
  }
Future<void> _cancelRide() async {
  // Show confirmation dialog
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
              Icons.warning_amber_rounded,
              color: Colors.orange.shade600,
              size: 28,
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel this ride?',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8.w),
            Text(
              'Your driver is already on the way. Cancelling now may result in cancellation charges.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 12.w),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, 
                       color: Colors.orange.shade600, size: 16),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'This action cannot be undone',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Keep Ride',
              style: TextStyle(
                color: Colors.green.shade600,
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
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
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.w),
            ),
            child: Text(
              'Cancel Ride',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
          ),
        ],
      );
    },
  );

  if (shouldCancel == true) {
    try {
      // Show loading overlay
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16.w),
                  Text('Cancelling ride...'),
                ],
              ),
            ),
          ),
        ),
      );

      if (rideId != null) {
        // Call your API to cancel the ride
        final result = await Authservices.cancelRide(rideId!, "Cancelled directly");
        
        // Close loading dialog
        Navigator.of(context).pop();
        
        if (result != null) {
          // Clear stored data
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('rideId');
          await prefs.remove('rideStatus');
          await prefs.remove('rideOtp');
          
          // Stop all timers
          _statusTimer?.cancel();
          _driverLocationTimer?.cancel();
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12.w),
                  Expanded(child: Text('Ride cancelled successfully')),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              duration: Duration(seconds: 3),
            ),
          );
          
          // Navigate back to home/booking screen
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          throw Exception('Failed to cancel ride');
        }
      }
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      print("❌ Error cancelling ride: $e");
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12.w),
              Expanded(child: Text('Failed to cancel ride. Please try again.')),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
}
  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _carMovementController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _carMovementAnimation = CurvedAnimation(
      parent: _carMovementController,
      curve: Curves.linear,
    );
    _carMovementController.addListener(() {
      if (_oldDriverPosition != null && _driverPosition != null) {
        final double v = _carMovementAnimation.value;
        final lat = (_oldDriverPosition!.latitude * (1 - v)) + (_driverPosition!.latitude * v);
        final lng = (_oldDriverPosition!.longitude * (1 - v)) + (_driverPosition!.longitude * v);
        
        // Smooth rotation tween handling 360 degree wrap-around
        double diff = _driverBearing - _oldDriverBearing;
        if (diff > 180) diff -= 360;
        if (diff < -180) diff += 360;
        double currentBearing = _oldDriverBearing + (diff * v);
        
        if (mounted) {
          setState(() {
            _markers.removeWhere((m) => m.markerId.value == "driver");
            _markers.add(
              Marker(
                markerId: const MarkerId("driver"),
                position: LatLng(lat, lng),
                rotation: currentBearing,
                anchor: const Offset(0.5, 0.5),
                icon: _getCustomMarker('driver'),
                infoWindow: InfoWindow(
                  title: "Driver - ${_driverDetails?["name"] ?? 'Unknown'}",
                  snippet: _driverDetails?["vehicleNumber"]?.toString(),
                ),
              ),
            );
          });
        }
      }
    });

    _slideController.forward();
    _pulseController.repeat(reverse: true);
    _fadeController.forward();
  }

  Future<void> _initializeEverything() async {
    try {
      await Future.wait([
        _getUserLocation(),
        _fetchDriverData(),
        _loadOtp(),
      ]);
      
      // Draw initial polyline after getting both positions
      if (_currentPosition != null && _driverPosition != null) {
        await _drawPolyline();
      }
      
      if (rideId != null && _currentPosition != null) {
        _startSmartDriverTracking(); // Use the smart animated tracker
        _startPollingRideStatus();
      }
    } catch (e) {
      print("❌ Error initializing: $e");
    }
  }

  // Method to get dynamic custom markers
  BitmapDescriptor _getCustomMarker(String type) {
    switch (type.toLowerCase()) {
      case 'user':
        return _userIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'driver':
        return _driverIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  Future<void> _drawPolyline() async {
    print("🚀 Inside _drawPolyline()...");
    if (_currentPosition != null && _driverPosition != null) {
      print("🚀 Calling _getRouteCoordinates...");
      final routeCoordinates = await _getRouteCoordinates(
        _driverPosition!,
        _currentPosition!,
      );

      print("🚀 Received ${routeCoordinates.length} route coordinates");
      if (routeCoordinates.isNotEmpty && mounted) {
        setState(() {
          _polylineCoordinates = routeCoordinates;
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId("driver_to_user"),
              points: _polylineCoordinates,
              color: Theme.of(context).primaryColor,
              width: 5,
              // Removed dash patterns to make it a solid, real line
            ),
          );
        });

        _fitMapToShowBothLocations();
      }
    }
  }

  void _fitMapToShowBothLocations() {
    if (_controller != null && _currentPosition != null && _driverPosition != null) {
      final southwest = LatLng(
        min(_currentPosition!.latitude, _driverPosition!.latitude) - 0.001,
        min(_currentPosition!.longitude, _driverPosition!.longitude) - 0.001,
      );
      final northeast = LatLng(
        max(_currentPosition!.latitude, _driverPosition!.latitude) + 0.001,
        max(_currentPosition!.longitude, _driverPosition!.longitude) + 0.001,
      );

      final bounds = LatLngBounds(
        southwest: southwest,
        northeast: northeast,
      );

      _controller!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );
    }
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final startLat = start.latitude * pi / 180;
    final startLng = start.longitude * pi / 180;
    final endLat = end.latitude * pi / 180;
    final endLng = end.longitude * pi / 180;

    final dLong = endLng - startLng;
    final y = sin(dLong) * cos(endLat);
    final x = cos(startLat) * sin(endLat) - sin(startLat) * cos(endLat) * cos(dLong);
    final bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _driverLocationTimer?.cancel();
    _controller?.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _carMovementController.dispose();
    super.dispose();
  }

  void makePhoneCall(String phoneNumber) async {
    try {
      final Uri launchUri = Uri.parse('tel:$phoneNumber');
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        print('Could not launch $launchUri');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not make phone call')),
          );
        }
      }
    } catch (e) {
      print('Error making phone call: $e');
    }
  }

  String getRideImage(String type) {
    final t = type.toLowerCase();
    if (t.contains('bike') || t.contains('moto')) return 'assets/images/bike.png';
    if (t.contains('auto') || t.contains('rickshaw')) return 'assets/images/auto.png';
    if (t.contains('suv')) return 'assets/images/suv.png';
    if (t.contains('sedan')) return 'assets/images/sedan.png';
    if (t.contains('premium')) return 'assets/images/premium.png';
    if (t.contains('ev')) return 'assets/images/ev.png';
    return 'assets/images/car.png'; // default fallback for car/mini/city
  }

  // Enhanced ETA calculation using Google Directions API for more accurate time estimates

Future<void> _calculateAccurateETA() async {
  if (_driverPosition != null && _currentPosition != null) {
    try {
      const String googleAPIKey = "AIzaSyBQx7m5RcWfgRtYZzvwxRLcMa3Ks-Z0xUI";
      
      // Get real-time traffic data and accurate route
      final String url = "https://maps.googleapis.com/maps/api/directions/json?"
          "origin=${_driverPosition!.latitude},${_driverPosition!.longitude}&"
          "destination=${_currentPosition!.latitude},${_currentPosition!.longitude}&"
          "departure_time=now&"  // For real-time traffic
          "traffic_model=best_guess&"
          "key=$googleAPIKey";

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print("⚠️ Directions API Timeout in ETA calculation!");
          return http.Response('Error', 408); // Return timeout response
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          // Get accurate distance and duration from Google
          final distanceText = leg['distance']['text'];
          final durationText = leg['duration_in_traffic'] != null 
              ? leg['duration_in_traffic']['text']  // With traffic
              : leg['duration']['text'];           // Without traffic
          
          final distanceValue = leg['distance']['value'] / 1000.0; // Convert to km
          final durationValue = leg['duration_in_traffic'] != null
              ? leg['duration_in_traffic']['value'] / 60.0  // Convert to minutes
              : leg['duration']['value'] / 60.0;
          
          if (mounted) {
            setState(() {
              _distanceToDriver = distanceValue;
              _estimatedArrival = durationValue < 1 
                  ? "Less than 1 min"
                  : "${durationValue.round()} min";
            });
          }
        } else {
          // Fallback to basic calculation
          _calculateBasicETA();
        }
      } else {
        // Fallback to basic calculation
        _calculateBasicETA();
      }
    } catch (e) {
      print("❌ Error calculating accurate ETA: $e");
      // Fallback to basic calculation
      _calculateBasicETA();
    }
  }
}

// Fallback method (your current implementation)
void _calculateBasicETA() {
  if (_driverPosition != null && _currentPosition != null) {
    final distance = Geolocator.distanceBetween(
      _driverPosition!.latitude,
      _driverPosition!.longitude,
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );
    
    setState(() {
      _distanceToDriver = distance / 1000;
      
      // Enhanced speed calculation based on time of day and area type
      double averageSpeed = _getAverageSpeedForContext();
      final etaMinutes = (_distanceToDriver! / averageSpeed) * 60;
      
      if (etaMinutes < 1) {
        _estimatedArrival = "Less than 1 min";
      } else if (etaMinutes < 60) {
        _estimatedArrival = "${etaMinutes.round()} min";
      } else {
        _estimatedArrival = "${(etaMinutes / 60).toStringAsFixed(1)} hr";
      }
    });
  }
}

// Smart speed estimation based on context
double _getAverageSpeedForContext() {
  final hour = DateTime.now().hour;
  
  // Rush hour detection (slower speeds)
  if ((hour >= 7 && hour <= 10) || (hour >= 17 && hour <= 20)) {
    return 15.0; // 15 km/h during rush hour
  }
  
  // Late night (faster speeds)
  if (hour >= 22 || hour <= 6) {
    return 45.0; // 45 km/h late night
  }
  
  // Regular hours
  return 30.0; // 30 km/h regular hours
}

// Enhanced tracking with more frequent updates when driver is close
void _startSmartDriverTracking() {
  _driverLocationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
    if (rideId == null || !mounted) return;
    
    try {
      final data = await Authservices.getDriverLocation(rideId!);
      if (data != null && mounted) {
        final lat = data["lat"];
        final lng = data["lng"];
        if (lat != null && lng != null) {
          final newDriverPosition = LatLng(
            (lat as num).toDouble(),
            (lng as num).toDouble(),
          );
          
          // Calculate distance between old and new driver position
          double driverMovement = 0;
          if (_driverPosition != null) {
            driverMovement = Geolocator.distanceBetween(
              _driverPosition!.latitude,
              _driverPosition!.longitude,
              newDriverPosition.latitude,
              newDriverPosition.longitude,
            );
          }
          
          if (_driverPosition != null) {
            _oldDriverPosition = _driverPosition;
            _oldDriverBearing = _driverBearing; // Store old bearing for smooth turning
            
            // Only update bearing if car moved significantly (prevents flipping upside down when stopped due to GPS jitter)
            if (driverMovement > 2) {
              _driverBearing = _calculateBearing(_oldDriverPosition!, newDriverPosition);
            }
            
            _driverPosition = newDriverPosition;
            
            if (driverMovement > 200) {
              // If driver jumped a huge distance, snap instantly
              setState(() {
                _markers.removeWhere((m) => m.markerId.value == "driver");
                _markers.add(
                  Marker(
                    markerId: const MarkerId("driver"),
                    position: _driverPosition!,
                    rotation: _driverBearing,
                    anchor: const Offset(0.5, 0.5),
                    icon: _getCustomMarker('driver'),
                    infoWindow: InfoWindow(
                      title: "Driver - ${_driverDetails?["name"] ?? 'Unknown'}",
                      snippet: _driverDetails?["vehicleNumber"]?.toString(),
                    ),
                  ),
                );
              });
            } else {
              // Set duration based on frequency and animate for normal driving
              _carMovementController.duration = const Duration(milliseconds: 4500); 
              _carMovementController.forward(from: 0.0);
            }
          } else {
            setState(() {
              _driverPosition = newDriverPosition;
              if (_currentPosition != null) {
                // Initialize bearing to point towards the user's pickup location on first load
                _driverBearing = _calculateBearing(_driverPosition!, _currentPosition!);
                _oldDriverBearing = _driverBearing;
              }
              _markers.removeWhere((m) => m.markerId.value == "driver");
              _markers.add(
                Marker(
                  markerId: const MarkerId("driver"),
                  position: _driverPosition!,
                  rotation: _driverBearing,
                  anchor: const Offset(0.5, 0.5),
                  icon: _getCustomMarker('driver'),
                  infoWindow: InfoWindow(
                    title: "Driver - ${_driverDetails?["name"] ?? 'Unknown'}",
                    snippet: _driverDetails?["vehicleNumber"]?.toString(),
                  ),
                ),
              );
            });
          }
          
          // Use accurate ETA calculation or fallback to basic
          await _calculateAccurateETA();
          
          print("🚗 SmartTracking -> Driver Movement: $driverMovement meters");
          
          // Redraw polyline if driver moved even slightly off-route (> 10m)
          // This ensures the route updates dynamically if the driver takes a different road
          if (driverMovement > 10) {
            print("🚀 Redrawing Polyline because movement > 10m!");
            await _drawPolyline();
          }
          
          // Increase update frequency when driver is very close (< 1km)
          if (_distanceToDriver != null && _distanceToDriver! < 1.0) {
            _startHighFrequencyTracking();
          }
        }
      }
    } catch (e) {
      print("❌ Error tracking driver: $e");
    }
  });
}

// High frequency tracking when driver is very close
void _startHighFrequencyTracking() {
  _driverLocationTimer?.cancel();
  
  _driverLocationTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
    if (rideId == null || !mounted) return;
    
    try {
      final data = await Authservices.getDriverLocation(rideId!);
      if (data != null && mounted) {
        final lat = data["lat"];
        final lng = data["lng"];
        if (lat != null && lng != null) {
          final newDriverPosition = LatLng(
            (lat as num).toDouble(),
            (lng as num).toDouble(),
          );
          
          double driverMovement = 0;
          if (_driverPosition != null) {
            driverMovement = Geolocator.distanceBetween(
              _driverPosition!.latitude,
              _driverPosition!.longitude,
              newDriverPosition.latitude,
              newDriverPosition.longitude,
            );
          }
          
          if (_driverPosition != null) {
            _oldDriverPosition = _driverPosition;
            _oldDriverBearing = _driverBearing;
            _driverBearing = _calculateBearing(_oldDriverPosition!, newDriverPosition);
            _driverPosition = newDriverPosition;
            
            if (driverMovement > 200) {
              // Snap instantly if teleported
              setState(() {
                _markers.removeWhere((m) => m.markerId.value == "driver");
                _markers.add(
                  Marker(
                    markerId: const MarkerId("driver"),
                    position: _driverPosition!,
                    rotation: _driverBearing,
                    anchor: const Offset(0.5, 0.5),
                    icon: _getCustomMarker('driver'),
                    infoWindow: InfoWindow(
                      title: "Driver - ${_driverDetails?["name"] ?? 'Unknown'}",
                      snippet: _driverDetails?["vehicleNumber"]?.toString(),
                    ),
                  ),
                );
              });
            } else {
              _carMovementController.duration = const Duration(milliseconds: 1800); 
              _carMovementController.forward(from: 0.0);
            }
          }
          
          print("🏎️ HighFreqTracking -> Driver Movement: $driverMovement meters");
          if (driverMovement > 10) {
            print("🚀 HighFreqTracking: Redrawing Polyline because movement > 10m!");
            await _drawPolyline();
          }
        }
      }
    } catch (e) {
      print("❌ Error in high freq tracking: $e");
    }
  });
}

// Enhanced ETA display with more detailed information
Widget _buildEnhancedETACard() {
  return Container(
    margin: EdgeInsets.all(16.w),
    padding: EdgeInsets.all(20.w),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Theme.of(context).primaryColor.withOpacity(0.1),
          Theme.of(context).primaryColor.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20.r),
      border: Border.all(
        color: Theme.of(context).primaryColor.withOpacity(0.2),
        width: 1.w,
      ),
    ),
    child: Column(
      children: [
        Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.access_time,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                );
              },
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Driver arriving in",
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.w),
                  Text(
                    _estimatedArrival,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        if (_distanceToDriver != null) ...[
          SizedBox(height: 16.w),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.straighten,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      "${_distanceToDriver!.toStringAsFixed(1)} km away",
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                
                // Traffic indicator
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.w),
                  decoration: BoxDecoration(
                    color: _getTrafficColor(),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.traffic,
                        size: 12,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        _getTrafficText(),
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

// Helper methods for traffic indication
Color _getTrafficColor() {
  final hour = DateTime.now().hour;
  if ((hour >= 7 && hour <= 10) || (hour >= 17 && hour <= 20)) {
    return Colors.red; // Heavy traffic
  } else if ((hour >= 11 && hour <= 16) || (hour >= 21 && hour <= 23)) {
    return Colors.orange; // Moderate traffic
  }
  return Colors.green; // Light traffic
}

String _getTrafficText() {
  final hour = DateTime.now().hour;
  if ((hour >= 7 && hour <= 10) || (hour >= 17 && hour <= 20)) {
    return "Heavy";
  } else if ((hour >= 11 && hour <= 16) || (hour >= 21 && hour <= 23)) {
    return "Moderate";
  }
  return "Light";
}

  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print("Location permission denied");
        return;
      }

      // Try getting last known position first for quick load
      Position? lastPosition = await Geolocator.getLastKnownPosition();

      if (lastPosition != null && mounted) {
        setState(() {
          _currentPosition = LatLng(lastPosition.latitude, lastPosition.longitude);
        });
      }

      // Then fetch current position with a timeout
      Position? currentPosition;
      try {
        currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e) {
        currentPosition = lastPosition;
      }

      if (currentPosition != null && mounted) {
        setState(() {
          _currentPosition = LatLng(currentPosition!.latitude, currentPosition.longitude);
          _markers.removeWhere((m) => m.markerId.value == "user");
          _markers.add(
            Marker(
              markerId: const MarkerId("user"),
              position: _currentPosition!,
              infoWindow: const InfoWindow(title: "Your Location"),
              icon: _getCustomMarker('user'),
            ),
          );
        });
      } else if (mounted) {
        // Ultimate fallback to prevent infinite loading spinner
        setState(() {
          _currentPosition = const LatLng(28.570317, 77.3218196); // Noida Default
        });
      }
    } catch (e) {
      print("Error fetching location: $e");
    }
  }

  Future<void> _fetchDriverData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      rideId = prefs.getString("rideId");

      if (rideId != null) {
        final data = await Authservices.getDriverLocation(rideId!);
        if (mounted && data != null) {
          final driverLat = data["lat"];
          final driverLng = data["lng"];

          if (driverLat != null && driverLng != null) {
            setState(() {
              _driverDetails = data;
              _driverPosition = LatLng(
                (driverLat as num).toDouble(),
                (driverLng as num).toDouble(),
              );
              _isLoadingDetails = false;
              _markers.add(
                Marker(
                  markerId: const MarkerId("driver"),
                  position: _driverPosition!,
                  rotation: _driverBearing,
                  anchor: const Offset(0.5, 0.5),
                  icon: _getCustomMarker('driver'),
                  infoWindow: InfoWindow(
                    title: "Driver - ${_driverDetails?["name"] ?? 'Unknown'}",
                    snippet: _driverDetails?["vehicleNumber"]?.toString(),
                  ),
                ),
              );
            });
            _calculateAccurateETA();
          } else {
            setState(() {
              _driverDetails = data;
              _isLoadingDetails = false;
            });
          }
        } else {
          setState(() {
            _isLoadingDetails = false;
          });
        }
      } else {
        setState(() {
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      print("❌ Error fetching driver data: $e");
      if (mounted) {
        setState(() {
          _driverDetails = {};
          _isLoadingDetails = false;
        });
      }
    }
  }

  Future<List<LatLng>> _getRouteCoordinates(
    LatLng driverLocation,
    LatLng userLocation,
  ) async {
    try {
      const String googleAPIKey = "AIzaSyBQx7m5RcWfgRtYZzvwxRLcMa3Ks-Z0xUI";
      
      final double distanceInMeters = Geolocator.distanceBetween(
        driverLocation.latitude,
        driverLocation.longitude,
        userLocation.latitude,
        userLocation.longitude,
      );

      if (distanceInMeters > 50000) {
        return [driverLocation, userLocation];
      }

      final String url =
          "https://maps.googleapis.com/maps/api/directions/json?origin=${driverLocation.latitude},${driverLocation.longitude}&destination=${userLocation.latitude},${userLocation.longitude}&key=$googleAPIKey";

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print("⚠️ Directions API Timeout in getRouteCoordinates!");
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final encodedPoints = data['routes'][0]['overview_polyline']['points'];
          return _decodePolyline(encodedPoints);
        } else {
          print("No routes found, using direct line");
          return [driverLocation, userLocation];
        }
      } else {
        print("Direction API failed with status: ${response.statusCode}");
        return [driverLocation, userLocation];
      }
    } catch (e) {
      print("❌ Error getting route coordinates: $e");
      return [driverLocation, userLocation];
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
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return poly;
  }

  void _startTrackingDriver() {
    _driverLocationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (rideId == null || !mounted) return;

      try {
        final data = await Authservices.getDriverLocation(rideId!);
        if (data != null && mounted) {
          final lat = data["lat"];
          final lng = data["lng"];

          if (lat != null && lng != null) {
            final driverLat = (lat as num).toDouble();
            final driverLng = (lng as num).toDouble();

            setState(() {
              _driverPosition = LatLng(driverLat, driverLng);
              _markers.removeWhere((m) => m.markerId.value == "driver");
              _markers.add(
                Marker(
                  markerId: const MarkerId("driver"),
                  position: _driverPosition!,
                  icon: _getCustomMarker('driver'),
                  infoWindow: InfoWindow(
                    title: "Driver - ${_driverDetails?["name"] ?? 'Unknown'}",
                    snippet: _driverDetails?["vehicleNumber"]?.toString(),
                  ),
                ),
              );
            });

            _calculateAccurateETA();
            await _drawPolyline(); // Redraw polyline with new driver position
          }
        }
      } catch (e) {
        print("❌ Error tracking driver: $e");
      }
    });
  }

  Future<void> _loadOtp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          otp = prefs.getString('rideOtp') ?? 'N/A';
        });
      }
    } catch (e) {
      print("❌ Error loading OTP: $e");
      if (mounted) {
        setState(() {
          otp = 'N/A';
        });
      }
    }
  }

  Future<void> _startPollingRideStatus() async {
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (rideId == null || !mounted || _navigated) return;

      try {
        final status = await Authservices.getRideStatus(rideId!);
        final rideStatus = status?["status"]?.toString().toLowerCase() ?? "";

        if (rideStatus == "ongoing" && !_navigated) {
          _navigated = true;
          _statusTimer?.cancel();
          _driverLocationTimer?.cancel();

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RideStarted(rideId: "",)),
            );
          }
        } else if ((rideStatus == "cancelled" || rideStatus == "canceled") && !_navigated) {
          _navigated = true;
          _statusTimer?.cancel();
          _driverLocationTimer?.cancel();

          // Clear stored data
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('rideId');
          await prefs.remove('rideStatus');
          await prefs.remove('rideOtp');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white),
                    SizedBox(width: 12.w),
                    const Expanded(child: Text('Ride was cancelled by the driver.')),
                  ],
                ),
                backgroundColor: Colors.orange.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                duration: const Duration(seconds: 4),
              ),
            );
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      } catch (e) {
        print("❌ Error polling ride status: $e");
      }
    });
  }

  Widget _buildETACard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.access_time,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              );
            },
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Driver arriving in",
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.w),
                Text(
                  _estimatedArrival,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (_distanceToDriver != null)
                  Text(
                    "${_distanceToDriver!.toStringAsFixed(1)} km away",
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // ETA and Pickup Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Driver arriving in",
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2.w),
                  Text(
                    _estimatedArrival,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              if (_distanceToDriver != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.w),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    "${_distanceToDriver!.toStringAsFixed(1)} km away",
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.w),
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  "Please meet your driver at the pickup point",
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          Divider(height: 12.w, color: Colors.grey.shade200),
          Row(
            children: [
              // Driver Image/Vehicle
              Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.1),
                      Theme.of(context).primaryColor.withOpacity(0.3),
                    ],
                  ),
                  image: DecorationImage(
                    image: AssetImage(getRideImage(widget.rideType)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              // Driver Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _driverDetails?["name"]?.toString() ?? 'Driver Name',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4.w),
                    Text(
                      _driverDetails?["vehicleNumber"]?.toString() ?? 'Vehicle Number',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: 4.w),
                    Text(
                      _driverDetails?["vehicleName"]?.toString() ?? 'Vehicle Name',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 8.w),
                    // Rating
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.w),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber),
                          SizedBox(width: 4.w),
                          Text(
                            _driverDetails?["rating"] != null
                                ? (double.tryParse(_driverDetails!["rating"].toString())
                                        ?.toStringAsFixed(1) ??
                                    'No Rating')
                                : 'No Rating',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Chat and Call Buttons
              Row(
                children: [
                  // Chat Button
                  Container(
                    margin: EdgeInsets.only(right: 12.w),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        String driverId = _driverDetails?["_id"]?.toString() ?? 
                                          _driverDetails?["id"]?.toString() ?? 
                                          _driverDetails?["driverId"]?.toString() ?? '';
                        String driverName = _driverDetails?["name"]?.toString() ?? 'Driver';
                        
                        print('💬 Chat Button Tapped -> RideId: $rideId, DriverId: $driverId');

                        if (rideId != null && rideId!.isNotEmpty && driverId.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                rideId: rideId!,
                                receiverId: driverId,
                                receiverName: driverName,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Cannot open chat: Missing Driver ID or Ride ID')),
                          );
                        }
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                  // Call Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        String driverPhone = _driverDetails?["phone"]?.toString() ?? '';
                        if (!driverPhone.startsWith('+91')) {
                          driverPhone = '+91$driverPhone';
                        }
                        makePhoneCall(driverPhone);
                      },
                      icon: const Icon(Icons.call, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.w),
          // OTP Section
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.w),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Your OTP",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.w),
                    Text(
                      "Share with your driver",
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.w),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    otp ?? "N/A",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
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

  void _showCancelReasonSheet(BuildContext context) {
    String selectedReason = "Changed my mind";
    final TextEditingController customReasonController = TextEditingController();
    final List<String> reasons = [
      "Driver is too far",
      "Changed my mind",
      "Driver asked to cancel",
      "Other"
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 20.w,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20.w,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 5.w,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.w),
                  Text(
                    "Cancel Ride",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8.w),
                  Text(
                    "Please select a reason for cancelling your ride",
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 20.w),
                  ...reasons.map((reason) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.w),
                      child: GestureDetector(
                        onTap: () {
                          setSheetState(() {
                            selectedReason = reason;
                          });
                        },
                        child: Row(
                          children: [
                            Icon(
                              selectedReason == reason
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: selectedReason == reason
                                  ? Colors.red.shade600
                                  : Colors.grey.shade400,
                              size: 20.w,
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              reason,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: selectedReason == reason
                                    ? Colors.black87
                                    : Colors.grey.shade700,
                                fontWeight: selectedReason == reason
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  Padding(
                    padding: EdgeInsets.only(top: 8.w, bottom: 12.w),
                    child: TextField(
                      controller: customReasonController,
                      decoration: InputDecoration(
                        hintText: "Add custom message... (optional)",
                        hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.w),
                      ),
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ),
                  SizedBox(height: 20.w),
                  SizedBox(
                    width: double.infinity,
                    height: 48.w,
                    child: ElevatedButton(
                      onPressed: () async {
                        String finalReason = selectedReason;
                        if (customReasonController.text.trim().isNotEmpty) {
                          if (selectedReason == "Other") {
                            finalReason = customReasonController.text.trim();
                          } else {
                            finalReason = "$selectedReason - ${customReasonController.text.trim()}";
                          }
                        }
                        
                        if (finalReason.isEmpty || finalReason == "Other") {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please provide a valid reason')),
                          );
                          return;
                        }

                        Navigator.pop(sheetContext);
                        _submitCancelRide(finalReason);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        "Submit & Cancel",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitCancelRide(String reason) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    if (rideId == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final result = await Authservices.cancelRide(rideId!, reason);
    
    if (mounted) Navigator.pop(context);

    if (result != null) {
      // Clear stored data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('rideId');
      await prefs.remove('rideStatus');
      await prefs.remove('rideOtp');
      
      // Stop all timers
      _statusTimer?.cancel();
      _driverLocationTimer?.cancel();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12.w),
                const Expanded(child: Text('Ride cancelled successfully')),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12.w),
                const Expanded(child: Text('Failed to cancel ride. Please try again.')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 60,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back, color: Colors.black87),
            ),
            title: Text(
              "Driver on the way",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 18.sp,
              ),
            ),
            actions: [
              // Cancel button in app bar
              Container(
                margin: EdgeInsets.only(right: 16.w, top: 8.w, bottom: 8.w),
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelReasonSheet(context),
                  icon: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.red.shade600,
                  ),
                  label: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.red.shade400,
                      width: 1.w,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.w),
                    minimumSize: Size.zero,
                    backgroundColor: Colors.red.shade50,
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1.w,
                color: Colors.grey.shade200,
              ),
            ),
          ),
          
          // Map Section
          SliverToBoxAdapter(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.50,
              margin: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: _currentPosition == null
                    ? Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor.withOpacity(0.1),
                              Colors.white,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : GoogleMap(
                        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                          Factory<OneSequenceGestureRecognizer>(
                            () => EagerGestureRecognizer(),
                          ),
                        },
                        initialCameraPosition: CameraPosition(
                          target: _currentPosition!,
                          zoom: 15,
                        ),
                        onMapCreated: (controller) {
                          _controller = controller;
                          // Fit map to show both locations after a short delay
                          Future.delayed(const Duration(milliseconds: 500), () {
                            _fitMapToShowBothLocations();
                          });
                        },
                        myLocationEnabled: false, // Disabled to use custom marker
                        markers: _markers,
                        polylines: _polylines,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        compassEnabled: true,
                        trafficEnabled: false,
                      ),
              ),
            ),
          ),

          // Driver Details Card
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnimation,
              child: _isLoadingDetails
                  ? Container(
                      margin: EdgeInsets.all(16.w),
                      height: 200.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _buildDriverCard(),
            ),
          ),

          // Bottom spacing
          SliverToBoxAdapter(
            child: SizedBox(height: 32.w),
          ),
        ],
      ),
      ),
    );
  }
}