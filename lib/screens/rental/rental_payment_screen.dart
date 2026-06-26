import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:rideal/authservices.dart';
import 'package:rideal/screens/dashboard/BottomNavigation.dart';

class RentalPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  final String bookingType;
  final DateTime startDate;
  final DateTime endDate;

  const RentalPaymentScreen({
    super.key,
    required this.vehicle,
    required this.bookingType,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<RentalPaymentScreen> createState() => _RentalPaymentScreenState();
}

class _RentalPaymentScreenState extends State<RentalPaymentScreen> {
  static const Color _primaryGreen = Color(0xFF0F9D58);
  static const String _baseUrl = Authservices.baseUrl;
  double _depositAmount = 1000.0;

  final ImagePicker _picker = ImagePicker();

  File? _aadharFrontImage;
  File? _aadharBackImage;
  File? _driverLicenseImage;
  bool _isProcessing = false;
  bool _isUploading = false;
  double _vehiclePrice = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeDepositAmount();
    _calculateVehiclePrice();
  }

  void _initializeDepositAmount() {
    final pricing = widget.vehicle['pricing'];
    if (pricing is Map) {
      final deposit = pricing['securityDeposit'] ?? pricing['deposit'];
      if (deposit != null) {
        _depositAmount = double.tryParse(deposit.toString()) ?? 1000.0;
      }
    }
  }


  void _calculateVehiclePrice() {
    final calculatedFareInfo = widget.vehicle['calculatedFareInfo'];
    final estimatedFare = calculatedFareInfo != null ? calculatedFareInfo['estimatedFare'] : null;

    if (estimatedFare != null) {
      _vehiclePrice = double.tryParse(estimatedFare.toString()) ?? 0.0;
      return;
    }

    final pricing = widget.vehicle['pricing'];
    if (pricing is! Map) {
      _vehiclePrice = 0.0;
      return;
    }

    final key = widget.bookingType.toLowerCase() == 'hourly' ? 'hourlyRate' : 'dailyRate';
    final rateVal = pricing[key] ?? pricing['dailyRate'] ?? pricing['hourlyRate'];
    
    if (rateVal != null) {
      final rate = double.tryParse(rateVal.toString()) ?? 0.0;
      final duration = widget.endDate.difference(widget.startDate);
      if (widget.bookingType.toLowerCase() == 'hourly') {
        final hours = (duration.inMinutes / 60.0).ceil();
        _vehiclePrice = rate * hours;
      } else {
        final days = (duration.inHours / 24.0).ceil();
        _vehiclePrice = rate * (days > 0 ? days : 1);
      }
    }
  }

  double get _totalAmount => _depositAmount + _vehiclePrice;

  Future<void> _pickImage(String imageType) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          if (imageType == 'aadharFront') {
            _aadharFrontImage = File(image.path);
          } else if (imageType == 'aadharBack') {
            _aadharBackImage = File(image.path);
          } else if (imageType == 'driverLicense') {
            _driverLicenseImage = File(image.path);
          }
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _captureImage(String imageType) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          if (imageType == 'aadharFront') {
            _aadharFrontImage = File(image.path);
          } else if (imageType == 'aadharBack') {
            _aadharBackImage = File(image.path);
          } else if (imageType == 'driverLicense') {
            _driverLicenseImage = File(image.path);
          }
        });
      }
    } catch (e) {
      _showSnackBar('Failed to capture image: ${e.toString()}');
    }
  }

  void _showImageSourceDialog(String imageType) {
    String titleText = 'Select Image';
    if (imageType == 'aadharFront') {
      titleText = 'Select Front Aadhar';
    } else if (imageType == 'aadharBack') {
      titleText = 'Select Back Aadhar';
    } else if (imageType == 'driverLicense') {
      titleText = 'Select Driver License';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                titleText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library, color: _primaryGreen),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(imageType);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: _primaryGreen),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _captureImage(imageType);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  bool _validateForm() {
    if (_aadharFrontImage == null) {
      _showSnackBar('Please upload Aadhar front image');
      return false;
    }
    if (_aadharBackImage == null) {
      _showSnackBar('Please upload Aadhar back image');
      return false;
    }
    if (_driverLicenseImage == null) {
      _showSnackBar('Please upload Driver License');
      return false;
    }
    return true;
  }

  Future<void> _submitBooking() async {
    if (!_validateForm()) return;

    if (_isProcessing) return;

    // Show confirmation dialog
    final confirm = await _showConfirmationDialog();
    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      // Create booking
      final bookingData = await _createBooking();
      
      if (bookingData == null) {
        throw Exception('Failed to create booking');
      }

      // Upload KYC documents
      await _uploadKycDocuments();

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<bool?> _showConfirmationDialog() async {
    return showDialog<bool>(
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
          content: const Text(
            'Are you sure you want to submit your booking request?',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
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
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Submit',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadKycDocuments() async {
    setState(() => _isUploading = true);

    try {
      final token = await Authservices.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://backend.ridealmobility.com/auth/kyc'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      if (_aadharFrontImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'aadharFront',
            _aadharFrontImage!.path,
          ),
        );
      }

      if (_aadharBackImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'aadharBack',
            _aadharBackImage!.path,
          ),
        );
      }

      if (_driverLicenseImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'drivingLicense',
            _driverLicenseImage!.path,
          ),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      dynamic decoded;
      try {
        decoded = jsonDecode(responseBody);
      } catch (_) {}

      if (response.statusCode != 200 && response.statusCode != 201) {
        final message = decoded is Map<String, dynamic> ? decoded['message']?.toString() : null;
        throw Exception(message ?? 'Failed to upload KYC documents');
      }

      if (!mounted) return;
      setState(() => _isUploading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      throw Exception('KYC upload failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>?> _createBooking() async {
    try {
      final token = await Authservices.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      final vehicleId = widget.vehicle['_id']?.toString() ?? widget.vehicle['id']?.toString();
      if (vehicleId == null || vehicleId.isEmpty) {
        throw Exception('Vehicle ID not found');
      }

      final response = await http.post(
        Uri.parse('https://backend.ridealmobility.com/api/vehicle-bookings/request'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'vehicleId': vehicleId,
          'bookingType': widget.bookingType.toLowerCase(),
          'startDate': widget.startDate.toUtc().toIso8601String(),
          'endDate': widget.endDate.toUtc().toIso8601String(),
          'riderNote': 'Looking forward to the trip!',
        }),
      );

      final decoded = jsonDecode(response.body);
      final isSuccess = decoded is Map<String, dynamic> && decoded['success'] == true;

      if ((response.statusCode != 200 && response.statusCode != 201) || !isSuccess) {
        final message = decoded is Map<String, dynamic> ? decoded['message']?.toString() : null;
        throw Exception(message ?? 'Failed to create booking');
      }

      return decoded;
    } catch (e) {
      throw Exception('Booking failed: ${e.toString()}');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: _primaryGreen,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Booking Successful!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your rental booking request has been submitted.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BottomNavigationLogic(),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
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

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicleModel = widget.vehicle['model']?.toString() ?? 'Rental Vehicle';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Complete Booking',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Info Card
            _buildVehicleInfoCard(vehicleModel),
            const SizedBox(height: 24),

            // Aadhar Upload Section
            const Text(
              'Upload Aadhar Card',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Required for verification',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),

            // Aadhar Front
            _buildImageUploadCard(
              title: 'Aadhar Front',
              image: _aadharFrontImage,
              onTap: () => _showImageSourceDialog('aadharFront'),
            ),
            const SizedBox(height: 16),

            // Aadhar Back
            _buildImageUploadCard(
              title: 'Aadhar Back',
              image: _aadharBackImage,
              onTap: () => _showImageSourceDialog('aadharBack'),
            ),
            const SizedBox(height: 24),

            // Driver License Upload Section
            const Text(
              'Upload Driver License',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Required for rental approval',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),

            // Driver License
            _buildImageUploadCard(
              title: 'Driver License',
              image: _driverLicenseImage,
              onTap: () => _showImageSourceDialog('driverLicense'),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                onPressed: _isProcessing || _isUploading ? null : _submitBooking,
                child: _isProcessing || _isUploading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit Booking',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleInfoCard(String vehicleModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_car,
              color: _primaryGreen,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicleModel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.bookingType} Rental',
                  style: TextStyle(
                    fontSize: 13,
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

  Widget _buildImageUploadCard({
    required String title,
    required File? image,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: image != null ? _primaryGreen : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    Image.file(
                      image,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: _primaryGreen,
                          size: 20,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                        ),
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to upload',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

}
