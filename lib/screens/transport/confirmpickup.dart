import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rideal/screens/transport/confirmed.dart';
import 'package:rideal/authservices.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class Confirm extends StatefulWidget {
  final String pickupLocation;
  final String dropoffLocation;
  final String rideType;
  final String originalRideType;
  final double pickupLat;
  final double pickupLng;
  final double dropLat;
  final double dropLng;
  final String? promoCode;
  final bool autoBook;

  const Confirm({
    super.key,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.rideType,
    required this.originalRideType,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropLat,
    required this.dropLng,
    this.promoCode,
    this.autoBook = false,
  });

  @override
  State<Confirm> createState() => _ConfirmState();
}

class _ConfirmState extends State<Confirm> with TickerProviderStateMixin {
  final bool _navigated = false;
  Timer? _timeoutTimer;
  String? rideId;
  String? rideStatus;
  Timer? _timer;
  GoogleMapController? _controller;
  LatLng? _currentPosition;
  Timer? _pollingTimer;
  bool _isBooking = true;
  String _statusMessage = "Booking your ride...";
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // 🚀 Optimization: Delay heavy map and network work to allow 
    // the push transition animation to complete smoothly.
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _getUserLocation();
        _loadRide();
      }
    });
  }

  void _initializeAnimations() {
    // Pulse animation for searching state
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

    // Slide animation for status card
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

    // Fade animation for content changes
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeController);

    // Start animations
    _slideController.forward();
    _fadeController.forward();
    _pulseController.repeat(reverse: true);
  }

  Future<void> _loadRide() async {
    final prefs = await SharedPreferences.getInstance();
    rideId = prefs.getString("rideId");
    rideStatus = prefs.getString("rideStatus");

    if (rideId == null && widget.autoBook) {
      // 🚀 Perform optimistic booking
      try {
        final result = await Authservices.bookRide(
          pickupLocation: widget.pickupLocation,
          dropoffLocation: widget.dropoffLocation,
          rideType: widget.originalRideType,
          pickupLat: widget.pickupLat,
          pickupLng: widget.pickupLng,
          dropLat: widget.dropLat,
          dropLng: widget.dropLng,
          promoCode: widget.promoCode,
        );

        if (result != null) {
          if (result.containsKey('error')) {
             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error']), backgroundColor: Colors.red));
               Navigator.pop(context); // Go back if error
             }
             return;
          }
          
          final newRideId = result['rideId'] ?? result['id'];
          if (newRideId != null) {
            // ✅ Save detailed booking data for persistence
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('current_ride_id', newRideId.toString());
            await prefs.setString('rideId', newRideId.toString());
            await prefs.setString('last_pickup_lat', widget.pickupLat.toString());
            await prefs.setString('last_pickup_lng', widget.pickupLng.toString());
            await prefs.setString('last_drop_lat', widget.dropLat.toString());
            await prefs.setString('last_drop_lng', widget.dropLng.toString());
            await prefs.setString('last_pickup_address', widget.pickupLocation);
            await prefs.setString('last_drop_address', widget.dropoffLocation);

            setState(() {
              rideId = newRideId.toString();
              _isBooking = true;
              _statusMessage = "Searching for a driver...";
            });
            _startPolling();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to book ride")));
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
          Navigator.pop(context);
        }
      }
    } else if (rideId != null) {
      _startPolling();
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkRideStatus();
    });
    _checkRideStatus(); // Initial check
  }

  Future<void> _cancelRide() async {
  final bool? shouldCancel = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.cancel_outlined,
              color: Colors.red.shade600,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              'Cancel Ride?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to cancel this ride? This action cannot be undone.',
          style: TextStyle(fontSize: 16),
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
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
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
      setState(() {
        _statusMessage = "Cancelling ride...";
      });

      if (rideId != null) {
        final result = await Authservices.cancelRide(rideId!);
        
        if (result != null) {
          // Clear stored data (already done in cancelRide method)
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('rideId');
          await prefs.remove('current_ride_id');
          await prefs.remove('rideStatus');
          await prefs.remove('ongoingRideIds');
          
          // Stop timers
          _pollingTimer?.cancel();
          _timeoutTimer?.cancel();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Ride cancelled successfully'),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          
          // Navigate back
          Navigator.pop(context);
        } else {
          throw Exception('Failed to cancel ride');
        }
      }
    } catch (e) {
      print("❌ Error cancelling ride: $e");
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Text('Failed to cancel ride. Please try again.'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      
      setState(() {
        _statusMessage = "Searching for a driver...";
      });
    }
  }
}

  Future<void> _checkRideStatus() async {
    if (_navigated) return;
    
    try {
      final result = await Authservices.getRideStatus(rideId!);
      if (result != null) {
        await _fadeController.reverse();
        
        setState(() {
          rideStatus = result["status"];
          switch (rideStatus) {
            case 'pending':
              _statusMessage = "Searching for a driver...";
              _isBooking = true;
              break;
            case "accepted":
              _statusMessage = "Driver accepted your ride!";
              _isBooking = false;
              _pulseController.stop();
              break;
            case "cancelled":
              _statusMessage = "Ride cancelled";
              _isBooking = false;
              _pulseController.stop();
              break;
            default:
              _statusMessage = "Booking your ride...";
              _isBooking = true;
          }
        });

        await _fadeController.forward();

        if (rideStatus == "accepted") {
          _timer?.cancel();
          // Add a small delay for better UX
          await Future.delayed(const Duration(seconds: 1));
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => Confirmed(
                rideType: widget.rideType.toLowerCase(),
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        }
      }
    } catch (e) {
      print("❌ Error checking ride status: $e");
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _timeoutTimer?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    if (_controller != null) {
      _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 15),
      );
    }
  }

  Widget _buildLocationCard({
    required String title,
    required String location,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    IconData statusIcon;
    Color statusColor;

    switch (rideStatus) {
      case 'pending':
        statusIcon = Icons.search;
        statusColor = Colors.blue;
        break;
      case 'accepted':
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusIcon = Icons.cancel;
        statusColor = Colors.red;
        break;
      default:
        statusIcon = Icons.hourglass_empty;
        statusColor = Colors.orange;
    }

    return AnimatedBuilder(
      animation: _isBooking && rideStatus == 'pending' ? _pulseAnimation : 
                 const AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        return Transform.scale(
          scale: _isBooking && rideStatus == 'pending' ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 24,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map with gradient overlay
          _currentPosition == null
              ? Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.1),
                        Colors.white,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : RepaintBoundary(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition!,
                      zoom: 14,
                    ),
                    onMapCreated: (controller) {
                      _controller = controller;
                      _controller!.animateCamera(
                        CameraUpdate.newLatLngZoom(_currentPosition!, 15),
                      );
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    markers: {
                      Marker(
                        markerId: const MarkerId("pickup"),
                        position: LatLng(widget.pickupLat, widget.pickupLng),
                        infoWindow: InfoWindow(
                          title: "Pickup",
                          snippet: widget.pickupLocation,
                        ),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueGreen,
                        ),
                      ),
                      Marker(
                        markerId: const MarkerId("drop"),
                        position: LatLng(widget.dropLat, widget.dropLng),
                        infoWindow: InfoWindow(
                          title: "Dropoff",
                          snippet: widget.dropoffLocation,
                        ),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        ),
                      ),
                    },
                  ),
                ),

          // Top app bar
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.rideType.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Location info cards
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 16,
            right: 16,
            child: Column(
              children: [
                _buildLocationCard(
                  title: "PICKUP",
                  location: widget.pickupLocation,
                  icon: Icons.location_on,
                  color: Colors.green,
                ),
                _buildLocationCard(
                  title: "DROPOFF",
                  location: widget.dropoffLocation,
                  icon: Icons.flag,
                  color: Colors.red,
                ),
              ],
            ),
          ),

          // My location button
          Positioned(
            right: 16,
            bottom: 200,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _getUserLocation,
              child: Icon(
                Icons.my_location,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),

          Positioned(
  bottom: 0,
  left: 0,
  right: 0,
  child: SlideTransition(
    position: _slideAnimation,
    child: Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusIndicator(),
              const SizedBox(width: 16),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _statusMessage,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isBooking 
                            ? "We're finding the best driver for you"
                            : "Your ride is confirmed",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          if (_isBooking) ...[
            const SizedBox(height: 20),
            // Progress indicator
            LinearProgressIndicator(
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            // Action buttons row
            Row(
              children: [
                // Cancel button
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _cancelRide,
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.red.shade600,
                      ),
                      label: Text(
                        'Cancel Ride',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.red.shade300,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.red.shade50,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Waiting indicator
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Finding Driver...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Additional info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This usually takes 1-3 minutes. You can cancel anytime.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  ),
),
        ],
      ),
    );
  }
}