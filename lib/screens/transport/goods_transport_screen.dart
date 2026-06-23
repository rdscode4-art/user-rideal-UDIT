import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rideal/authservices.dart';
import 'package:rideal/screens/transport/thankyou.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:rideal/screens/transport/goods_transport_history_screen.dart';
import 'dart:ui';

class GoodsTransportScreen extends StatefulWidget {
  const GoodsTransportScreen({super.key});

  @override
  State<GoodsTransportScreen> createState() => _GoodsTransportScreenState();
}

class _GoodsTransportScreenState extends State<GoodsTransportScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();
  final PlacesService _placesService = PlacesService("AIzaSyBQx7m5RcWfgRtYZzvwxRLcMa3Ks-Z0xUI");

  List<Map<String, dynamic>> _pickupSuggestions = [];
  List<Map<String, dynamic>> _dropSuggestions = [];

  double? _pickupLat;
  double? _pickupLng;
  double? _dropLat;
  double? _dropLng;

  bool _isGeocodingPickup = false;
  bool _isGeocodingDrop = false;

  double _estimatedDistance = 0.0; // in km
  int _selectedVehicleIndex = 0;
  String _selectedPayment = 'Cash';
  bool _isBookingInProgress = false;

  // Scheduling state variables
  bool _isScheduled = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // The 4 categories of vehicles as requested
  final List<Map<String, dynamic>> _vehicles = [
    {
      'name': 'Tata Ace',
      'icon': '🚚',
      'capacity': '850 kg',
      'size': '7ft x 4.5ft x 5ft',
      'description': 'Best for household appliances, small furniture, and medium boxes.',
      'basePrice': 250,
      'perKmRate': 20,
    },
    {
      'name': 'Tata Pickup / Bolero Pickup',
      'icon': '🚚',
      'capacity': '1500 kg',
      'size': '8ft x 4.8ft x 5.5ft',
      'description': 'Perfect for commercial bulk cargo, large sofas, and heavy industrial goods.',
      'basePrice': 350,
      'perKmRate': 25,
    },
    {
      'name': 'Auto Cargo / Ape Piaggio',
      'icon': '🛺',
      'capacity': '500 kg',
      'size': '5.5ft x 4ft x 4.5ft',
      'description': 'Ideal for quick shifting of carton boxes, small electronics, and light loads.',
      'basePrice': 180,
      'perKmRate': 15,
    },
    {
      'name': 'Mini Truck 6 Wheeler',
      'icon': '🚛',
      'capacity': '3000 kg',
      'size': '10ft x 6ft x 6.5ft',
      'description': 'Recommended for complete 2-3 BHK home shifting and heavy industrial machinery.',
      'basePrice': 600,
      'perKmRate': 35,
    },
  ];

  @override
  void initState() {
    super.initState();
    _setCurrentLocationAsPickup();
  }

  Future<void> _setCurrentLocationAsPickup() async {
    try {
      setState(() => _isGeocodingPickup = true);
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isGeocodingPickup = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isGeocodingPickup = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isGeocodingPickup = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _pickupLat = position.latitude;
      _pickupLng = position.longitude;

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        String address = [
          if (p.name != null && p.name!.isNotEmpty && p.name != 'Unnamed Road') p.name,
          if (p.street != null && p.street!.isNotEmpty) p.street,
          if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality,
        ].join(', ');

        setState(() {
          _pickupController.text = address;
        });
      }
    } catch (e) {
      print("Error getting current location: $e");
    } finally {
      setState(() => _isGeocodingPickup = false);
    }
  }

  void _onPickupChanged(String value) async {
    if (value.isNotEmpty) {
      final results = await _placesService.getSuggestions(value);
      setState(() => _pickupSuggestions = results);
    } else {
      setState(() => _pickupSuggestions = []);
    }
  }

  void _onDropChanged(String value) async {
    if (value.isNotEmpty) {
      final results = await _placesService.getSuggestions(value);
      setState(() => _dropSuggestions = results);
    } else {
      setState(() => _dropSuggestions = []);
    }
  }

  Future<void> _geocodeAndCalculateDistance(String address, bool isPickup) async {
    try {
      if (isPickup) {
        setState(() => _isGeocodingPickup = true);
      } else {
        setState(() => _isGeocodingDrop = true);
      }

      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        if (isPickup) {
          _pickupLat = loc.latitude;
          _pickupLng = loc.longitude;
        } else {
          _dropLat = loc.latitude;
          _dropLng = loc.longitude;
        }

        if (_pickupLat != null && _pickupLng != null && _dropLat != null && _dropLng != null) {
          double distanceMeters = Geolocator.distanceBetween(
            _pickupLat!,
            _pickupLng!,
            _dropLat!,
            _dropLng!,
          );
          setState(() {
            _estimatedDistance = distanceMeters / 1000.0;
          });
        }
      }
    } catch (e) {
      print("Geocoding failed for ${isPickup ? 'pickup' : 'dropoff'}: $e");
    } finally {
      setState(() {
        if (isPickup) {
          _isGeocodingPickup = false;
        } else {
          _isGeocodingDrop = false;
        }
      });
    }
  }

  double _calculatePrice(Map<String, dynamic> vehicle) {
    int base = vehicle['basePrice'] as int;
    int perKm = vehicle['perKmRate'] as int;
    double cost = base + (_estimatedDistance * perKm);
    return cost;
  }

  void _confirmBooking() async {
    final pickup = _pickupController.text.trim();
    final drop = _dropController.text.trim();

    if (pickup.isEmpty || drop.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ Please enter both pickup and dropoff locations"),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isScheduled && (_selectedDate == null || _selectedTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ Please select both Date and Time for scheduling"),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isBookingInProgress = true;
    });

    // Elegant simulated loading state showing driver searching status
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      // Save to local SharedPreferences history list
      final selectedVehicle = _vehicles[_selectedVehicleIndex];
      final calculatedFare = _calculatePrice(selectedVehicle);

      final bookingData = {
        'id': 'GT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        'pickup': pickup,
        'drop': drop,
        'distance': _estimatedDistance,
        'vehicle': selectedVehicle['name'] as String,
        'vehicleIcon': selectedVehicle['icon'] as String,
        'price': calculatedFare.toInt(),
        'payment': _selectedPayment,
        'isScheduled': _isScheduled,
        'scheduledDate': _isScheduled && _selectedDate != null 
            ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"
            : null,
        'scheduledTime': _isScheduled && _selectedTime != null
            ? _selectedTime!.format(context)
            : null,
        'bookingTime': DateTime.now().toIso8601String(),
        'status': _isScheduled ? 'Scheduled' : 'Completed',
      };

      try {
        final prefs = await SharedPreferences.getInstance();
        List<String> list = prefs.getStringList('goods_transport_history') ?? [];
        list.add(jsonEncode(bookingData));
        await prefs.setStringList('goods_transport_history', list);
      } catch (e) {
        print("Error saving booking history: $e");
      }

      setState(() {
        _isBookingInProgress = false;
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ThankYou()),
      );
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedVehicle = _vehicles[_selectedVehicleIndex];
    final calculatedFare = _calculatePrice(selectedVehicle);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 120.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom Header
                  Padding(
                    padding: EdgeInsets.only(top: 8.w, left: 16.w, right: 16.w, bottom: 20.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const GoodsTransportHistoryScreen(),
                              ),
                            );
                          },
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
                            child: Icon(Icons.history, color: Colors.black87, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Large Typography Intro
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Need a truck?",
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w800,
                            height: 1.1.w,
                            letterSpacing: -1,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8.w),
                        Text(
                          "Transport goods across the city easily.",
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.w),

                  // Locations Card
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16.0.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pickup Field
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 0),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.circle, size: 12, color: Color(0xFF0F9D58)),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: TextField(
                                    controller: _pickupController,
                                    onChanged: _onPickupChanged,
                                    textAlignVertical: TextAlignVertical.center,
                                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                                    decoration: InputDecoration(
                                      hintText: "Pickup location",
                                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14.sp),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 16.w),
                                      isDense: true,
                                      suffixIcon: _isGeocodingPickup
                                          ? Padding(
                                              padding: EdgeInsets.all(14.0.w),
                                              child: SizedBox(
                                                width: 16.w, height: 16.w,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F9D58)),
                                              ),
                                            )
                                          : _pickupController.text.isNotEmpty
                                              ? IconButton(
                                                  icon: Icon(Icons.close, size: 16, color: Colors.black45),
                                                  onPressed: () {
                                                    _pickupController.clear();
                                                    setState(() {
                                                      _pickupLat = null; _pickupLng = null;
                                                      _pickupSuggestions = []; _estimatedDistance = 0.0;
                                                    });
                                                  },
                                                )
                                              : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_pickupSuggestions.isNotEmpty)
                            Container(
                              constraints: BoxConstraints(maxHeight: 200),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _pickupSuggestions.length > 3 ? 3 : _pickupSuggestions.length,
                                separatorBuilder: (context, idx) => Divider(height: 1.w, color: Colors.grey.shade100),
                                itemBuilder: (context, index) {
                                  final suggestion = _pickupSuggestions[index];
                                  return ListTile(
                                    visualDensity: VisualDensity.compact,
                                    leading: Icon(Icons.location_on_outlined, color: Colors.black54, size: 18),
                                    title: Text(suggestion["description"]!, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500)),
                                    onTap: () {
                                      _pickupController.text = suggestion["description"]!;
                                      setState(() => _pickupSuggestions = []);
                                      _geocodeAndCalculateDistance(suggestion["description"]!, true);
                                    },
                                  );
                                },
                              ),
                            ),
                          
                          Padding(
                            padding: EdgeInsets.only(left: 17.w, top: 4.w, bottom: 4.w),
                            child: SizedBox(height: 16.w, child: VerticalDivider(color: Colors.grey, thickness: 1)),
                          ),

                          // Dropoff Field
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 0),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.circle, size: 12, color: Colors.redAccent),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: TextField(
                                    controller: _dropController,
                                    onChanged: _onDropChanged,
                                    textAlignVertical: TextAlignVertical.center,
                                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                                    decoration: InputDecoration(
                                      hintText: "Where to?",
                                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14.sp),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 16.w),
                                      isDense: true,
                                      suffixIcon: _isGeocodingDrop
                                          ? Padding(
                                              padding: EdgeInsets.all(14.0.w),
                                              child: SizedBox(
                                                width: 16.w, height: 16.w,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                                              ),
                                            )
                                          : _dropController.text.isNotEmpty
                                              ? IconButton(
                                                  icon: Icon(Icons.close, size: 16, color: Colors.black45),
                                                  onPressed: () {
                                                    _dropController.clear();
                                                    setState(() {
                                                      _dropLat = null; _dropLng = null;
                                                      _dropSuggestions = []; _estimatedDistance = 0.0;
                                                    });
                                                  },
                                                )
                                              : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_dropSuggestions.isNotEmpty)
                            Container(
                              constraints: BoxConstraints(maxHeight: 200),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _dropSuggestions.length > 3 ? 3 : _dropSuggestions.length,
                                separatorBuilder: (context, idx) => Divider(height: 1.w, color: Colors.grey.shade100),
                                itemBuilder: (context, index) {
                                  final suggestion = _dropSuggestions[index];
                                  return ListTile(
                                    visualDensity: VisualDensity.compact,
                                    leading: Icon(Icons.location_on_outlined, color: Colors.black54, size: 18),
                                    title: Text(suggestion["description"]!, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500)),
                                    onTap: () {
                                      _dropController.text = suggestion["description"]!;
                                      setState(() => _dropSuggestions = []);
                                      _geocodeAndCalculateDistance(suggestion["description"]!, false);
                                    },
                                  );
                                },
                              ),
                            ),
                          
                          if (_estimatedDistance > 0) ...[
                            SizedBox(height: 16.w),
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F9D58).withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Trip Distance", style: TextStyle(color: Colors.black54, fontSize: 13.sp, fontWeight: FontWeight.w500)),
                                  Text(
                                    "${_estimatedDistance.toStringAsFixed(1)} km",
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.sp, color: Color(0xFF0F9D58)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24.w),
                  
                  // Vehicles Section
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text(
                      "Select Goods Carrier",
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                  SizedBox(height: 12.w),
                  ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _vehicles.length,
                    itemBuilder: (context, index) {
                      final v = _vehicles[index];
                      final isSelected = index == _selectedVehicleIndex;
                      final price = _calculatePrice(v);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedVehicleIndex = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.only(bottom: 12.w),
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF0F9D58) : Colors.transparent,
                              width: 2.w,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected ? const Color(0xFF0F9D58).withOpacity(0.15) : Colors.black.withOpacity(0.03),
                                blurRadius: isSelected ? 15 : 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(v['icon'] as String, style: TextStyle(fontSize: 24.sp)),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      v['name'] as String,
                                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                    SizedBox(height: 4.w),
                                    Text(
                                      "Max: ${v['capacity']} • ${v['size']}",
                                      style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                    ),
                                    SizedBox(height: 6.w),
                                    Text(
                                      v['description'] as String,
                                      style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "₹${price.toStringAsFixed(0)}",
                                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: Colors.black87),
                                  ),
                                  SizedBox(height: 4.w),
                                  Text(
                                    "₹${v['basePrice']}+₹${v['perKmRate']}/km",
                                    style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 20.w),

                  // Payment Method Section
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text(
                      "Payment Method",
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                  SizedBox(height: 12.w),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      children: [
                        _buildPaymentOption('Cash', Icons.money, Colors.orange),
                        SizedBox(width: 12.w),
                        _buildPaymentOption('UPI', Icons.account_balance, Colors.blue),
                        SizedBox(width: 12.w),
                        _buildPaymentOption('Wallet', Icons.account_balance_wallet, const Color(0xFF0F9D58)),
                      ],
                    ),
                  ),
                  SizedBox(height: 40.w),
                ],
              ),
            ),

            // Floating Frosted Bottom Bar
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: EdgeInsets.only(
                      top: 16.w, left: 20.w, right: 20.w,
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20, offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Total Estimate", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: Colors.black54)),
                            Text(
                              "₹${calculatedFare.toStringAsFixed(0)}",
                              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w800, color: Colors.black87),
                            ),
                          ],
                        ),
                        SizedBox(width: 20.w),
                        Expanded(
                          child: GestureDetector(
                            onTap: _confirmBooking,
                            child: Container(
                              height: 52.w,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F9D58),
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0F9D58).withOpacity(0.3),
                                    blurRadius: 10, offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  "Book Truck",
                                  style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Searching Loader Overlay
            if (_isBookingInProgress)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 40.w, height: 40.w,
                          child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F9D58))),
                        ),
                        SizedBox(height: 20.w),
                        Text(
                          "Finding drivers...",
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.black87),
                        ),
                        SizedBox(height: 4.w),
                        Text(
                          "Looking for nearby ${selectedVehicle['name']}",
                          style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
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

  Widget _buildPaymentOption(String title, IconData icon, Color color) {
    final isSelected = _selectedPayment == title;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPayment = title;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.w),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey, size: 24),
              SizedBox(height: 6.w),
              Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.black87,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
