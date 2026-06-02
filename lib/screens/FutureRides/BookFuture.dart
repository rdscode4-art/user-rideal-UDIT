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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
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
                        child: const Icon(Icons.arrow_back,
                            color: Colors.black87, size: 20),
                      ),
                    ),
                    const Text(
                      'Book Ride',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              Expanded(
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      children: [
                        // Date + Route Card
                        _buildRouteCard(date, startTime, from, to),
                        const SizedBox(height: 16),

                        // Availability Card
                        _buildAvailabilityCard(
                            availableSeats, maxPassengers, bookedSeats),
                        const SizedBox(height: 16),

                        // Seat Selector
                        if (availableSeats > 0)
                          _buildSeatSelectorCard(availableSeats),

                        if (availableSeats > 0) const SizedBox(height: 16),

                        // Pricing Card
                        _buildPricingCard(
                            price, priceNum, totalPrice, availableSeats),
                        const SizedBox(height: 16),

                        // Driver & Vehicle Card
                        _buildDriverCard(
                            drivername, vehicleName, vehicle, driverPhone),
                        const SizedBox(height: 24),

                        // Book Button
                        _buildBookButton(
                            ride, availableSeats, totalPrice),
                        const SizedBox(height: 8),

                        Text(
                          'By booking, you agree to the ride sharing terms',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade400),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: brandGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_rounded,
                    color: brandGreen, size: 13),
                const SizedBox(width: 6),
                Text(
                  date,
                  style: const TextStyle(
                    color: brandGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Route timeline
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time column
              SizedBox(
                width: 52,
                child: Column(
                  children: [
                    Text(
                      startTime,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 28),
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
                    width: 2,
                    height: 42,
                    color: Colors.grey.shade200,
                  ),
                  _dot(Colors.red.shade400),
                ],
              ),

              const SizedBox(width: 12),

              // Locations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      from,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      to,
                      style: const TextStyle(
                        fontSize: 14,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAvailable
            ? brandGreen.withOpacity(0.06)
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
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
          const SizedBox(width: 12),
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
                    fontSize: 14,
                    color: isAvailable
                        ? brandGreen
                        : Colors.red.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$booked of $max seats booked',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          // Seat pills
          Row(
            children: List.generate(max, (i) {
              final filled = i < booked;
              return Container(
                margin: const EdgeInsets.only(left: 3),
                width: 10,
                height: 10,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: brandGreen.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chair_alt_rounded,
                    color: brandGreen, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Select Seats',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
                    margin: const EdgeInsets.only(right: 10),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: selected
                          ? brandGreen
                          : const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(14),
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
                          fontSize: 16,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: brandGreen.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.payments_rounded,
                        color: brandGreen, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Pricing',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _priceRow('Per Seat', '₹$price', isLabel: false),
          const SizedBox(height: 8),
          _priceRow('Seats Selected', '$selectedSeats', isLabel: false),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
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
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
              : EdgeInsets.zero,
          decoration: isLabel
              ? BoxDecoration(
                  color: brandGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: brandGreen.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_pin_circle_rounded,
                    color: brandGreen, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Driver & Vehicle',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Driver row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: brandGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded,
                    color: brandGreen, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drivername,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('Driver',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          // Vehicle info
          Row(
            children: [
              _vehicleChip(Icons.directions_car_rounded, vehicleName),
              const SizedBox(width: 8),
              _vehicleChip(
                  Icons.confirmation_number_rounded,
                  vehicle['numberPlate']?.toString() ?? ''),
              const SizedBox(width: 8),
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
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.grey.shade500),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
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
      height: 56,
      child: ElevatedButton(
        onPressed: availableSeats > 0
            ? () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                brandGreen),
                          ),
                          SizedBox(height: 16),
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
                        content: const Text("✅ Ride booked successfully!"),
                        backgroundColor: brandGreen,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
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
                            borderRadius: BorderRadius.circular(12)),
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
                          borderRadius: BorderRadius.circular(12)),
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
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              availableSeats > 0
                  ? 'Request to Book · ₹$totalPrice'
                  : 'No Seats Available',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}