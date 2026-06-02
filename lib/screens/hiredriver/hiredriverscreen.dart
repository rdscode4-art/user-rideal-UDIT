// Save this file as: lib/screens/hiredriver/hiredriverscreen.dart

import 'package:flutter/material.dart';
import 'package:rideal/screens/hiredriver/hiredrivertrackingscreen.dart';
import 'package:rideal/screens/hiredriver/trip_history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart' as geo;
import 'package:rideal/authservices.dart';
import 'package:rideal/walletauthservices.dart';
import 'package:rideal/screens/wallet/AddAmount.dart';
import 'dart:ui'; // For ImageFilter
import 'package:geolocator/geolocator.dart';

class HireDriverScreen extends StatefulWidget {
  const HireDriverScreen({super.key});

  @override
  State<HireDriverScreen> createState() => _HireDriverScreenState();
}

class _HireDriverScreenState extends State<HireDriverScreen> {
  int selectedHours = 0; // No additional hours
  int selectedDays = 1;
  double pricePerHour = 90.0;
  double foodAllowancePerDay = 250.0;
  bool isLoading = false;
  String? riderId;
  bool isLoadingRiderId = true;
  String? errorMessage;
  String? initialOtp;

  // Pickup location fields
  final TextEditingController _pickupController = TextEditingController();
  final _placesService = PlacesService("AIzaSyBQx7m5RcWfgRtYZzvwxRLcMa3Ks-Z0xUI");
  List<Map<String, dynamic>> _suggestions = [];
  double? _pickupLat;
  double? _pickupLng;
  bool _isGeocodingPickup = false;
  String? _pickupError;

  @override
  void initState() {
    super.initState();
    _loadRiderId();
    _pickupController.addListener(_onPickupTextChanged);
    _getCurrentLocation();
  }

  void _onPickupTextChanged() {
    // If the text changes and we had a geocoded location, clear it
    // to ensure the user confirms the new address
    if (_pickupLat != null || _pickupLng != null) {
      if (mounted) {
        setState(() {
          _pickupLat = null;
          _pickupLng = null;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return;
    }

    setState(() {
      _isGeocodingPickup = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
          position.latitude, position.longitude);
          
      if (placemarks.isNotEmpty && mounted) {
        geo.Placemark place = placemarks[0];
        String address = [
          if (place.name != null && place.name!.isNotEmpty) place.name,
          if (place.subLocality != null && place.subLocality!.isNotEmpty) place.subLocality,
          if (place.locality != null && place.locality!.isNotEmpty) place.locality
        ].join(', ');
        
        setState(() {
          _pickupLat = position.latitude;
          _pickupLng = position.longitude;
        });

        _pickupController.removeListener(_onPickupTextChanged);
        _pickupController.text = address;
        _pickupController.addListener(_onPickupTextChanged);
      }
    } catch (e) {
      print('Location error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isGeocodingPickup = false;
        });
      }
    }
  }

  Future<void> _loadRiderId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      String? id = prefs.getString('rider_id') ?? 
                   prefs.getString('riderId') ?? 
                   prefs.getString('userId') ?? 
                   prefs.getString('user_id') ??
                   prefs.getString('id');
      
      print('SharedPreferences keys: ${prefs.getKeys()}');
      print('RiderId found: $id');
      
      setState(() {
        riderId = id;
        isLoadingRiderId = false;
        if (id == null) {
          errorMessage = 'User ID not found. Please login again.';
        }
      });
    } catch (e) {
      print('Error loading riderId: $e');
      setState(() {
        isLoadingRiderId = false;
        errorMessage = 'Error loading user data: $e';
      });
    }
  }

  // Maximum hours allowed based on days selected
  int get maxAllowedHours {
    return selectedDays == 0 ? 8 : 23;
  }

  // Total price: Days * 8 hours * rate + Days * food allowance
  double get totalPrice {
    int days = selectedDays > 0 ? selectedDays : 1;
    double dayPrice = 8 * pricePerHour;
    double foodAllowance = days * foodAllowancePerDay;
    return (days * dayPrice) + foodAllowance;
  }

  int get totalHours {
    return (selectedDays > 0 ? selectedDays : 1) * 8;
  }

  void _onSearchChanged(String value) async {
    if (value.length > 2) {
      final results = await _placesService.getSuggestions(value);
      setState(() {
        _suggestions = results;
      });
    } else {
      setState(() {
        _suggestions = [];
      });
    }
  }

  Future<void> _geocodePickupAddress() async {
    final address = _pickupController.text.trim();
    if (address.isEmpty) {
      setState(() {
        _pickupError = 'Please enter a pickup address';
        _pickupLat = null;
        _pickupLng = null;
      });
      return;
    }
    setState(() {
      _isGeocodingPickup = true;
      _pickupError = null;
    });
    try {
      final locations = await geo.locationFromAddress(address);
      if (locations.isNotEmpty) {
        setState(() {
          _pickupLat = locations.first.latitude;
          _pickupLng = locations.first.longitude;
          _pickupError = null;
        });
        print('✅ Geocoded pickup: lat=$_pickupLat, lng=$_pickupLng');
      } else {
        setState(() {
          _pickupError = 'Location not found. Try a more specific address.';
          _pickupLat = null;
          _pickupLng = null;
        });
      }
    } catch (e) {
      setState(() {
        _pickupError = 'Failed to find location. Check your address.';
        _pickupLat = null;
        _pickupLng = null;
      });
      print('❌ Geocoding error: $e');
    } finally {
      setState(() => _isGeocodingPickup = false);
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    super.dispose();
  }

  Future<void> _createHireDriverRequest() async {
    if (riderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Rider ID not found. Please login again.')),
      );
      return;
    }

    // Validate pickup location
    if (_pickupLat == null || _pickupLng == null) {
      setState(() => _pickupError = 'Please enter and confirm a valid pickup location');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Please enter a valid pickup location first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Check wallet balance
      final walletData = await WalletAuthServices.getWalletBalance();
      if (walletData == null || walletData['success'] != true) {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Failed to verify wallet balance. Please check your connection.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final double walletBalance = walletData['wallet']?.toDouble() ?? 0.0;
      if (walletBalance < totalPrice) {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          _showInsufficientBalanceDialog(walletBalance);
        }
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token');

      final url = 'https://backend.ridealmobility.com/api/nonvehicle/ride/request';
      final body = {
        'riderId': riderId,
        'hours': totalHours,
        'days': selectedDays,
        'price': totalPrice.toInt(),
        'requestedBy': "rider",
        'vehicleType': "non-vehichle",
        'pickupLocation': {
          'lat': _pickupLat,
          'lng': _pickupLng,
        },
      };

      // Print CURL command for debugging
      print('🚀 HIRE DRIVER API CALL:');
      print('curl -X POST "$url" \\');
      print('  -H "Content-Type: application/json" \\');
      if (token != null) print('  -H "Authorization: Bearer $token" \\');
      print("  -d '${jsonEncode(body)}'");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      print('📥 HIRE DRIVER API RESPONSE: ${response.statusCode}');
      print('📥 BODY: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          final requestId = data['requestId'];
          final otp = data['otp']?.toString() ?? '';

          await prefs.setString('hireDriverRequestId', requestId);

          if (mounted) {
            print("data:$data");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HireDriverTrackingScreen(
                  otp: otp,
                  requestId: requestId,
                  hours: totalHours,
                  totalPrice: totalPrice,
                ),
              ),
            );
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to create request');
        }
      } else {
        throw Exception(data['message'] ?? 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showInsufficientBalanceDialog(double currentBalance) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 50,
                    color: Colors.red.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Insufficient Balance',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'Your current wallet balance is '),
                      TextSpan(
                        text: '₹${currentBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const TextSpan(text: ', which is not enough for this booking of '),
                      TextSpan(
                        text: '₹${totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const TextSpan(text: '.\n\nPlease add money to your wallet to proceed.'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context); // Close the dialog
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Amount(),
                            ),
                          );
                          if (result == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Balance updated! Try booking again.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Add Money',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: isLoadingRiderId
          ? const Center(child: CircularProgressIndicator())
          : riderId == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage ?? 'User ID not found',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.login),
                          label: const Text('Go to Login'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 120), // Space for bottom bar
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Custom Header
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
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
                                        child: const Icon(Icons.arrow_back, color: Colors.black87, size: 18),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      "Hire Driver",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.3,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => TripHistoryScreen()),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
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
                                    child: const Icon(Icons.history, color: Colors.black87, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Large Typography Intro
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Need a driver\nfor your car?",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                    letterSpacing: -1,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Hire professional drivers by the day.",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Pickup Location Search Bar
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _pickupError != null
                                            ? Colors.red.shade200
                                            : _pickupLat != null
                                                ? Colors.green.shade200
                                                : Colors.grey.shade200,
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _pickupController,
                                      onChanged: _onSearchChanged,
                                      textAlignVertical: TextAlignVertical.center,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                      decoration: InputDecoration(
                                        hintText: 'Pickup address',
                                        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                                        prefixIcon: Icon(
                                          Icons.location_on,
                                          size: 16,
                                          color: _pickupLat != null ? const Color(0xFF0F9D58) : Colors.black45,
                                        ),
                                        suffixIcon: _isGeocodingPickup
                                            ? const Padding(
                                                padding: EdgeInsets.all(14),
                                                child: SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F9D58)),
                                                ),
                                              )
                                            : _pickupController.text.isNotEmpty
                                                ? IconButton(
                                                    icon: const Icon(Icons.close, size: 16, color: Colors.black45),
                                                    onPressed: () {
                                                      setState(() {
                                                        _pickupController.clear();
                                                        _suggestions = [];
                                                        _pickupLat = null;
                                                        _pickupLng = null;
                                                        _pickupError = null;
                                                      });
                                                    },
                                                  )
                                                : null,
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_suggestions.isNotEmpty)
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border(top: BorderSide(color: Colors.grey.shade100)),
                                    ),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _suggestions.length,
                                      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                                      itemBuilder: (context, index) {
                                        final suggestion = _suggestions[index];
                                        return ListTile(
                                          visualDensity: VisualDensity.compact,
                                          leading: const Icon(Icons.location_on_outlined, color: Colors.black54, size: 18),
                                          title: Text(
                                            suggestion["description"] ?? "",
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                          ),
                                          onTap: () {
                                            _pickupController.text = suggestion["description"] ?? "";
                                            setState(() => _suggestions = []);
                                            _geocodePickupAddress();
                                          },
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (_pickupError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, left: 20),
                              child: Text(
                                _pickupError!,
                                style: TextStyle(color: Colors.red.shade600, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                          const SizedBox(height: 24),

                          // Days Selection
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              "Duration",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Number of Days',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                            onPressed: selectedDays > 0 ? () => setState(() => selectedDays--) : null,
                                            icon: Icon(Icons.remove, size: 16, color: selectedDays > 0 ? Colors.black87 : Colors.black26),
                                          ),
                                          Text(
                                            '$selectedDays',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
                                          ),
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                            onPressed: selectedDays < 30 ? () => setState(() => selectedDays++) : null,
                                            icon: Icon(Icons.add, size: 16, color: selectedDays < 30 ? Colors.black87 : Colors.black26),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [1, 2, 3, 5, 7, 10, 15].map((days) {
                                      final isSelected = selectedDays == days;
                                      return GestureDetector(
                                        onTap: () => setState(() => selectedDays = days),
                                        child: Container(
                                          margin: const EdgeInsets.only(right: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.black87 : Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected ? Colors.black87 : Colors.grey.shade200,
                                            ),
                                          ),
                                          child: Text(
                                            '$days days',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                              color: isSelected ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Important Pricing Notes
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF9E6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFFE082), width: 1),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline, color: Color(0xFFF57C00), size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Pricing Rules',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFE65100)),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '• 1 day = Fixed 8 hours at ₹720\n• Driver food allowance: ₹250/day',
                                        style: TextStyle(fontSize: 12, color: const Color(0xFFE65100).withOpacity(0.8), height: 1.5, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),

                          // Features
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'What\'s Included',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
                                ),
                                const SizedBox(height: 16),
                                _buildFeatureItem(Icons.verified_user_outlined, 'Professional & Verified Driver'),
                                _buildFeatureItem(Icons.shield_outlined, 'Fully Insured Service'),
                                _buildFeatureItem(Icons.headset_mic_outlined, '24/7 Customer Support'),
                                _buildFeatureItem(Icons.account_balance_wallet_outlined, 'Flexible Payment Options'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),

                    // Floating Bottom Glass Sheet
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: EdgeInsets.only(
                              top: 20,
                              left: 24,
                              right: 24,
                              bottom: MediaQuery.of(context).padding.bottom + 20,
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Total Estimate",
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54),
                                    ),
                                    Text(
                                      '₹${totalPrice.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87),
                                    ),
                                    Text(
                                      selectedDays == 1 ? '1 day (8 hours)' : '$selectedDays days (${selectedDays * 8} hrs)',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F9D58)),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: (selectedDays == 0 && selectedHours == 0) || isLoading ? null : _createHireDriverRequest,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: (selectedDays == 0 && selectedHours == 0) ? Colors.grey : const Color(0xFF0F9D58),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        if (selectedDays > 0)
                                          BoxShadow(
                                            color: const Color(0xFF0F9D58).withOpacity(0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                      ],
                                    ),
                                    child: isLoading
                                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Text(
                                            "Confirm",
                                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
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

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF0F9D58), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}