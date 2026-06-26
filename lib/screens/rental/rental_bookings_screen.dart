import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:rideal/authservices.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rideal/screens/wallet/wallet.dart';

class RentalBookingsScreen extends StatefulWidget {
  const RentalBookingsScreen({super.key});

  @override
  State<RentalBookingsScreen> createState() => _RentalBookingsScreenState();
}

class _RentalBookingsScreenState extends State<RentalBookingsScreen> {
  static const Color _primaryGreen = Color(0xFF0F9D58);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Rental Bookings',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: _primaryGreen,
            labelColor: _primaryGreen,
            unselectedLabelColor: Colors.black54,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Pending'),
              Tab(text: 'Accepted'),
              Tab(text: 'Rejected'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            BookingListTab(status: null),
            BookingListTab(status: 'pending'),
            BookingListTab(status: 'accepted'),
            BookingListTab(status: 'rejected'),
            BookingListTab(status: 'cancelled'),
          ],
        ),
      ),
    );
  }
}

class BookingListTab extends StatefulWidget {
  final String? status;
  const BookingListTab({super.key, this.status});

  @override
  State<BookingListTab> createState() => _BookingListTabState();
}

class _BookingListTabState extends State<BookingListTab> {
  static const Color _primaryGreen = Color(0xFF0F9D58);
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _bookings = [];

  bool _isPaying = false;
  Map<String, dynamic>? _currentBookingToPay;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchBookings() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await Authservices.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      String urlStr = '${Authservices.baseUrl}/api/vehicle-bookings/my';
      if (widget.status != null) {
        urlStr += '?status=${widget.status}';
      }

      final response = await http.get(
        Uri.parse(urlStr),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final decoded = jsonDecode(response.body);
      final isSuccess = decoded is Map<String, dynamic> && decoded['success'] == true;

      if (response.statusCode != 200 || !isSuccess) {
        final message = decoded is Map<String, dynamic> ? decoded['message']?.toString() : null;
        throw Exception(message ?? 'Failed to load bookings');
      }

      List<dynamic> list = [];
      if (decoded['bookings'] is List) {
        list = decoded['bookings'];
      } else if (decoded['data'] is List) {
        list = decoded['data'];
      } else if (decoded['booking'] is List) {
        list = decoded['booking'];
      }

      if (!mounted) return;
      setState(() {
        _bookings = list.reversed.toList(); // Newest bookings first
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      final token = await Authservices.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      final response = await http.patch(
        Uri.parse('${Authservices.baseUrl}/api/vehicle-bookings/$bookingId/cancel'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'reason': 'Plans changed',
        }),
      );

      final decoded = jsonDecode(response.body);
      final isSuccess = decoded is Map<String, dynamic> && decoded['success'] == true;

      if ((response.statusCode != 200 && response.statusCode != 201) || !isSuccess) {
        final message = decoded is Map<String, dynamic> ? decoded['message']?.toString() : null;
        throw Exception(message ?? 'Failed to cancel booking');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cancel Successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _primaryGreen,
        ),
      );

      _fetchBookings(); // Refresh the list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  void _confirmCancelBooking(String bookingId, String modelName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Confirm Cancellation',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: Text(
            'Are you sure you want to cancel booking for $modelName?',
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black54,
            ),
          ),
          actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'No',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _cancelBooking(bookingId);
              },
              child: const Text(
                'Yes, Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  String _formatAmount(dynamic value) {
    if (value == null) return '0';
    final parsed = double.tryParse(value.toString());
    if (parsed == null) return value.toString();
    if (parsed == parsed.roundToDouble()) {
      return parsed.round().toString();
    }
    return parsed.toStringAsFixed(2);
  }

  void _showPaymentConfirmationDialog(Map<String, dynamic> booking) {
    final vehicleMap = booking['vehicleId'] is Map 
        ? booking['vehicleId'] 
        : (booking['vehicle'] is Map ? booking['vehicle'] : null);

    String modelName = 'Rental Vehicle';
    if (vehicleMap != null) {
      modelName = vehicleMap['model']?.toString() ?? vehicleMap['name']?.toString() ?? 'Rental Vehicle';
    } else if (booking['vehicleModel'] != null) {
      modelName = booking['vehicleModel'].toString();
    }

    double securityDeposit = 0.0;
    if (booking['securityDepositAmount'] != null) {
      securityDeposit = _toDouble(booking['securityDepositAmount']);
    } else if (booking['securityDeposit'] != null) {
      securityDeposit = _toDouble(booking['securityDeposit']);
    } else if (vehicleMap != null && vehicleMap['pricing'] is Map) {
      securityDeposit = _toDouble(vehicleMap['pricing']['securityDeposit']);
    }

    double vehicleFare = 0.0;
    if (booking['estimatedFare'] != null) {
      vehicleFare = _toDouble(booking['estimatedFare']);
    } else if (booking['fare'] != null) {
      vehicleFare = _toDouble(booking['fare']);
    } else if (booking['price'] != null) {
      vehicleFare = _toDouble(booking['price']);
    } else if (booking['totalAmount'] != null) {
      vehicleFare = _toDouble(booking['totalAmount']);
    } else if (vehicleMap != null && vehicleMap['pricing'] is Map) {
      final pricing = vehicleMap['pricing'];
      final rate = pricing['dailyRate'] ?? pricing['hourlyRate'] ?? pricing['price'];
      if (rate != null) {
        vehicleFare = _toDouble(rate);
      }
    }

    double advanceAmount = 0.0;
    if (booking['advanceAmount'] != null && _toDouble(booking['advanceAmount']) > 0) {
      advanceAmount = _toDouble(booking['advanceAmount']);
    } else {
      advanceAmount = vehicleFare + securityDeposit;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.payment_outlined,
                  color: _primaryGreen,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Payment Confirmation',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Confirm your advance payment for $modelName',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Vehicle Rent:',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '₹${_formatAmount(vehicleFare)}',
                          style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Security Deposit:',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '₹${_formatAmount(securityDeposit)}',
                          style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Payable:',
                          style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₹${_formatAmount(advanceAmount)}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: _primaryGreen,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.only(right: 16, bottom: 16, left: 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _payBooking(booking);
                    },
                    child: const Text(
                      'Confirm Pay',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _payBooking(Map<String, dynamic> booking) async {
    final bookingId = booking['_id']?.toString() ?? booking['id']?.toString() ?? '';
    if (bookingId.isEmpty) return;

    setState(() {
      _isPaying = true;
      _currentBookingToPay = booking;
    });

    try {
      final token = await Authservices.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      // Initiate advance payment from wallet
      final response = await http.post(
        Uri.parse('${Authservices.baseUrl}/api/vehicle-bookings/$bookingId/initiate-advance-payment'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'paymentMethod': 'wallet',
        }),
      );

      final decoded = jsonDecode(response.body);
      final isSuccess = decoded is Map<String, dynamic> && decoded['success'] == true;

      if ((response.statusCode != 200 && response.statusCode != 201) || !isSuccess) {
        final message = decoded is Map<String, dynamic> ? decoded['message']?.toString() : null;
        throw Exception(message ?? 'Failed to complete advance payment');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Advance Payment completed successfully using Wallet!'),
            backgroundColor: _primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      _fetchBookings(); // Refresh the list
    } catch (e) {
      if (mounted) {
        final errStr = e.toString().replaceFirst('Exception: ', '');
        if (errStr.toLowerCase().contains('insufficient')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$errStr. Redirecting to Wallet...'),
              backgroundColor: Colors.amber.shade900,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 2000));
          if (mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Wallet()),
            );
            _fetchBookings(); // Refresh bookings on return
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errStr),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPaying = false;
          _currentBookingToPay = null;
        });
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '--';
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String statusText = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'pending':
        bgColor = Colors.amber.shade50;
        textColor = Colors.amber.shade800;
        break;
      case 'accepted':
      case 'confirmed':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        statusText = 'ACCEPTED';
        break;
      case 'rejected':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
        break;
      case 'cancelled':
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade600;
        break;
      default:
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _primaryGreen,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _fetchBookings,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No bookings found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.status != null
                  ? 'You don\'t have any ${widget.status} rental bookings.'
                  : 'You haven\'t made any rental bookings yet.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _primaryGreen,
      onRefresh: _fetchBookings,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _bookings.length,
        itemBuilder: (context, index) {
          final booking = _bookings[index];
          final bookingId = booking['_id']?.toString() ?? booking['id']?.toString() ?? '';
          final status = booking['status']?.toString() ?? 'pending';
          final bookingType = booking['bookingType']?.toString() ?? 'Daily';

          // Extract model / vehicle name safely
          String modelName = 'Rental Vehicle';
          if (booking['vehicle'] is Map) {
            modelName = booking['vehicle']['model']?.toString() ?? booking['vehicle']['name']?.toString() ?? 'Rental Vehicle';
          } else if (booking['vehicleModel'] != null) {
            modelName = booking['vehicleModel'].toString();
          }

          // Extract fare/amount safely
          String? fareText;
          final pricing = booking['pricing'];
          final totalAmount = booking['totalAmount'] ?? booking['fare'] ?? booking['price'];
          if (totalAmount != null) {
            fareText = 'Rs $totalAmount';
          } else if (pricing is Map) {
            final rate = pricing['dailyRate'] ?? pricing['hourlyRate'] ?? pricing['price'];
            if (rate != null) {
              fareText = 'Rs $rate';
            }
          }

          final canCancel = status.toLowerCase() == 'pending' || status.toLowerCase() == 'accepted' || status.toLowerCase() == 'confirmed' || status.toLowerCase() == 'awaiting_payment';

          return Card(
            elevation: 1.5,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade100, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        modelName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      _buildStatusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.circle_notifications_outlined, size: 16, color: _primaryGreen),
                      const SizedBox(width: 8),
                      Text(
                        'Booking: ${bookingType.toUpperCase()}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'From: ${_formatDate(booking['startDate'])}',
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'To: ${_formatDate(booking['endDate'])}',
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  if (fareText != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Fare:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
                        ),
                        Text(
                          fareText,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if ((status.toLowerCase() == 'accepted' || status.toLowerCase() == 'confirmed' || status.toLowerCase() == 'awaiting_payment') && booking['advancePaid'] == true && booking['startOtp'] != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Start OTP:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            booking['startOtp'].toString(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if ((status.toLowerCase() == 'accepted' || status.toLowerCase() == 'confirmed' || status.toLowerCase() == 'awaiting_payment') && booking['advancePaid'] != true) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Payment Status:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
                        ),
                        Text(
                          'Unpaid (Advance Required)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (status.toLowerCase() == 'ongoing' && booking['endOtp'] != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'End OTP:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            booking['endOtp'].toString(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (canCancel) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Builder(
                        builder: (context) {
                          // Extract location safely
                          final ownerId = booking['ownerId'];
                          final location = ownerId is Map ? ownerId['location'] : null;
                          final lat = location is Map ? location['lat'] : null;
                          final lng = location is Map ? location['lng'] : null;

                          final isAccepted = status.toLowerCase() == 'accepted' || status.toLowerCase() == 'confirmed' || status.toLowerCase() == 'awaiting_payment';
                          final advancePaid = booking['advancePaid'] == true;

                          if (isAccepted) {
                            if (!advancePaid) {
                              final isCurrentPaying = _isPaying && _currentBookingToPay != null && 
                                  (_currentBookingToPay!['_id']?.toString() == bookingId || _currentBookingToPay!['id']?.toString() == bookingId);
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _confirmCancelBooking(bookingId, modelName),
                                    icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
                                    label: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber.shade700,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onPressed: _isPaying ? null : () => _showPaymentConfirmationDialog(booking),
                                    icon: isCurrentPaying
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.payment_outlined, size: 16),
                                    label: const Text(
                                      'Pay Advance',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _confirmCancelBooking(bookingId, modelName),
                                    icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
                                    label: const Text(
                                      'Cancel Booking',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  if (lat != null && lng != null) ...[
                                    const SizedBox(width: 12),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _primaryGreen,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      onPressed: () async {
                                        final googleMapsUrl = Uri.parse(
                                          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving'
                                        );
                                        try {
                                          if (await canLaunchUrl(googleMapsUrl)) {
                                            await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Could not open map navigation')),
                                            );
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error opening maps: $e')),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.navigation_outlined, size: 16),
                                      label: const Text(
                                        'Navigate',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            }
                          }

                          return TextButton.icon(
                            onPressed: () => _confirmCancelBooking(bookingId, modelName),
                            icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
                            label: const Text(
                              'Cancel Booking',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
