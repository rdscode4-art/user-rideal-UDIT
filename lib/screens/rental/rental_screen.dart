import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:rideal/authservices.dart';
import 'package:rideal/screens/rental/rental_payment_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RentalScreen extends StatefulWidget {
  const RentalScreen({super.key});

  @override
  State<RentalScreen> createState() => _RentalScreenState();
}

class _RentalScreenState extends State<RentalScreen> {
  static const Color _primaryGreen = Color(0xFF0F9D58);
  static const String _baseUrl = Authservices.baseUrl;
  static const double _defaultLat = 28.5786;
  static const double _defaultLng = 77.3178;
  static const String _defaultLocationLabel = 'Noida';

  final List<String> _vehicleTypes = const ['Car', 'Bike', 'SUV', 'EV'];
  final List<String> _bookingTypes = const ['Daily', 'Hourly'];

  String? _selectedVehicleType;
  String _selectedBookingType = 'Daily';
  bool _hasSearched = false;
  bool _isSearching = false;
  String? _bookingVehicleId;
  bool _isLoadingLocation = false;
  bool _isUsingDefaultLocation = true;
  double _currentLat = _defaultLat;
  double _currentLng = _defaultLng;
  num? _searchRadius;
  List<Map<String, dynamic>> _vehicles = [];

  DateTime _startDate = DateTime.now().add(const Duration(hours: 1));
  late DateTime _endDate;

  bool get _canSearch => _selectedVehicleType != null;

  @override
  void initState() {
    super.initState();
    _endDate = _startDate.add(const Duration(days: 1));
  }

  Future<void> _loadCurrentLocation({bool showMessage = true}) async {
    if (_isLoadingLocation) return;

    setState(() => _isLoadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (showMessage) {
          _showSnackBar(
            'Phone location is off. Searching near $_defaultLocationLabel.',
            isError: false,
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (showMessage) {
          _showSnackBar(
            'Location permission denied. Searching near $_defaultLocationLabel.',
            isError: false,
          );
        }
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (showMessage) {
          _showLocationSettingsSheet();
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
        _isUsingDefaultLocation = false;
      });

      if (showMessage) {
        _showSnackBar('Current location updated', isError: false);
      }
    } catch (e) {
      if (showMessage) {
        _showSnackBar(
          'Unable to get current location. Searching near $_defaultLocationLabel.',
          isError: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _searchVehicles() async {
    if (!_canSearch) {
      _showSnackBar('Please select vehicle type');
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final token = await Authservices.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse('$_baseUrl/api/vehicle-bookings/search').replace(
        queryParameters: {
          'lat': _currentLat.toString(),
          'lng': _currentLng.toString(),
          'type': _selectedVehicleType!.toLowerCase(),
          'bookingType': _selectedBookingType.toLowerCase(),
          'startDate': _startDate.toUtc().toIso8601String(),
          'endDate': _endDate.toUtc().toIso8601String(),
        },
      );

      debugPrint('🔍 RENTAL SEARCH URL: $url');
      debugPrint('🔑 Token: ${token.substring(0, 20)}...');

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint('📡 Response Status: ${response.statusCode}');
      debugPrint('📦 Response Body: ${response.body}');

      final decoded = jsonDecode(response.body);
      if (response.statusCode != 200 || decoded['success'] != true) {
        final message =
            decoded is Map<String, dynamic>
                ? decoded['message']?.toString()
                : null;
        throw Exception(message ?? 'Failed to search rental vehicles');
      }

      final vehicles = decoded['vehicles'];
      if (!mounted) return;
      setState(() {
        _vehicles =
            vehicles is List
                ? vehicles
                    .whereType<Map>()
                    .map((item) => Map<String, dynamic>.from(item))
                    .toList()
                : [];
        _searchRadius =
            decoded['radius'] is num ? decoded['radius'] as num : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _vehicles = []);
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red.shade600 : _primaryGreen,
      ),
    );
  }

  void _showLocationSettingsSheet() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Location permission off',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Rental search will continue near $_defaultLocationLabel. Enable location from settings to search near you.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Continue'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Geolocator.openAppSettings();
                      },
                      child: const Text('Settings'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$_baseUrl$path';
  }

  String _priceText(Map<String, dynamic> vehicle) {
    final pricing = vehicle['pricing'];
    if (pricing is! Map) return 'Rs --';

    final key = _selectedBookingType == 'Hourly' ? 'hourlyRate' : 'dailyRate';
    final price = pricing[key] ?? pricing['dailyRate'] ?? pricing['hourlyRate'];
    final currency = pricing['currency']?.toString() ?? 'INR';
    if (price == null) return '$currency --';
    return '$currency $price';
  }

  String? _vehicleId(Map<String, dynamic> vehicle) {
    return vehicle['_id']?.toString() ?? vehicle['id']?.toString();
  }

  String _ownerAddress(Map<String, dynamic> owner) {
    final address = owner['address'];
    if (address is! Map) return 'Location available';
    final area = address['area']?.toString();
    final city = address['city']?.toString();
    final parts = [area, city].where((part) => part != null && part.isNotEmpty);
    return parts.isEmpty ? 'Location available' : parts.join(', ');
  }

  Future<void> _bookVehicle(Map<String, dynamic> vehicle) async {
    final vehicleId = _vehicleId(vehicle);
    if (vehicleId == null || vehicleId.isEmpty) {
      _showSnackBar('Vehicle id not found');
      return;
    }

    if (_bookingVehicleId != null) return;

    // Navigate to payment screen instead of direct booking with selected dates
    if (!mounted) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RentalPaymentScreen(
          vehicle: vehicle,
          bookingType: _selectedBookingType,
          startDate: _startDate,
          endDate: _endDate,
        ),
      ),
    );
  }

  void _showBookingConfirmationDialog(Map<String, dynamic> vehicle) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Confirm Booking',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: Text(
            'Are you sure you want to book ${vehicle['model'] ?? 'this vehicle'}?',
            style: const TextStyle(fontSize: 15, color: Colors.black54),
          ),
          actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(); // Close the dialog, keeps page open
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
                _bookVehicle(vehicle); // Call booking API
              },
              child: const Text(
                'Confirm',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveRentalBookingHistory(
    Map<String, dynamic> vehicle,
    Map<String, dynamic> response,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('rental_vehicle_bookings') ?? [];
      final bookingData = response['booking'];
      final booking =
          bookingData is Map
              ? Map<String, dynamic>.from(bookingData)
              : <String, dynamic>{};
      final bookingId =
          booking['_id']?.toString() ??
          booking['id']?.toString() ??
          response['bookingId']?.toString();

      history.add(
        jsonEncode({
          'bookingId': bookingId,
          'status': booking['status']?.toString() ?? 'pending',
          'bookingType':
              booking['bookingType']?.toString() ??
              _selectedBookingType.toLowerCase(),
          'vehicleId': _vehicleId(vehicle),
          'vehicleModel': vehicle['model']?.toString() ?? 'Rental vehicle',
          'numberPlate': vehicle['numberPlate']?.toString(),
          'requestedAt': DateTime.now().toIso8601String(),
          'rawBooking': booking,
        }),
      );

      await prefs.setStringList('rental_vehicle_bookings', history);
    } catch (e) {
      debugPrint('Failed to save rental booking history: $e');
    }
  }

  void _showBookingSuccessSheet(Map<String, dynamic> vehicle) {
    final owner = vehicle['owner'];
    final ownerName =
        owner is Map ? owner['agencyName'] ?? owner['name'] : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Rental vehicle selected',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${vehicle['model'] ?? 'Vehicle'} from ${ownerName ?? 'owner'} has been requested. Our team will confirm availability shortly.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 8),
              _buildIntro(),
              const SizedBox(height: 22),
              _buildFilterCard(),
              const SizedBox(height: 24),
              _buildVehicleSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: _buildRoundIcon(Icons.arrow_back),
          ),
          _buildRoundIcon(Icons.car_rental_outlined),
        ],
      ),
    );
  }

  Widget _buildRoundIcon(IconData icon) {
    return Container(
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
      child: Icon(icon, color: Colors.black87, size: 18),
    );
  }

  Widget _buildIntro() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rent a vehicle',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: 0,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search nearby rental vehicles from verified owners.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLocationRow(),
          const SizedBox(height: 14),
          _buildDropdown(
            label: 'Vehicle Type',
            hint: 'Select vehicle',
            icon: Icons.directions_car_outlined,
            value: _selectedVehicleType,
            items: _vehicleTypes,
            onChanged: (value) {
              setState(() {
                _selectedVehicleType = value;
                _hasSearched = false;
                _vehicles = [];
              });
            },
          ),
          const SizedBox(height: 14),
          _buildDropdown(
            label: 'Booking Type',
            hint: 'Select booking',
            icon: Icons.calendar_month_outlined,
            value: _selectedBookingType,
            items: _bookingTypes,
            onChanged: (value) {
              setState(() {
                _selectedBookingType = value ?? 'Daily';
                _hasSearched = false;
                _vehicles = [];
                if (_selectedBookingType == 'Hourly') {
                  _endDate = _startDate.add(const Duration(hours: 2));
                } else {
                  _endDate = _startDate.add(const Duration(days: 1));
                }
              });
            },
          ),
          const SizedBox(height: 14),
          _buildDateTimeSection(),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _isSearching ? null : _searchVehicles,
              icon:
                  _isSearching
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.manage_search_outlined, size: 20),
              label: Text(
                _isSearching ? 'Searching...' : 'Search Vehicles',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow() {
    final locationText =
        _isUsingDefaultLocation
            ? 'Searching near $_defaultLocationLabel'
            : '${_currentLat.toStringAsFixed(4)}, ${_currentLng.toStringAsFixed(4)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.my_location_outlined, color: _primaryGreen, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isLoadingLocation ? 'Getting current location...' : locationText,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          TextButton(
            onPressed:
                _isLoadingLocation
                    ? null
                    : () => _loadCurrentLocation(showMessage: true),
            child: const Text(
              'Update',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(icon, color: _primaryGreen, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    hint: Text(
                      hint,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(16),
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items:
                        items
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(
                                  item,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    final startLabel = '${_startDate.day}/${_startDate.month}/${_startDate.year} ${_formatTime(_startDate)}';
    final endLabel = '${_endDate.day}/${_endDate.month}/${_endDate.year} ${_formatTime(_endDate)}';

    return Row(
      children: [
        Expanded(
          child: _buildDateTimeTile(
            label: 'Start Date & Time',
            value: startLabel,
            icon: Icons.access_time_outlined,
            onTap: () async {
              final selected = await _selectDateTime(context, _startDate);
              if (selected != null) {
                setState(() {
                  _startDate = selected;
                  if (_endDate.isBefore(_startDate)) {
                    _endDate = _selectedBookingType == 'Hourly'
                        ? _startDate.add(const Duration(hours: 2))
                        : _startDate.add(const Duration(days: 1));
                  }
                  _hasSearched = false;
                  _vehicles = [];
                });
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDateTimeTile(
            label: 'End Date & Time',
            value: endLabel,
            icon: Icons.update_outlined,
            onTap: () async {
              final selected = await _selectDateTime(context, _endDate);
              if (selected != null) {
                if (selected.isBefore(_startDate)) {
                  _showSnackBar('End date/time cannot be before start date/time');
                  return;
                }
                setState(() {
                  _endDate = selected;
                  _hasSearched = false;
                  _vehicles = [];
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(icon, color: _primaryGreen, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<DateTime?> _selectDateTime(BuildContext context, DateTime initialDateTime) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return null;

    if (!context.mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDateTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time == null) return null;

    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  Widget _buildVehicleSection() {
    final resultTitle =
        _searchRadius == null
            ? 'Available Vehicles'
            : 'Available Vehicles within ${_searchRadius!.toStringAsFixed(0)} km';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              resultTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_isSearching)
            _buildLoadingState()
          //else if (!_hasSearched)
          // _buildEmptyState(
          //   icon: Icons.manage_search_outlined,
          //   title: 'Select filters',
          //   message: 'Choose vehicle and booking type to see nearby rentals.',
          // )
          else if (_vehicles.isEmpty)
            _buildEmptyState(
              icon: Icons.event_busy_outlined,
              title: 'No vehicles found',
              message: 'Try another vehicle type or update your location.',
            )
          else
            ..._vehicles.map(_buildVehicleCard),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(color: _primaryGreen),
          const SizedBox(height: 14),
          const Text(
            'Finding rental vehicles...',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primaryGreen.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _primaryGreen, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    final owner = vehicle['owner'];
    final ownerMap =
        owner is Map<String, dynamic> ? owner : <String, dynamic>{};
    final vehicleId = _vehicleId(vehicle);
    final isBookingThisVehicle =
        vehicleId != null && _bookingVehicleId == vehicleId;
    final images = vehicle['images'];
    final imagePath =
        images is List && images.isNotEmpty ? images.first?.toString() : null;
    final distance =
        vehicle['distanceKm'] is num
            ? '${(vehicle['distanceKm'] as num).toStringAsFixed(1)} km'
            : 'Nearby';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVehicleImage(_imageUrl(imagePath)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle['model']?.toString() ?? 'Rental vehicle',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      ownerMap['agencyName']?.toString() ??
                          ownerMap['name']?.toString() ??
                          'Verified owner',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildInfoPill(
                          Icons.airline_seat_recline_normal,
                          '${vehicle['seatingCapacity'] ?? '--'} seats',
                        ),
                        _buildInfoPill(
                          Icons.local_gas_station_outlined,
                          vehicle['fuelType']?.toString().toUpperCase() ?? '--',
                        ),
                        _buildInfoPill(
                          Icons.social_distance_outlined,
                          distance,
                        ),
                        _buildInfoPill(
                          Icons.location_on_outlined,
                          _ownerAddress(ownerMap),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (() {
                        final calculatedFareInfo = vehicle['calculatedFareInfo'];
                        final estimatedFare = calculatedFareInfo != null ? calculatedFareInfo['estimatedFare'] : null;
                        final totalDays = calculatedFareInfo != null ? calculatedFareInfo['totalDays'] : null;
                        final totalHours = calculatedFareInfo != null ? calculatedFareInfo['totalHours'] : null;
                        if (estimatedFare != null) {
                          if (totalDays != null) {
                            return 'Total for $totalDays Day${totalDays > 1 ? "s" : ""}';
                          } else if (totalHours != null) {
                            return 'Total for $totalHours Hour${totalHours > 1 ? "s" : ""}';
                          }
                          return 'Estimated Fare';
                        }
                        return _selectedBookingType == 'Hourly' ? 'Per hour' : 'Per day';
                      })(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      (() {
                        final calculatedFareInfo = vehicle['calculatedFareInfo'];
                        final estimatedFare = calculatedFareInfo != null ? calculatedFareInfo['estimatedFare'] : null;
                        if (estimatedFare != null) {
                          final pricing = vehicle['pricing'];
                          final currency = (pricing is Map ? pricing['currency']?.toString() : null) ?? 'INR';
                          return '$currency $estimatedFare';
                        }
                        return _priceText(vehicle);
                      })(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    if (vehicle['numberPlate'] != null)
                      Text(
                        vehicle['numberPlate'].toString(),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  onPressed:
                      _bookingVehicleId == null
                          ? () => _showBookingConfirmationDialog(vehicle)
                          : null,
                  child:
                      isBookingThisVehicle
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            'Book Now',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleImage(String imageUrl) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child:
          imageUrl.isEmpty
              ? Icon(
                Icons.directions_car_filled_outlined,
                color: _primaryGreen,
                size: 34,
              )
              : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => Icon(
                      Icons.directions_car_filled_outlined,
                      color: _primaryGreen,
                      size: 34,
                    ),
              ),
    );
  }

  Widget _buildInfoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: _primaryGreen.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _primaryGreen, size: 13),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
