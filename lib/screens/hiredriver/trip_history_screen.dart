import 'package:flutter_screenutil/flutter_screenutil.dart';
// Save this file as: lib/screens/hiredriver/trip_history_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:rideal/screens/hiredriver/trip_detail_screen.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> trips = [];

  @override
  void initState() {
    super.initState();
    _fetchTripHistory();
  }

  Future<void> _fetchTripHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token');

      final url = 'https://backend.ridealmobility.com/api/nonvehicle/ride/user/hired-drivers';
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      // Logging Request
      print('🚀 FETCH HIRED DRIVERS HISTORY:');
      print('curl -X GET "$url" \\');
      headers.forEach((key, value) => print('  -H "$key: $value" \\'));

      final response = await http.get(Uri.parse(url), headers: headers);

      // Logging Response
      print('📥 RESPONSE STATUS: ${response.statusCode}');
      print('📥 RESPONSE BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            trips = data['hiredDrivers'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'Failed to load trip history';
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to fetch data');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
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

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'STARTED':
      case 'ONGOING':
        return Colors.orange;
      case 'PENDING':
        return Colors.blue;
      case 'ACCEPTED':
      case 'ASSIGNED':
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }

  Future<String> _fetchRideStatus(String rideId, String token) async {
    try {
      final url = 'https://backend.ridealmobility.com/api/nonvehicle/ride/$rideId/status';
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Logging Individual Status Request
      print('🔍 FETCH RIDE STATUS ($rideId):');
      print('curl -X GET "$url" \\');
      headers.forEach((key, value) => print('  -H "$key: $value" \\'));

      final res = await http.get(Uri.parse(url), headers: headers);

      // Logging Response
      print('📥 STATUS RESPONSE ($rideId): ${res.statusCode}');
      print('📥 BODY: ${res.body}');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final status = body['ride']?['status']?.toString() ?? 'UNKNOWN';
        return status.toUpperCase();
      } else {
        return 'UNKNOWN';
      }
    } catch (_) {
      return 'UNKNOWN';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trip History'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              _fetchTripHistory();
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      SizedBox(height: 16.w),
                      Text(
                        errorMessage!,
                        style: TextStyle(fontSize: 16.sp),
                      ),
                      SizedBox(height: 16.w),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });
                          _fetchTripHistory();
                        },
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : trips.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey),
                          SizedBox(height: 16.w),
                          Text(
                            'No trip history available',
                            style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16.w),
                      itemCount: trips.length,
                      itemBuilder: (context, index) {
                        final trip = trips[index];
                        final driver = trip['driver'];
                        final driverName = driver != null ? driver['name'] : 'Unassigned';
                        final driverPhone = driver != null ? driver['phone'] : 'N/A';
                        final createdAt = trip['createdAt'] ?? '';

                        return FutureBuilder<String>(
                          future: SharedPreferences.getInstance().then((prefs) {
                            final token = prefs.getString('auth_token') ?? 
                                         prefs.getString('token') ?? '';
                            return _fetchRideStatus(trip['rideId'], token);
                          }),
                          builder: (context, snapshot) {
                            final status = snapshot.data ?? 'LOADING...';
                            
                            return Card(
                              margin: EdgeInsets.only(bottom: 12.w),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              elevation: 3,
                              child: InkWell(
                                onTap: () {
                                  // Navigate to detail screen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TripDetailScreen(
                                        rideId: trip['rideId'],
                                        tripData: trip,
                                      ),
                                    ),
                                  ).then((_) {
                                    // Refresh the list when coming back
                                    setState(() {
                                      isLoading = true;
                                    });
                                    _fetchTripHistory();
                                  });
                                },
                                borderRadius: BorderRadius.circular(12.r),
                                child: Padding(
                                  padding: EdgeInsets.all(16.w),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.drive_eta,
                                                  color: Colors.green,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 8.w),
                                                Flexible(
                                                  child: Text(
                                                    'Ride ID: ${trip['rideId']}',
                                                    style: TextStyle(
                                                      fontSize: 14.sp,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8.w,
                                              vertical: 4.w,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(status).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8.r),
                                              border: Border.all(
                                                color: _getStatusColor(status),
                                              ),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                color: _getStatusColor(status),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12.sp,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12.w),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person,
                                            size: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                          SizedBox(width: 8.w),
                                          Text(
                                            'Driver: $driverName',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 6.w),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.phone,
                                            size: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                          SizedBox(width: 8.w),
                                          Text(
                                            'Phone: $driverPhone',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 6.w),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                          SizedBox(width: 8.w),
                                          Text(
                                            'Duration: ${trip['duration']}',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 6.w),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.payment,
                                                size: 16,
                                                color: Colors.green,
                                              ),
                                              SizedBox(width: 8.w),
                                              Text(
                                                '₹${trip['price']}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16.sp,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (createdAt.isNotEmpty)
                                            Text(
                                              _formatDate(createdAt),
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 8.w),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Tap for details',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: Colors.green.shade700,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                          SizedBox(width: 4.w),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 12,
                                            color: Colors.green.shade700,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
    );
  }
}