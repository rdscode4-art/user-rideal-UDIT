import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:rideal/screens/FutureRides/BookFuture.dart';
import 'package:rideal/widget/rideoptioncard.dart';

class RideList extends StatefulWidget {
  final List<dynamic> rides; // ✅ Pass API rides here

  const RideList({super.key, required this.rides});

  @override
  State<RideList> createState() => _RideListState();
}

class _RideListState extends State<RideList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Floating Header Row
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Text(
                    "Available Rides",
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: widget.rides.isEmpty
                  ? Center(
                      child: Text(
                        "No rides available",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16.sp),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.w),
                      itemCount: widget.rides.length,
                      itemBuilder: (context, index) {
                        final ride = widget.rides[index];
                        return RideOptionCard(
                          screenWidget: Bookfuture(rideData: ride),
                          rideId: ride['_id'] ?? '',
                          startTime: ride['time'] ?? '',
                          from: ride['fromLocation']?['address'] ?? 'Unknown location',
                          to: ride['toLocation']?['address'] ?? 'Unknown location',
                          extraWidget: SizedBox.shrink(),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
