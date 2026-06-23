import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class GoodsTransportHistoryScreen extends StatefulWidget {
  const GoodsTransportHistoryScreen({super.key});

  @override
  State<GoodsTransportHistoryScreen> createState() => _GoodsTransportHistoryScreenState();
}

class _GoodsTransportHistoryScreenState extends State<GoodsTransportHistoryScreen> {
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = prefs.getStringList('goods_transport_history') ?? [];
      
      final List<Map<String, dynamic>> parsedList = list
          .map((item) => jsonDecode(item) as Map<String, dynamic>)
          .toList();

      // Sort bookings to show the newest first
      parsedList.sort((a, b) {
        final aTime = DateTime.tryParse(a['bookingTime'] ?? '') ?? DateTime.now();
        final bTime = DateTime.tryParse(b['bookingTime'] ?? '') ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      setState(() {
        _bookings = parsedList;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading history: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10.w),
            Text("Clear History"),
          ],
        ),
        content: Text("Are you sure you want to clear all your booking history? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text("Clear All"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('goods_transport_history');
        setState(() {
          _bookings = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🗑️ Booking history cleared successfully"),
            backgroundColor: Colors.black87,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        print("Error clearing history: $e");
      }
    }
  }

  Future<void> _cancelBooking(int index, Map<String, dynamic> booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text("Cancel Scheduled Ride"),
        content: Text("Are you sure you want to cancel your scheduled booking for ${booking['vehicle']}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("No", style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text("Cancel Ride"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final List<String> list = prefs.getStringList('goods_transport_history') ?? [];
        
        // Find the index in the original list based on booking ID
        final targetId = booking['id'];
        int originalIndex = -1;
        for (int i = 0; i < list.length; i++) {
          final parsed = jsonDecode(list[i]) as Map<String, dynamic>;
          if (parsed['id'] == targetId) {
            originalIndex = i;
            break;
          }
        }

        if (originalIndex != -1) {
          final parsed = jsonDecode(list[originalIndex]) as Map<String, dynamic>;
          parsed['status'] = 'Cancelled';
          list[originalIndex] = jsonEncode(parsed);
          await prefs.setStringList('goods_transport_history', list);
          
          _loadHistory(); // Reload from storage
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("❌ Scheduled ride cancelled successfully"),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        print("Error cancelling booking: $e");
      }
    }
  }

  String _formatBookingTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (e) {
      return isoString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green.shade700;
      case 'Scheduled':
        return Colors.orange.shade700;
      case 'Cancelled':
        return Colors.red.shade700;
      default:
        return Colors.blue.shade700;
    }
  }

  Color _getStatusBg(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green.shade50;
      case 'Scheduled':
        return Colors.orange.shade50;
      case 'Cancelled':
        return Colors.red.shade50;
      default:
        return Colors.blue.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade600, Colors.green.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Booking History',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22.sp,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_bookings.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep, color: Colors.white),
              tooltip: "Clear All History",
              onPressed: _clearHistory,
            ),
        ],
        elevation: 4,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.green))
          : _bookings.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: _bookings.length,
                  itemBuilder: (context, index) {
                    final booking = _bookings[index];
                    final status = booking['status'] ?? 'Completed';
                    final isScheduled = booking['isScheduled'] ?? false;
                    final price = booking['price'] ?? 0;

                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 16.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.all(16.0.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Vehicle info and ID and Status badge
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10.w),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    booking['vehicleIcon'] ?? '🚚',
                                    style: TextStyle(fontSize: 22.sp),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        booking['vehicle'] ?? 'Goods Carrier',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16.sp,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 2.w),
                                      Text(
                                        "ID: ${booking['id'] ?? 'N/A'}",
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.w),
                                  decoration: BoxDecoration(
                                    color: _getStatusBg(status),
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(
                                      color: _getStatusColor(status).withOpacity(0.3),
                                      width: 1.w,
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
                            Divider(height: 24.w),

                            // Details: Pickup & Dropoff timeline
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    Icon(Icons.radio_button_checked, color: Colors.green, size: 18),
                                    Container(
                                      width: 2.w,
                                      height: 35.w,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(1.r),
                                      ),
                                    ),
                                    Icon(Icons.location_on, color: Colors.red, size: 18),
                                  ],
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        booking['pickup'] ?? 'Pickup location',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 28.w),
                                      Text(
                                        booking['drop'] ?? 'Dropoff location',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Divider(height: 24.w),

                            // Footer details: Date and Price
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Booked on:",
                                      style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500),
                                    ),
                                    SizedBox(height: 2.w),
                                    Text(
                                      _formatBookingTime(booking['bookingTime'] ?? ''),
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "Fare (${booking['distance'] != null ? '${(booking['distance'] as double).toStringAsFixed(1)} KM' : 'N/A'}):",
                                      style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500),
                                    ),
                                    SizedBox(height: 2.w),
                                    Text(
                                      "₹$price",
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // If scheduled, show target schedule date & time
                            if (isScheduled && booking['scheduledDate'] != null && booking['scheduledTime'] != null) ...[
                              SizedBox(height: 12.w),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.w),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(color: Colors.orange.shade100),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.schedule, color: Colors.orange.shade700, size: 18),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(fontSize: 13.sp, color: Colors.black87),
                                          children: [
                                            TextSpan(text: "Scheduled for: "),
                                            TextSpan(
                                              text: "${booking['scheduledDate']} at ${booking['scheduledTime']}",
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Show cancel action button if status is Scheduled
                            if (status == 'Scheduled') ...[
                              SizedBox(height: 16.w),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _cancelBooking(index, booking),
                                  icon: Icon(Icons.cancel, size: 16),
                                  label: Text(
                                    "Cancel Scheduled Booking",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red.shade700,
                                    side: BorderSide(color: Colors.red.shade200),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 10.w),
                                  ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.0.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_shipping_outlined,
                size: 80,
                color: Colors.green.shade600,
              ),
            ),
            SizedBox(height: 24.w),
            Text(
              "No Booking History",
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10.w),
            Text(
              "You haven't booked any goods carrier transport rides yet. Make your first booking now!",
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
                height: 1.5.w,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.w),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.add),
              label: Text("Book Now"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 14.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
