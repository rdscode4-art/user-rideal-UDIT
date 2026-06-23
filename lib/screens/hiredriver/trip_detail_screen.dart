import 'package:flutter_screenutil/flutter_screenutil.dart';
// Save this file as: lib/screens/hiredriver/trip_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:intl/intl.dart';

class TripDetailScreen extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic> tripData;

  const TripDetailScreen({
    super.key,
    required this.rideId,
    required this.tripData,
  });

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  String status = 'PENDING';
  bool isLoading = true;
  String? errorMessage;
  Timer? _statusCheckTimer;
  Map<String, dynamic>? rideDetails;
  String? initialOtp; // Store OTP from initial booking
  @override
  void initState() {
    super.initState();
    rideDetails = widget.tripData;
    status = widget.tripData['status']?.toString().toUpperCase() ?? 'PENDING';
    
    // Store OTP from initial data if it exists
    initialOtp = widget.tripData['otp']?.toString();
    
    _fetchRideStatus();
    // Auto-refresh every 10 seconds
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchRideStatus();
    });
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRideStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token');

      final response = await http.get(
        Uri.parse('https://backend.ridealmobility.com/api/nonvehicle/ride/${widget.rideId}/status'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            // Handle different response structures
            if (data['ride'] != null) {
              rideDetails = data['ride'];
              status = (data['ride']['status'] ?? 'PENDING').toString().toUpperCase();
            } else if (data['hiredDrivers'] != null && data['hiredDrivers'].isNotEmpty) {
              // If response contains hiredDrivers array, find matching ride
              final matchingRide = (data['hiredDrivers'] as List).firstWhere(
                (ride) => ride['rideId'] == widget.rideId,
                orElse: () => null,
              );
              if (matchingRide != null) {
                rideDetails = matchingRide;
                status = (matchingRide['status'] ?? 'PENDING').toString().toUpperCase();
              }
            } else {
              // Response is the ride data itself
              rideDetails = data;
              status = (data['status'] ?? 'PENDING').toString().toUpperCase();
            }
            
            // Store OTP if it's in the response
            if (data['otp'] != null) {
              initialOtp = data['ride']['otp'].toString();
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

  String _formatDate(String dateString) {
  try {
    final date = DateTime.parse(dateString).toLocal(); // convert to local timezone
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  } catch (_) {
    return dateString;
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

      final response = await http.post(
        Uri.parse('https://backend.ridealmobility.com/api/nonvehicle/ride/cancel/${widget.rideId}'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Request cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
          await _fetchRideStatus();
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
    final driver = widget.tripData['driver'];
    final driverName = driver != null ? driver['name'] : 'Not Assigned';
    final driverPhone = driver != null ? driver['phone'] : 'N/A';
    final otp = rideDetails?['otp']?.toString() ?? 'N/A';
    final completionOtp = rideDetails?['completionOtp']?.toString() ?? 'N/A';
    final duration = widget.tripData['duration']?.toString() ?? 'N/A';
    final price = widget.tripData['price']?.toString() ?? 'N/A';
    final createdAt = widget.tripData['createdAt'] ?? '';
    final completedAt = widget.tripData['completedAt'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Trip Details'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchRideStatus,
          ),
        ],
      ),
      body: isLoading && rideDetails == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Card
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: _getStatusColor(status),
                          width: 2.w,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              _getStatusIcon(status),
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(status),
                                  ),
                                ),
                                SizedBox(height: 4.w),
                                Text(
                                  _getStatusMessage(status),
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.w),

                    // Ride Details
                    Text(
                      'Ride Details',
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
                            Icons.confirmation_number,
                            'Ride ID',
                            widget.rideId,
                          ),
                          Divider(height: 24.w),
                          _buildDetailRow(
                            Icons.lock,
                            'Acceptance OTP',
                            otp,
                          ),
                          Divider(height: 24.w),
                          _buildDetailRow(
                            Icons.lock_open,
                            'Completion OTP',
                            completionOtp,
                          ),
                          Divider(height: 24.w),
                          _buildDetailRow(
                            Icons.access_time,
                            'Duration',
                            duration,
                          ),
                          Divider(height: 24.w),
                          _buildDetailRow(
                            Icons.payment,
                            'Total Amount',
                            '₹$price',
                          ),
                          if (createdAt.isNotEmpty) ...[
                            Divider(height: 24.w),
                            _buildDetailRow(
                              Icons.calendar_today,
                              'Created At',
                              _formatDate(createdAt),
                            ),
                          ],
                          if (completedAt.isNotEmpty) ...[
                            Divider(height: 24.w),
                            _buildDetailRow(
                              Icons.check_circle,
                              'Completed At',
                              _formatDate(completedAt),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 24.w),

                    // Driver Details
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
                            driverName,
                          ),
                          Divider(height: 24.w),
                          _buildDetailRow(
                            Icons.phone,
                            'Phone',
                            driverPhone,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.w),

                    // Action Buttons - Only show cancel if status is PENDING
                    if (status.toUpperCase() == 'PENDING') ...[
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

                    // Back Button
                    SizedBox(
                      width: double.infinity,
                      height: 56.w,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back),
                        label: Text(
                          'Back to History',
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