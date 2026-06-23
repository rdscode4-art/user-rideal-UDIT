import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';


class RideOptionCard extends StatelessWidget {
  final String rideId;
  final String startTime;
  
  final String from;
  final String to;
  final String profileImage;
  final bool isBus;
  final String subtitle;
  final Widget screenWidget ;
  final Widget? extraWidget; // NEW

  const RideOptionCard({
    super.key,
    required this.rideId,
    required this.startTime,   
    required this.from,
    required this.to,
    this.profileImage = '',
    this.isBus = false,
    this.subtitle = '',
    required this.screenWidget,
    required this.extraWidget
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screenWidget),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10.w, horizontal: 16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(20.0.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.w),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      startTime,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.w),
                      decoration: BoxDecoration(
                        color: _getStatusColor(subtitle).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        subtitle.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          color: _getStatusColor(subtitle),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 20.w),

              // Route Timeline
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 12.w,
                        height: 12.w,
                        decoration: BoxDecoration(
                          color: Color(0xFF0F9D58),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 2.w,
                        height: 30.w,
                        color: Colors.grey.shade200,
                      ),
                      Container(
                        width: 12.w,
                        height: 12.w,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.rectangle,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          from,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 24.w),
                        Text(
                          to,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (extraWidget != null) ...[
                SizedBox(height: 16.w),
                Divider(color: Colors.grey.shade100, thickness: 1),
                SizedBox(height: 12.w),
                extraWidget!,
              ]
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    status = status.toLowerCase();
    if (status.contains('completed') || status.contains('success')) {
      return const Color(0xFF0F9D58);
    } else if (status.contains('cancelled') || status.contains('failed')) {
      return Colors.red.shade600;
    } else if (status.contains('pending') || status.contains('progress')) {
      return Colors.orange.shade600;
    }
    return Colors.blue.shade600;
  }
}