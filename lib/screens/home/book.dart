import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rideal/authservices.dart';
import 'package:rideal/screens/transport/confirmpickup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart' as geo;
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:rideal/model/promocodemodel.dart';
import 'package:rideal/widget/promocode_widget.dart';

// 🚖 Model for ride type with original key preservation
class RideType {
  final String type; // Display name (e.g., "Bike")
  final String originalKey; // Backend key (e.g., "bike")
  final int farePerKm;
  final int avgSpeed;
  final String? imageUrl;
  final int? minFare;
  final int? freeWaitMin;
  final int? waitChargePerMin;
  final int? nightChargePercent;

  RideType({
    required this.type,
    required this.originalKey,
    required this.farePerKm,
    required this.avgSpeed,
    this.imageUrl,
    this.minFare,
    this.freeWaitMin,
    this.waitChargePerMin,
    this.nightChargePercent,
  });

  static int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory RideType.fromJson(
    String key,
    dynamic value,
    Map<String, dynamic>? vehicleImages,
  ) {
    String displayType = key
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');

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
      speed = 30;
    }

    int perKmRate;
    int? minFare;
    int? freeWaitMin;
    int? waitChargePerMin;
    int? nightChargePercent;

    if (value is Map<String, dynamic>) {
      perKmRate = _parseToInt(value['perKmRate']) ?? 0;
      minFare = _parseToInt(value['minFare']);
      freeWaitMin = _parseToInt(value['freeWaitMin']);
      waitChargePerMin = _parseToInt(value['waitChargePerMin']);
      nightChargePercent = _parseToInt(value['nightChargePercent']);
    } else if (value is Map) {
      perKmRate = _parseToInt(value['perKmRate']) ?? 0;
      minFare = _parseToInt(value['minFare']);
      freeWaitMin = _parseToInt(value['freeWaitMin']);
      waitChargePerMin = _parseToInt(value['waitChargePerMin']);
      nightChargePercent = _parseToInt(value['nightChargePercent']);
    } else {
      perKmRate = _parseToInt(value) ?? 0;
    }

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
      originalKey: key, // ⭐ Store original backend key
      farePerKm: perKmRate,
      avgSpeed: speed,
      imageUrl: imageUrl,
      minFare: minFare,
      freeWaitMin: freeWaitMin,
      waitChargePerMin: waitChargePerMin,
      nightChargePercent: nightChargePercent,
    );
  }
}

class Book extends StatefulWidget {
  final String pickupLocation;
  final String dropoffLocation;

  const Book({
    super.key,
    required this.pickupLocation,
    required this.dropoffLocation,
  });

  @override
  State<Book> createState() => _BookState();
}

class _BookState extends State<Book> {
  List<RideType> rideTypes = [];
  int selectedIndex = -1;
  bool isLoading = true;

  double distanceInKm = 0.0;
  double? pickupLat;
  double? pickupLng;
  double? dropLat;
  double? dropLng;

  Timer? _statusRefreshTimer;
  String? _currentRideId;
  String _rideStatus = '';
  bool _isRideBooked = false;
  bool _isBookingInProgress = false; // 🚀 New: track booking request

  PromoCodeDiscount? _appliedPromo;
  String? _appliedPromoCode;

  GoogleMapController? _controller;
  LatLng? currentPosition;
  final loc.Location location = loc.Location();
  bool locationPermissionGranted = false;
  Set<Marker> markers = {};

  final Set<Polyline> _polylines = {};
  List<LatLng> polylineCoordinates = [];
  final polylinePoints = PolylinePoints(
    apiKey: "AIzaSyBQx7m5RcWfgRtYZzvwxRLcMa3Ks-Z0xUI",
  );

  String calculateDropTime(RideType ride) {
    if (distanceInKm == 0) return "—";
    double hours = distanceInKm / ride.avgSpeed;
    int travelMinutes = (hours * 60).round();
    DateTime now = DateTime.now();
    DateTime dropTime = now.add(Duration(minutes: travelMinutes));
    String formatted =
        "${dropTime.hour}:${dropTime.minute.toString().padLeft(2, '0')} ${dropTime.hour >= 12 ? "PM" : "AM"}";
    return formatted;
  }

  double calculateFare(RideType ride, double distanceInKm) {
    if (distanceInKm == 0) return 0;
    double baseFare = ride.farePerKm * distanceInKm;
    if (ride.minFare != null && baseFare < ride.minFare!) {
      baseFare = ride.minFare!.toDouble();
    }
    if (ride.nightChargePercent != null) {
      DateTime now = DateTime.now();
      if (now.hour >= 22 || now.hour < 6) {
        baseFare += baseFare * (ride.nightChargePercent! / 100);
      }
    }
    return baseFare;
  }

  Map<String, String> getRideData(RideType ride) {
    String imagePath;
    if (ride.imageUrl != null && ride.imageUrl!.isNotEmpty) {
      String cleanPath = ride.imageUrl!;
      if (cleanPath.contains('/www/wwwroot/Backendrid')) {
        cleanPath = cleanPath.replaceAll('/www/wwwroot/Backendrid', '');
      }
      if (!cleanPath.startsWith('/')) {
        cleanPath = '/$cleanPath';
      }
      imagePath = 'https://backend.ridealmobility.com$cleanPath';
    } else {
      String lowerType = ride.type.toLowerCase();
      if (lowerType.contains('bike')) {
        imagePath = 'assets/images/bike.png';
      } else if (lowerType.contains('sedan')) {
        imagePath = 'assets/images/taxi.png';
      } else if (lowerType.contains('suv')) {
        imagePath = 'assets/images/suv.png';
      } else if (lowerType.contains('ev')) {
        imagePath = 'assets/images/ev.png';
      } else if (lowerType.contains('auto')) {
        imagePath = 'assets/images/auto.png';
      } else {
        imagePath = 'assets/images/bike.png';
      }
    }
    return {
      'image': imagePath,
      'time': "Approx ${ride.avgSpeed} km/h",
      'drop': calculateDropTime(ride),
    };
  }

  @override
  void initState() {
    super.initState();
    loadRideTypes();
    _convertAddressesToLatLng();
    _requestLocationPermission();
    _calculateDistance();
    _checkForExistingRide();
    _clearRideStateIfCancelled();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      LatLng? pickupLatLng = await _getLatLngFromAddress(widget.pickupLocation);
      LatLng? dropLatLng = await _getLatLngFromAddress(widget.dropoffLocation);
      if (pickupLatLng != null && dropLatLng != null) {
        setState(() {
          pickupLat = pickupLatLng.latitude;
          pickupLng = pickupLatLng.longitude;
          dropLat = dropLatLng.latitude;
          dropLng = dropLatLng.longitude;
          markers.add(
            Marker(
              markerId: const MarkerId("pickup"),
              position: pickupLatLng,
              infoWindow: const InfoWindow(title: "Pickup"),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            ),
          );
          markers.add(
            Marker(
              markerId: const MarkerId("drop"),
              position: dropLatLng,
              infoWindow: const InfoWindow(title: "Drop-off"),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          );
        });
        _getRouteBetweenCoordinates(pickupLatLng, dropLatLng);
        if (_controller != null) {
          _controller!.animateCamera(
            CameraUpdate.newLatLngBounds(
              LatLngBounds(
                southwest: LatLng(
                  pickupLatLng.latitude < dropLatLng.latitude
                      ? pickupLatLng.latitude
                      : dropLatLng.latitude,
                  pickupLatLng.longitude < dropLatLng.longitude
                      ? pickupLatLng.longitude
                      : dropLatLng.longitude,
                ),
                northeast: LatLng(
                  pickupLatLng.latitude > dropLatLng.latitude
                      ? pickupLatLng.latitude
                      : dropLatLng.latitude,
                  pickupLatLng.longitude > dropLatLng.longitude
                      ? pickupLatLng.longitude
                      : dropLatLng.longitude,
                ),
              ),
              80,
            ),
          );
        }
      }
    });
  }

  Future<LatLng?> _getLatLngFromAddress(String address) async {
    try {
      List<geo.Location> locations = await geo.locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (e) {
      print("❌ Error converting address: $e");
    }
    return null;
  }

  @override
  void dispose() {
    _statusRefreshTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _clearRideStateIfCancelled() async {
    final prefs = await SharedPreferences.getInstance();
    final rideId = prefs.getString('current_ride_id');
    if (rideId == null) {
      setState(() {
        _isRideBooked = false;
        _currentRideId = null;
      });
      return;
    }
    final token = prefs.getString('auth_token');
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse("https://backend.ridealmobility.com/rides/status/$rideId"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = (data['status'] ?? '').toString().toLowerCase();
        if (status == 'cancelled' || status == 'completed') {
          await prefs.remove('current_ride_id');
          setState(() {
            _isRideBooked = false;
            _currentRideId = null;
          });
          print("✅ Cleared ride because status = $status");
        } else {
          print("ℹ️ Current ride still active ($status)");
        }
      }
    } catch (e) {
      print("❌ Error checking ride status: $e");
    }
  }

  Future<void> _checkForExistingRide() async {
    final prefs = await SharedPreferences.getInstance();
    final rideId = prefs.getString('current_ride_id');
    if (rideId != null) {
      setState(() {
        _currentRideId = rideId;
        _isRideBooked = true;
      });
      _startStatusRefresh();
    }
  }

  void _startStatusRefresh() {
    _statusRefreshTimer?.cancel();
    _statusRefreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) => _fetchRideStatus(),
    );
  }

  void _stopStatusRefresh() {
    _statusRefreshTimer?.cancel();
  }

  Future<void> _fetchRideStatus() async {
    if (_currentRideId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;
      final response = await http.get(
        Uri.parse(
          "https://backend.ridealmobility.com/rides/status/$_currentRideId",
        ),
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newStatus = data['status'] ?? '';
        if (_rideStatus != newStatus) {
          setState(() {
            _rideStatus = newStatus;
          });
        }
        if (newStatus == 'completed' || newStatus == 'cancelled') {
          await prefs.remove('current_ride_id');
          await prefs.remove('rideId');
          await prefs.remove('rideStatus');
          await prefs.remove('ongoingRideIds');
          await prefs.remove('last_pickup_lat');
          await prefs.remove('last_pickup_lng');
          await prefs.remove('last_drop_lat');
          await prefs.remove('last_drop_lng');
          await prefs.remove('last_pickup_address');
          await prefs.remove('last_drop_address');
          _stopStatusRefresh();
          setState(() {
            _isRideBooked = false;
            _currentRideId = null;
            _rideStatus = '';
            selectedIndex = -1;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ride $newStatus'),
                backgroundColor:
                    newStatus == 'completed' ? Colors.green : Colors.orange,
              ),
            );
          }
        }
      } else if (response.statusCode == 404) {
        await prefs.remove('current_ride_id');
        await prefs.remove('rideId');
        await prefs.remove('rideStatus');
        _stopStatusRefresh();
        setState(() {
          _isRideBooked = false;
          _currentRideId = null;
          _rideStatus = '';
        });
      }
    } catch (e) {
      print("❌ Error fetching ride status: $e");
    }
  }

  Future<void> _convertAddressesToLatLng() async {
    try {
      LatLng? pickup = await _getLatLngFromAddress(widget.pickupLocation);
      LatLng? drop = await _getLatLngFromAddress(widget.dropoffLocation);
      if (pickup != null && drop != null) {
        setState(() {
          pickupLat = pickup.latitude;
          pickupLng = pickup.longitude;
          dropLat = drop.latitude;
          dropLng = drop.longitude;
          markers.add(
            Marker(
              markerId: const MarkerId("pickup"),
              position: pickup,
              infoWindow: const InfoWindow(title: "Pickup"),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            ),
          );
          markers.add(
            Marker(
              markerId: const MarkerId("drop"),
              position: drop,
              infoWindow: const InfoWindow(title: "Drop-off"),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          );
        });
        _getRouteBetweenCoordinates(pickup, drop);
        distanceInKm =
            Geolocator.distanceBetween(
              pickup.latitude,
              pickup.longitude,
              drop.latitude,
              drop.longitude,
            ) /
            1000;
      }
    } catch (e) {
      print("❌ Error converting addresses: $e");
    }
  }

  Future<void> _getRouteBetweenCoordinates(LatLng pickup, LatLng drop) async {
    try {
      PolylineRequest request = PolylineRequest(
        origin: PointLatLng(pickup.latitude, pickup.longitude),
        destination: PointLatLng(drop.latitude, drop.longitude),
        mode: TravelMode.driving,
      );
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        request: request,
      );
      if (result.points.isNotEmpty) {
        polylineCoordinates.clear();
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
        setState(() {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId("route"),
              points: polylineCoordinates,
              color: Colors.blue,
              width: 5,
            ),
          );
        });
      }
    } catch (e) {
      print("❌ Error getting route: $e");
    }
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }
    loc.PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) return;
    }
    setState(() {
      locationPermissionGranted = true;
    });
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      loc.LocationData locationData = await location.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        setState(() {
          currentPosition = LatLng(
            locationData.latitude!,
            locationData.longitude!,
          );
        });
        if (_controller != null && currentPosition != null) {
          _controller!.animateCamera(
            CameraUpdate.newLatLngZoom(currentPosition!, 15.0),
          );
        }
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    if (currentPosition != null) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(currentPosition!, 15.0),
      );
    }
  }

  Future<void> _calculateDistance() async {
    try {
      List<geo.Location> pickup = await geo.locationFromAddress(
        widget.pickupLocation,
      );
      List<geo.Location> drop = await geo.locationFromAddress(
        widget.dropoffLocation,
      );
      if (pickup.isNotEmpty && drop.isNotEmpty) {
        setState(() {
          pickupLat = pickup.first.latitude;
          pickupLng = pickup.first.longitude;
          dropLat = drop.first.latitude;
          dropLng = drop.first.longitude;
        });
        markers.clear();
        markers.add(
          Marker(
            markerId: const MarkerId("pickup"),
            position: LatLng(pickupLat!, pickupLng!),
            infoWindow: const InfoWindow(title: "Pickup"),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
        markers.add(
          Marker(
            markerId: const MarkerId("drop"),
            position: LatLng(dropLat!, dropLng!),
            infoWindow: const InfoWindow(title: "Drop-off"),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
        double distance = Geolocator.distanceBetween(
          pickupLat!,
          pickupLng!,
          dropLat!,
          dropLng!,
        );
        distanceInKm = distance / 1000;
        _getRouteBetweenCoordinates(
          LatLng(pickupLat!, pickupLng!),
          LatLng(dropLat!, dropLng!),
        );
        if (_controller != null) {
          LatLngBounds bounds = LatLngBounds(
            southwest: LatLng(
              pickupLat! < dropLat! ? pickupLat! : dropLat!,
              pickupLng! < dropLng! ? pickupLng! : dropLng!,
            ),
            northeast: LatLng(
              pickupLat! > dropLat! ? pickupLat! : dropLat!,
              pickupLng! > dropLng! ? pickupLng! : dropLng!,
            ),
          );
          _controller!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
        }
      }
    } catch (e) {
      print("❌ Error calculating distance: $e");
    }
  }

  Future<void> loadRideTypes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        print("❌ No auth token found");
        setState(() => isLoading = false);
        return;
      }
      print("🔄 Fetching ride types...");
      final response = await http.get(
        Uri.parse("https://backend.ridealmobility.com/api/fare"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['fareRates'] != null) {
          final Map<String, dynamic> fareRates = data['fareRates'];
          final Map<String, dynamic>? vehicleImages = data['vehicleImages'];
          List<RideType> types = [];
          fareRates.forEach((key, value) {
            types.add(RideType.fromJson(key, value, vehicleImages));
          });
          setState(() {
            rideTypes = types;
            isLoading = false;
          });
          print("✅ Loaded ${rideTypes.length} ride types");
        } else {
          setState(() => isLoading = false);
          print("❌ Invalid response");
        }
      } else {
        setState(() => isLoading = false);
        print("❌ Failed to load ride types: ${response.statusCode}");
      }
    } catch (e, stackTrace) {
      setState(() => isLoading = false);
      print("❌ Error loading ride types: $e");
      print("Stack trace: $stackTrace");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Choose your ride",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  SizedBox(
                    height: 250,
                    child: RepaintBoundary(
                      child: GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(28.6139, 77.2090),
                          zoom: 14,
                        ),
                        myLocationEnabled: true,
                        markers: markers,
                        polylines: _polylines,
                      ),
                    ),
                  ),
                  if (_isRideBooked && _rideStatus.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: _getStatusColor(_rideStatus),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'You have $_rideStatus ride',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.my_location, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.pickupLocation,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.dropoffLocation,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (selectedIndex != -1)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: PromoCodeWidget(
                        rideType: rideTypes[selectedIndex].originalKey,
                        estimatedAmount: calculateFare(
                          rideTypes[selectedIndex],
                          distanceInKm,
                        ),
                        onPromoApplied: (discount) {
                          setState(() {
                            _appliedPromo = discount;
                            _appliedPromoCode = discount?.code;
                          });
                        },
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: rideTypes.length,
                      itemBuilder: (BuildContext context, int index) {
                        final ride = rideTypes[index];
                        final data = getRideData(ride);
                        double baseFare = calculateFare(ride, distanceInKm);
                        double displayFare = baseFare;
                        if (_appliedPromo != null && selectedIndex == index) {
                          displayFare = _appliedPromo!.finalAmount;
                        }
                        return TransportContainer(
                          data['image']!,
                          ride.type,
                          data['time']!,
                          data['drop']!,
                          displayFare,
                          selectedIndex == index,
                          () {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                          originalFare:
                              _appliedPromo != null && selectedIndex == index
                                  ? baseFare
                                  : null,
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed:
                          selectedIndex == -1 || _isBookingInProgress
                              ? null
                              : () async {
                                try {
                                  await _clearRideStateIfCancelled();
                                  if (_isRideBooked) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "You already have an active ride.",
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final selectedRide = rideTypes[selectedIndex];

                                  // 🚀 GPU Optimization: Clear map data to free up buffers
                                  setState(() {
                                    markers.clear();
                                    _polylines.clear();
                                  });

                                  // ✅ OPTIMISTIC NAVIGATION → Navigate to Confirm screen IMMEDIATELY
                                  // The Confirm screen will handle the actual Authservices.bookRide call
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      transitionDuration: const Duration(
                                        milliseconds: 400,
                                      ),
                                      pageBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                          ) => Confirm(
                                            pickupLocation:
                                                widget.pickupLocation,
                                            dropoffLocation:
                                                widget.dropoffLocation,
                                            rideType: selectedRide.type,
                                            originalRideType:
                                                selectedRide.originalKey,
                                            pickupLat: pickupLat!,
                                            pickupLng: pickupLng!,
                                            dropLat: dropLat!,
                                            dropLng: dropLng!,
                                            promoCode: _appliedPromoCode,
                                            autoBook:
                                                true, // 🚀 Delegate booking to next screen
                                          ),
                                      transitionsBuilder: (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                        child,
                                      ) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        );
                                      },
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("An error occurred: $e"),
                                    ),
                                  );
                                }
                              },
                      child:
                          _isBookingInProgress
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                "Book ${rideTypes.isNotEmpty && selectedIndex != -1 ? rideTypes[selectedIndex].type : ''}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'ongoing':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _saveBookingData(
    Map<String, dynamic> result,
    double lat,
    double lng,
  ) async {
    final rideId = result['rideId'] ?? result['id'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_ride_id', rideId.toString());
    await prefs.setString('rideId', rideId.toString());
    await prefs.setString('last_pickup_lat', lat.toString());
    await prefs.setString('last_pickup_lng', lng.toString());
    await prefs.setString('last_drop_lat', (dropLat ?? 0.0).toString());
    await prefs.setString('last_drop_lng', (dropLng ?? 0.0).toString());
    await prefs.setString('last_pickup_address', widget.pickupLocation);
    await prefs.setString('last_drop_address', widget.dropoffLocation);
  }
}

// ✅ Custom ride card widget
Widget TransportContainer(
  String image,
  String type,
  String time,
  String drop,
  double price,
  bool isSelected,
  VoidCallback onTap, {
  double? originalFare,
}) {
  bool isNetworkImage = image.startsWith('http');

  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? Colors.green.shade50 : Colors.white,
        border: Border.all(
          color: isSelected ? Colors.green : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 50,
            width: 50,
            child:
                isNetworkImage
                    ? Image.network(
                      image,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset('assets/images/bike.png');
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                          ),
                        );
                      },
                    )
                    : Image.asset(image, fit: BoxFit.contain),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(time, style: const TextStyle(color: Colors.grey)),
                Text("Drop: $drop", style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (originalFare != null) ...[
                Text(
                  "₹${originalFare.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                "₹${price.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: originalFare != null ? Colors.green : Colors.black,
                ),
              ),
              if (originalFare != null) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${((originalFare - price) / originalFare * 100).toStringAsFixed(0)}% OFF',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    ),
  );
}
