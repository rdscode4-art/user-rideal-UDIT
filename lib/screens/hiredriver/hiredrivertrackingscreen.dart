import 'package:flutter_screenutil/flutter_screenutil.dart';
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
        title: Text('Cancel Request'),
        content: Text('Are you sure you want to cancel this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Yes', style: TextStyle(color: Colors.red)),
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
        title: Text('Request Status'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchRequestStatus,
          ),
        ],
      ),
      body: isLoading && requestDetails == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Success Animation
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(24.w),
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
                    SizedBox(height: 24.w),

                    // Request Created Message
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Request Created Successfully!',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8.w),
                          Text(
                            'Request ID: ${widget.requestId}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32.w),

                    // Current Status Card
                    // Container(
                    //   padding: EdgeInsets.all(20.w),
                    //   decoration: BoxDecoration(
                    //     color: _getStatusColor(status).withOpacity(0.1),
                    //     borderRadius: BorderRadius.circular(16.r),
                    //     border: Border.all(
                    //       color: _getStatusColor(status),
                    //       width: 2.w,
                    //     ),
                    //   ),
                    //   child: Row(
                    //     children: [
                    //       Container(
                    //         padding: EdgeInsets.all(12.w),
                    //         decoration: BoxDecoration(
                    //           color: _getStatusColor(status),
                    //           borderRadius: BorderRadius.circular(12.r),
                    //         ),
                    //         child: Icon(
                    //           _getStatusIcon(status),
                    //           color: Colors.white,
                    //           size: 32,
                    //         ),
                    //       ),
                    //       SizedBox(width: 16.w),
                    //       Expanded(
                    //         child: Column(
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //             Text(
                    //               status.toUpperCase(),
                    //               style: TextStyle(
                    //                 fontSize: 18.sp,
                    //                 fontWeight: FontWeight.bold,
                    //                 color: _getStatusColor(status),
                    //               ),
                    //             ),
                    //             SizedBox(height: 4.w),
                    //             Text(
                    //               _getStatusMessage(status),
                    //               style: TextStyle(
                    //                 fontSize: 14.sp,
                    //                 color: Colors.grey.shade700,
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    // SizedBox(height: 24.w),

                    // Booking Details
                    Text(
                      'Booking Details',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.w),
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            Icons.lock,
                            'Acceptance OTP',
                            widget.otp,
                          ),
                          Divider(height: 24.w),
                          _buildDetailRow(
                            Icons.lock_open,
                            'Completion OTP',
                            requestDetails?['completionOtp']?.toString() ?? 'N/A',
                          ),
                          Divider(height: 24.w),
                          _buildDetailRow(
                            Icons.access_time,
                            'Duration',
                            '${widget.hours} hours',
                          ),
                          Divider(height: 24.w),
                          _buildDetailRow(
                            Icons.payment,
                            'Total Amount',
                            '₹${widget.totalPrice.toStringAsFixed(0)}',
                          ),
                          Divider(height: 24.w),
                          _buildDetailRow(
                            Icons.confirmation_number,
                            'Request ID',
                            widget.requestId,
                          ),
                          if (requestDetails?['createdAt'] != null) ...[
                            Divider(height: 24.w),
                            _buildDetailRow(
                              Icons.calendar_today,
                              'Created At',
                              requestDetails!['createdAt'].toString(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 24.w),

                    // Driver Details (if assigned)
                    if (requestDetails?['driver'] != null) ...[
                      Text(
                        'Driver Details',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12.w),
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12.r),
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
                              Divider(height: 24.w),
                              _buildDetailRow(
                                Icons.phone,
                                'Phone',
                                requestDetails!['driver']['phone'],
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 24.w),
                    ],

                    // Action Buttons - Show cancel if status is PENDING, ACCEPTED, or ASSIGNED
                    if (status.toUpperCase() == 'PENDING' || status.toUpperCase() == 'ACCEPTED' || status.toUpperCase() == 'ASSIGNED') ...[
                      SizedBox(
                        width: double.infinity,
                        height: 56.w,
                        child: ElevatedButton.icon(
                          onPressed: _cancelRequest,
                          icon: Icon(Icons.cancel),
                          label: Text(
                            'Cancel Request',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.w),
                    ],
                    
                    // Back to Home Button
                    SizedBox(
                      width: double.infinity,
                      height: 56.w,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => BottomNavigationLogic()),
                            (route) => false,
                          );
                        },
                        icon: Icon(Icons.home),
                        label: Text(
                          'Back to Home',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: BorderSide(color: Colors.green, width: 2.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.w),
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
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 2.w),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16.sp,
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