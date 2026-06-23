import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rideal/authservices.dart';
import 'package:rideal/screens/dashboard/BottomNavigation.dart';
import 'package:intl/intl.dart';

class Bookfuture extends StatefulWidget {
  final Map<String, dynamic> rideData;
  const Bookfuture({super.key, required this.rideData});

  @override
  State<Bookfuture> createState() => _BookfutureState();
}

class _BookfutureState extends State<Bookfuture>
    with SingleTickerProviderStateMixin {
  int selectedSeats = 1;

  static const Color brandGreen = Color(0xFF0F9D58);

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.rideData;
    final rawdate = ride['date'] ?? '';
    String date = '';
    if (rawdate != '') {
      final dateTime = DateTime.parse(rawdate);
      date = DateFormat('EEE, dd MMM yyyy').format(dateTime);
    }

    final from = ride['fromLocation']['address'] ?? '';
    final to = ride['toLocation']['address'] ?? '';
    final startTime = ride['time'] ?? '';
    final price = ride['pricePerPassenger']?.toString() ?? '0';
    final vehicle = ride['vehicle'] ?? {};
    final vehicleName = vehicle['name'] ?? '';
    final driverPhone = ride['driverPhone'] ?? '';
    final maxPassengers = ride['maxPassengers'] ?? 0;
    final drivername = ride['driverId']['name'] ?? '';

    final passengersBooked = ride['passengersBooked'] as List? ?? [];
    int bookedSeats = 0;
    for (var booking in passengersBooked) {
      if (booking['status'] == 'accepted') {
        bookedSeats += booking['numOfSeats'] as int? ?? 0;
      }
    }
    final availableSeats = maxPassengers - bookedSeats;
    final priceNum = int.tryParse(price) ?? 0;
    final totalPrice = priceNum * selectedSeats;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              // Floating Header
              Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        child: Icon(Icons.arrow_back,
                            color: Colors.black87, size: 20),
                      ),
                    ),
                    Text(
                      'Book Ride',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(width: 40.w),
                  ],
                ),
              ),

              Expanded(
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      children: [
                        // Date + Route Card
                        _buildRouteCard(date, startTime, from, to),
                        SizedBox(height: 16.w),

                        // Availability Card
                        _buildAvailabilityCard(
                            availableSeats, maxPassengers, bookedSeats),
                        SizedBox(height: 16.w),

                        // Seat Selector
                        if (availableSeats > 0)
                          _buildSeatSelectorCard(availableSeats),

                        if (availableSeats > 0) SizedBox(height: 16.w),

                        // Pricing Card
                        _buildPricingCard(
                            price, priceNum, totalPrice, availableSeats),
                        SizedBox(height: 16.w),

                        // Driver & Vehicle Card
                        _buildDriverCard(
                            drivername, vehicleName, vehicle, driverPhone),
                        SizedBox(height: 24.w),

                        // Book Button
                        _buildBookButton(
                            ride, availableSeats, totalPrice),
                        SizedBox(height: 8.w),

                        Text(
                          'By booking, you agree to the ride sharing terms',
                          style: TextStyle(
                              fontSize: 11.sp, color: Colors.grey.shade400),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteCard(
      String date, String startTime, String from, String to) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date chip
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.w),
            decoration: BoxDecoration(
              color: brandGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_rounded,
                    color: brandGreen, size: 13),
                SizedBox(width: 6.w),
                Text(
                  date,
                  style: TextStyle(
                    color: brandGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 18.w),

          // Route timeline
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time column
              SizedBox(
                width: 52.w,
                child: Column(
                  children: [
                    Text(
                      startTime,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 28.w),
                    Text(
                      '~',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),

              // Timeline dots
              Column(
                children: [
                  _dot(brandGreen),
                  Container(
                    width: 2.w,
                    height: 42.w,
                    color: Colors.grey.shade200,
                  ),
                  _dot(Colors.red.shade400),
                ],
              ),

              SizedBox(width: 12.w),

              // Locations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      from,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 28.w),
                    Text(
                      to,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityCard(
      int available, int max, int booked) {
    final isAvailable = available > 0;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isAvailable
            ? brandGreen.withOpacity(0.06)
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isAvailable
              ? brandGreen.withOpacity(0.3)
              : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAvailable
                ? Icons.event_seat_rounded
                : Icons.do_not_disturb_rounded,
            color: isAvailable ? brandGreen : Colors.red.shade400,
            size: 22,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAvailable
                      ? '$available seats available'
                      : 'No seats available',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                    color: isAvailable
                        ? brandGreen
                        : Colors.red.shade600,
                  ),
                ),
                SizedBox(height: 2.w),
                Text(
                  '$booked of $max seats booked',
                  style: TextStyle(
                      fontSize: 12.sp, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          // Seat pills
          Row(
            children: List.generate(max, (i) {
              final filled = i < booked;
              return Container(
                margin: EdgeInsets.only(left: 3.w),
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: filled
                      ? Colors.grey.shade300
                      : brandGreen.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatSelectorCard(int availableSeats) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: brandGreen.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.chair_alt_rounded,
                    color: brandGreen, size: 18),
              ),
              SizedBox(width: 10.w),
              Text(
                'Select Seats',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.w),
          Row(
            children: List.generate(
              availableSeats > 4 ? 4 : availableSeats,
              (i) {
                final n = i + 1;
                final selected = selectedSeats == n;
                return GestureDetector(
                  onTap: () => setState(() => selectedSeats = n),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: EdgeInsets.only(right: 10.w),
                    width: 50.w,
                    height: 50.w,
                    decoration: BoxDecoration(
                      color: selected
                          ? brandGreen
                          : const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: selected
                            ? brandGreen
                            : Colors.grey.shade200,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: brandGreen.withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        '$n',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                          color: selected
                              ? Colors.white
                              : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(
      String price, int priceNum, int totalPrice, int availableSeats) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: brandGreen.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.payments_rounded,
                        color: brandGreen, size: 18),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Pricing',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 14.w),
          _priceRow('Per Seat', '₹$price', isLabel: false),
          SizedBox(height: 8.w),
          _priceRow('Seats Selected', '$selectedSeats', isLabel: false),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.w),
            child: Divider(height: 1.w),
          ),
          _priceRow(
            'Total',
            '₹$totalPrice',
            isLabel: true,
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isLabel = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLabel ? 15 : 13,
            fontWeight:
                isLabel ? FontWeight.w700 : FontWeight.w500,
            color: isLabel ? Colors.black87 : Colors.grey.shade500,
          ),
        ),
        Container(
          padding: isLabel
              ? EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.w)
              : EdgeInsets.zero,
          decoration: isLabel
              ? BoxDecoration(
                  color: brandGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10.r),
                )
              : null,
          child: Text(
            value,
            style: TextStyle(
              fontSize: isLabel ? 17 : 13,
              fontWeight: FontWeight.bold,
              color: isLabel ? brandGreen : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDriverCard(
      String drivername, String vehicleName, Map vehicle, String phone) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: brandGreen.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_pin_circle_rounded,
                    color: brandGreen, size: 18),
              ),
              SizedBox(width: 10.w),
              Text(
                'Driver & Vehicle',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.w),
          // Driver row
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: brandGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_rounded,
                    color: brandGreen, size: 22),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drivername,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.sp,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2.w),
                    Text('Driver',
                        style: TextStyle(
                            fontSize: 12.sp, color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.w),
          Divider(height: 1.w),
          SizedBox(height: 14.w),
          // Vehicle info
          Row(
            children: [
              _vehicleChip(Icons.directions_car_rounded, vehicleName),
              SizedBox(width: 8.w),
              _vehicleChip(
                  Icons.confirmation_number_rounded,
                  vehicle['numberPlate']?.toString() ?? ''),
              SizedBox(width: 8.w),
              _vehicleChip(
                  Icons.color_lens_rounded,
                  vehicle['color']?.toString() ?? ''),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vehicleChip(IconData icon, String label) {
    return Flexible(
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.grey.shade500),
            SizedBox(width: 5.w),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 12.sp, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookButton(
      Map<String, dynamic> ride, int availableSeats, int totalPrice) {
    return SizedBox(
      width: double.infinity,
      height: 56.w,
      child: ElevatedButton(
        onPressed: availableSeats > 0
            ? () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Center(
                    child: Container(
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                brandGreen),
                          ),
                          SizedBox(height: 16.w),
                          Text('Booking your ride...',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                );

                try {
                  final rideId = widget.rideData['_id'];
                  final result = await Authservices.bookFutureRide(
                    rideId: rideId!,
                    numOfSeats: selectedSeats,
                    rideData: ride,
                  );
                  Navigator.of(context).pop();

                  if (result != null && result['error'] == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("✅ Ride booked successfully!"),
                        backgroundColor: brandGreen,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                      ),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => BottomNavigationLogic()),
                    );
                  } else {
                    String errorMessage = "Failed to book ride";
                    if (result?['error'] != null) {
                      try {
                        final errorData = jsonDecode(result!['error']);
                        errorMessage = errorData['msg'] ?? errorMessage;
                      } catch (_) {
                        errorMessage = result!['error'];
                      }
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("❌ $errorMessage"),
                        backgroundColor: Colors.red.shade400,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("❌ Error: ${e.toString()}"),
                      backgroundColor: Colors.red.shade400,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r)),
                    ),
                  );
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: brandGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade200,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, size: 20),
            SizedBox(width: 8.w),
            Text(
              availableSeats > 0
                  ? 'Request to Book · ₹$totalPrice'
                  : 'No Seats Available',
              style: TextStyle(
                  fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 10.w,
      height: 10.w,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}