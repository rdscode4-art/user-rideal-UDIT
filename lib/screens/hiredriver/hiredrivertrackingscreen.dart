// Save this file as: lib/screens/hiredriver/hiredrivertrackingscreen.dart
import 'package:flutter/material.dart';
import 'package:rideal/screens/dashboard/BottomNavigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

class HireDriverTrackingScreen extends StatefulWidget {
  final String requestId;
  final int hours;
  final double totalPrice;
  final String otp;

  const HireDriverTrackingScreen({
    super.key,
    required this.requestId,
    required this.hours,
    required this.totalPrice,
    required this.otp,
  });

  @override
  State<HireDriverTrackingScreen> createState() => _HireDriverTrackingScreenState();
}

class _HireDriverTrackingScreenState extends State<HireDriverTrackingScreen> {
  String status = 'PENDING';
  bool isLoading = true;
  String? errorMessage;
  Timer? _statusCheckTimer;
  Map<String, dynamic>? requestDetails;

  @override
  void initState() {
    super.initState();
    _fetchRequestStatus();
    // Auto-refresh every 10 seconds
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchRequestStatus();
    });
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRequestStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token');

      final url = 'https://backend.ridealmobility.com/api/nonvehicle/ride/${widget.requestId}/status';

      // Print CURL command for debugging
      print('🚀 FETCH STATUS API CALL:');
      print('curl -X GET "$url" \\');
      print('  -H "Content-Type: application/json" \\');
      if (token != null) print('  -H "Authorization: Bearer $token"');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('📥 FETCH STATUS RESPONSE: ${response.statusCode}');
      print('📥 BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            // Unwrap `ride` wrapper if present (new status endpoint structure)
            if (data['ride'] != null) {
              requestDetails = data['ride'];
              status = (data['ride']['status'] ?? 'PENDING').toString().toUpperCase();
            } else {
              requestDetails = data;
              status = (data['status'] ?? 'PENDING').toString().toUpperCase();
            }
            isLoading = false;
            errorMessage = null;
          });
        }
      } else {
        throw Exception('Failed to fetch status');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Unable to fetch status';
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'ACCEPTED':
      case 'ASSIGNED':
        return Colors.blue;
      case 'ONGOING':
      case 'STARTED':
        return Colors.green;
      case 'COMPLETED':
        return Colors.teal;
      case 'CANCELLED':
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Icons.hourglass_empty;
      case 'ACCEPTED':
      case 'ASSIGNED':
        return Icons.check_circle;
      case 'ONGOING':
      case 'STARTED':
        return Icons.drive_eta;
      case 'COMPLETED':
        return Icons.done_all;
      case 'CANCELLED':
      case 'REJECTED':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getStatusMessage(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Looking for available drivers...';
      case 'ACCEPTED':
      case 'ASSIGNED':
        return 'Driver assigned! They will contact you soon.';
      case 'ONGOING':
      case 'STARTED':
        return 'Your service is in progress.';
      case 'COMPLETED':
        return 'Service completed successfully!';
      case 'CANCELLED':
        return 'Request was cancelled.';
      case 'REJECTED':
        return 'Request was rejected.';
      default:
        return 'Status: $status';
    }
  }

  Future<void> _cancelRequest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text('Are you sure you want to cancel this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token');

      final url = 'https://backend.ridealmobility.com/api/nonvehicle/ride/cancel/${widget.requestId}';

      // Print CURL command for debugging
      print('🚀 CANCEL REQUEST API CALL:');
      print('curl -X POST "$url" \\');
      print('  -H "Content-Type: application/json" \\');
      if (token != null) print('  -H "Authorization: Bearer $token"');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('📥 CANCEL REQUEST RESPONSE: ${response.statusCode}');
      print('📥 BODY: ${response.body}');

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Request cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh the status after cancellation
          await _fetchRequestStatus();
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to cancel');
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Status'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRequestStatus,
          ),
        ],
      ),
      body: isLoading && requestDetails == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Success Animation
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          size: 80,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Request Created Message
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'Request Created Successfully!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Request ID: ${widget.requestId}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Current Status Card
                    // Container(
                    //   padding: const EdgeInsets.all(20),
                    //   decoration: BoxDecoration(
                    //     color: _getStatusColor(status).withOpacity(0.1),
                    //     borderRadius: BorderRadius.circular(16),
                    //     border: Border.all(
                    //       color: _getStatusColor(status),
                    //       width: 2,
                    //     ),
                    //   ),
                    //   child: Row(
                    //     children: [
                    //       Container(
                    //         padding: const EdgeInsets.all(12),
                    //         decoration: BoxDecoration(
                    //           color: _getStatusColor(status),
                    //           borderRadius: BorderRadius.circular(12),
                    //         ),
                    //         child: Icon(
                    //           _getStatusIcon(status),
                    //           color: Colors.white,
                    //           size: 32,
                    //         ),
                    //       ),
                    //       const SizedBox(width: 16),
                    //       Expanded(
                    //         child: Column(
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //             Text(
                    //               status.toUpperCase(),
                    //               style: TextStyle(
                    //                 fontSize: 18,
                    //                 fontWeight: FontWeight.bold,
                    //                 color: _getStatusColor(status),
                    //               ),
                    //             ),
                    //             const SizedBox(height: 4),
                    //             Text(
                    //               _getStatusMessage(status),
                    //               style: TextStyle(
                    //                 fontSize: 14,
                    //                 color: Colors.grey.shade700,
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    // const SizedBox(height: 24),

                    // Booking Details
                    const Text(
                      'Booking Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            Icons.lock,
                            'Acceptance OTP',
                            widget.otp,
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(
                            Icons.lock_open,
                            'Completion OTP',
                            requestDetails?['completionOtp']?.toString() ?? 'N/A',
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(
                            Icons.access_time,
                            'Duration',
                            '${widget.hours} hours',
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(
                            Icons.payment,
                            'Total Amount',
                            '₹${widget.totalPrice.toStringAsFixed(0)}',
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(
                            Icons.confirmation_number,
                            'Request ID',
                            widget.requestId,
                          ),
                          if (requestDetails?['createdAt'] != null) ...[
                            const Divider(height: 24),
                            _buildDetailRow(
                              Icons.calendar_today,
                              'Created At',
                              requestDetails!['createdAt'].toString(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Driver Details (if assigned)
                    if (requestDetails?['driver'] != null) ...[
                      const Text(
                        'Driver Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              Icons.person,
                              'Name',
                              requestDetails!['driver']['name'] ?? 'N/A',
                            ),
                            if (requestDetails!['driver']['phone'] != null) ...[
                              const Divider(height: 24),
                              _buildDetailRow(
                                Icons.phone,
                                'Phone',
                                requestDetails!['driver']['phone'],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Action Buttons - Only show cancel if status is PENDING
                    if (status.toUpperCase() == 'PENDING') ...[
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _cancelRequest,
                          icon: const Icon(Icons.cancel),
                          label: const Text(
                            'Cancel Request',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Back to Home Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => BottomNavigationLogic()),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.home),
                        label: const Text(
                          'Back to Home',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.green, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}