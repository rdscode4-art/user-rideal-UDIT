import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideal/authservices.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FutureRidesHistory extends StatefulWidget {
  const FutureRidesHistory({super.key});

  @override
  State<FutureRidesHistory> createState() => _FutureRidesHistoryState();
}

class _FutureRidesHistoryState extends State<FutureRidesHistory> {
  bool _isLoading = false;
  Future<void> _debugRideStorage() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final ridesJson = prefs.getStringList("booked_rides") ?? [];
    
    print("=== RIDE STORAGE DEBUG ===");
    print("Total saved rides: ${ridesJson.length}");
    
    for (int i = 0; i < ridesJson.length; i++) {
      try {
        final ride = jsonDecode(ridesJson[i]);
        print("Ride $i:");
        print("  ID: ${ride['_id']}");
        print("  From: ${ride['fromLocation']?['address']}");
        print("  To: ${ride['toLocation']?['address']}");
        print("  Date: ${ride['date']}");
        print("  Passengers: ${ride['passengersBooked']}");
        print("  Booked At: ${ride['bookedAt']}");
      } catch (e) {
        print("Ride $i: Error parsing - $e");
      }
    }
    print("=== END DEBUG ===");
    
    // Show debug info to user
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Debug Info"),
        content: SingleChildScrollView(
          child: Text("Found ${ridesJson.length} saved rides.\n\nCheck console for detailed logs."),
        ),
        actions: [
          IconButton(
      icon: const Icon(Icons.bug_report),
      onPressed: _debugRideStorage,
      tooltip: "Debug Storage",
    ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  } catch (e) {
    print("Debug error: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Floating Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                      child: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                    ),
                  ),
                  const Text(
                    "Booked Rides",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _refreshRides,
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
                          child: const Icon(Icons.refresh_rounded, color: Colors.black87, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
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
                        child: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, color: Colors.black87, size: 20),
                          padding: EdgeInsets.zero,
                          onSelected: (value) {
                            switch (value) {
                              case 'clear_all':
                                _showClearAllDialog();
                                break;
                              case 'sync':
                                _syncWithServer();
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'sync',
                              child: Row(
                                children: [
                                  Icon(Icons.sync, size: 20),
                                  SizedBox(width: 8),
                                  Text('Sync with Server'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'clear_all',
                              child: Row(
                                children: [
                                  Icon(Icons.clear_all, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Clear All Rides', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status banner
            if (_isLoading)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Validating rides with server...",
                      style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            
            // Main content
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: Authservices.getBookedRides(), // This now validates with server
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F9D58))),
                          SizedBox(height: 16),
                          Text("Loading and validating rides...", style: TextStyle(fontWeight: FontWeight.w500)),
                          SizedBox(height: 8),
                          Text(
                            "This may take a moment",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text("Error: ${snapshot.error}", style: const TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _refreshRides,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F9D58),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    );
                  }

                  final rides = snapshot.data ?? [];
                  if (rides.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_seat_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "No booked rides yet",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Book a ride to see it appear here!",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text("Book a Ride", style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F9D58),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refreshRides,
                    color: const Color(0xFF0F9D58),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: rides.length,
                      itemBuilder: (context, index) {
                        final ride = rides[index];
                        return _buildRideCard(ride, index);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideCard(Map<String, dynamic> ride, int index) {
    // Safe access to nested objects
    final fromLocation = ride['fromLocation'] as Map<String, dynamic>?;
    final toLocation = ride['toLocation'] as Map<String, dynamic>?;
    
    final fromAddress = fromLocation?['address']?.toString() ?? 'Unknown location';
    final toAddress = toLocation?['address']?.toString() ?? 'Unknown location';

    // Format date safely
    String formattedDate = "";
    final dateStr = ride['date']?.toString();
    if (dateStr != null && dateStr.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(dateStr);
        formattedDate = DateFormat('dd MMM yyyy').format(dateTime);
        
        // Check if ride is in the past
        final now = DateTime.now();
        final rideDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
        final today = DateTime(now.year, now.month, now.day);
        
        if (rideDate.isBefore(today)) {
          formattedDate += " (Past)";
        } else if (rideDate.isAtSameMomentAs(today)) {
          formattedDate += " (Today)";
        }
      } catch (e) {
        formattedDate = dateStr;
      }
    } else {
      formattedDate = "Date not available";
    }

    final time = ride['time']?.toString() ?? 'Time not set';
    final price = ride['pricePerPassenger']?.toString() ?? '0';
    
    // Get booking status from passengers
    final passengersData = ride['passengersBooked'];
    String status = ride['serverStatus']?.toString() ?? 'Unknown'; // Check server data first
   
    int bookedSeats = 0;
    
    if (passengersData is List && passengersData.isNotEmpty) {
      final firstPassenger = passengersData[0];
      if (firstPassenger is Map<String, dynamic>) {
        if (status == 'Unknown') { // Only use local data if no server data
          status = firstPassenger['status']?.toString() ?? 'Unknown';
        }
        bookedSeats = firstPassenger['numOfSeats'] ?? 0;
      }
    }

    final totalAmount = (int.tryParse(price) ?? 0) * (bookedSeats > 0 ? bookedSeats : 1);
    
    return GestureDetector(
      onTap: () => _showRideDetails(context, ride),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: _getStatusColor(status).withOpacity(0.15),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Header Row (Date/Time pill & Status badge)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text(
                          "$formattedDate  •  $time",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _getStatusColor(status),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Route Timeline (Vertical)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F9D58),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 30,
                        color: Colors.grey.shade200,
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.rectangle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fromAddress,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          toAddress,
                          style: const TextStyle(
                            fontSize: 15,
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

              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade100, thickness: 1),
              const SizedBox(height: 12),

              // Card Bottom Section (Seats, Price, Actions)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F9D58).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.airline_seat_recline_normal_rounded,
                          size: 16,
                          color: Color(0xFF0F9D58),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "$bookedSeats seat${bookedSeats != 1 ? 's' : ''}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Total: ₹$totalAmount",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F9D58),
                              fontSize: 16,
                            ),
                          ),
                          if (bookedSeats > 1)
                            Text(
                              "₹$price × $bookedSeats",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          onSelected: (value) {
                            switch (value) {
                              case 'delete':
                                _showDeleteDialog(ride);
                                break;
                              case 'refresh':
                                _refreshSingleRide(ride);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'refresh',
                              child: Row(
                                children: [
                                  Icon(Icons.refresh_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Refresh Status'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Remove', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
Future<void> _saveUpdatedRide(Map<String, dynamic> updatedRide) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final ridesJson = prefs.getStringList("booked_rides") ?? [];
    
    List<String> updatedRides = [];
    final rideId = updatedRide['_id']?.toString();
    
    // Update the specific ride in the stored data
    for (String rideJsonStr in ridesJson) {
      try {
        final storedRide = jsonDecode(rideJsonStr);
        if (storedRide['_id'] == rideId) {
          // Update with the new ride data
          updatedRides.add(jsonEncode(updatedRide));
        } else {
          updatedRides.add(rideJsonStr);
        }
      } catch (e) {
        updatedRides.add(rideJsonStr);
      }
    }
    
    await prefs.setStringList("booked_rides", updatedRides);
    print("✅ Updated ride saved to storage: $rideId");
  } catch (e) {
    print("❌ Error saving updated ride: $e");
  }
}
  void _showRideDetails(BuildContext context, Map<String, dynamic> ride) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    backgroundColor: const Color(0xFFF8F9FA),
    builder: (context) {
      final passengersData = ride['passengersBooked'];
      List<dynamic> passengers = [];
      
      if (passengersData != null) {
        if (passengersData is List) {
          passengers = passengersData;
        } else if (passengersData is Map) {
          passengers = [passengersData];
        }
      }

      if (passengers.isEmpty) {
        return _buildErrorBottomSheet(
          "No Booking Data",
          "No passenger information found for this ride.",
        );
      }

      final firstPassenger = passengers[0] as Map<String, dynamic>?;
      // ✅ FIX: Use riderId instead of bookingId
      final riderId = firstPassenger?['riderId']?.toString() ?? 
                     firstPassenger?['bookingId']?.toString();
      final rideId = ride['_id']?.toString();

      if (riderId == null || rideId == null) {
        return _buildErrorBottomSheet(
          "Invalid Data",
          "Missing booking or ride information.",
        );
      }

      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Title
                    const Text(
                      "Ride Details",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildDetailContentWithoutValidation(ride, firstPassenger),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// ✅ NEW METHOD: Show details without server validation
Widget _buildDetailContentWithoutValidation(
  Map<String, dynamic> ride,
  Map<String, dynamic>? firstPassenger,
) {
  // Use local data only
  final bookingStatus = ride['serverStatus']?.toString() ?? 
                       firstPassenger?['status']?.toString() ?? 'pending';
  final driverContact = ride['serverDriverContact']?.toString() ?? 
                       'Tap "Check Status" for contact info';


  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Route information
      _buildDetailRow(
        Icons.location_on_rounded,
        "From",
        ride['fromLocation']?['address']?.toString() ?? 'Unknown',
      ),
      _buildDetailRow(
        Icons.location_off_rounded,
        "To",
        ride['toLocation']?['address']?.toString() ?? 'Unknown',
      ),
      
      const Divider(height: 32),
      
      // Booking information
      _buildDetailRow(
        Icons.info_outline_rounded,
        "Status",
        bookingStatus.toUpperCase(),
        valueColor: _getStatusColor(bookingStatus),
      ),
      
      if (firstPassenger != null) ...[
        _buildDetailRow(
          Icons.airline_seat_recline_normal_rounded,
          "Seats Booked",
          "${firstPassenger['numOfSeats'] ?? 'N/A'}",
        ),
        _buildDetailRow(
          Icons.currency_rupee_rounded,
          "Total Amount",
          "₹${(int.tryParse(ride['pricePerPassenger']?.toString() ?? '0') ?? 0) * (firstPassenger['numOfSeats'] ?? 1)}",
        ),
      ],
      
      const Divider(height: 32),
      
      // Contact information (show placeholder)
     _buildDetailRow(
        Icons.phone_rounded,
        "Driver Contact",
        driverContact,
        isSelectable: driverContact != 'Tap "Check Status" for contact info',
      ),
      
      // Vehicle info if available
      if (ride['vehicle'] != null) ...[
        const SizedBox(height: 16),
        const Text(
          "Vehicle Details",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF0F9D58),
          ),
        ),
        const SizedBox(height: 8),
        _buildDetailRow(
          Icons.directions_car_rounded,
          "Vehicle",
          ride['vehicle']['name']?.toString() ?? 'Not specified',
        ),
        if (ride['vehicle']['numberPlate'] != null)
          _buildDetailRow(
            Icons.confirmation_number_rounded,
            "Number Plate",
            ride['vehicle']['numberPlate'].toString(),
          ),
      ],
      
      const SizedBox(height: 32),
      
      // Action buttons
      Column(
        children: [
          // ✅ NEW: Add explicit status check button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _checkRideStatus(context, ride),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
              label: const Text("Check Current Status", style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F9D58),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _refreshRides();
                  },
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F9D58), size: 18),
                  label: const Text("Refresh List", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F9D58).withOpacity(0.1),
                    foregroundColor: const Color(0xFF0F9D58),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}


// ✅ FIXED METHOD: Explicit status check with correct booking ID extraction
void _checkRideStatus(BuildContext context, Map<String, dynamic> ride) {
  final passengersData = ride['passengersBooked'];
  if (passengersData == null || (passengersData as List).isEmpty) {
    _showStatusDialog(context, "No booking data available", "error");
    return;
  }

  final firstPassenger = (passengersData)[0] as Map<String, dynamic>?;
  final rideId = ride['_id']?.toString();

  if (firstPassenger == null || rideId == null) {
    _showStatusDialog(context, "Missing ride or booking information", "error");
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text("Getting booking information..."),
        ],
      ),
    ),
  );

  final riderId = firstPassenger['riderId']?.toString();
  if (riderId != null) {
    Authservices.getStatusWithAutoResolve(rideId, riderId).then((status) {
      Navigator.pop(context); // Close loading dialog
      
      if (status['error'] != null) {
        _showStatusDialog(context, "Error: ${status['error']}", "error");
      } else {
        // Update the ride data with server response
        ride['serverStatus'] = status['bookingStatus'];
        ride['serverDriverContact'] = status['driverContact'];
        
        // Update the passenger status in the stored data
        firstPassenger['status'] = status['bookingStatus'];
        _saveUpdatedRide(ride);
        // Show success dialog
        String message = "Status: ${status['bookingStatus']}\nDriver Contact: ${status['driverContact']}";
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                const Text("Status Check"),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close status dialog
                  Navigator.pop(context); // Close bottom sheet
                  setState(() {}); // Refresh the main list
                  _showRideDetails(context, ride); // Show updated bottom sheet
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }).catchError((error) {
      Navigator.pop(context);
      _showStatusDialog(context, "Failed to check status: $error", "error");
    });
  } else {
    Navigator.pop(context);
    _showStatusDialog(context, "Missing rider information", "error");
  }
}

// ✅ NEW METHOD: Show status dialog
void _showStatusDialog(BuildContext context, String message, String type) {
  IconData icon;
  Color color;
  
  switch (type) {
    case 'success':
      icon = Icons.check_circle;
      color = Colors.green;
      break;
    case 'warning':
      icon = Icons.warning;
      color = Colors.orange;
      break;
    default:
      icon = Icons.error;
      color = Colors.red;
  }

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          const Text("Status Check"),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}

  Widget _buildDetailContent(
    AsyncSnapshot<Map<String, dynamic>> statusSnapshot,
    Map<String, dynamic> ride,
    Map<String, dynamic>? firstPassenger,
  ) {
    if (statusSnapshot.connectionState == ConnectionState.waiting) {
      return const Column(
        children: [
          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F9D58))),
          SizedBox(height: 16),
          Text("Loading ride status..."),
        ],
      );
    }

    Map<String, dynamic> datastatus = {};
    if (statusSnapshot.hasError) {
      datastatus = {
        'driverContact': 'Contact not available',
        'bookingStatus': firstPassenger?['status']?.toString() ?? 'Unknown'
      };
    } else {
      datastatus = statusSnapshot.data ?? {};
    }

    final driverContact = datastatus['driverContact']?.toString() ?? 'Contact not available';
    final bookingStatus = datastatus['bookingStatus']?.toString() ?? 'Unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Route information
        _buildDetailRow(
          Icons.location_on_rounded,
          "From",
          ride['fromLocation']?['address']?.toString() ?? 'Unknown',
        ),
        _buildDetailRow(
          Icons.location_off_rounded,
          "To",
          ride['toLocation']?['address']?.toString() ?? 'Unknown',
        ),       
        const Divider(height: 32),     
        // Booking information
        _buildDetailRow(
          Icons.info_outline_rounded,
          "Status",
          bookingStatus.toUpperCase(),
          valueColor: _getStatusColor(bookingStatus),
        ),
        
        if (firstPassenger != null) ...[
          _buildDetailRow(
            Icons.airline_seat_recline_normal_rounded,
            "Seats Booked",
            "${firstPassenger['numOfSeats'] ?? 'N/A'}",
          ),
          _buildDetailRow(
            Icons.currency_rupee_rounded,
            "Total Amount",
            "₹${(int.tryParse(ride['pricePerPassenger']?.toString() ?? '0') ?? 0) * (firstPassenger['numOfSeats'] ?? 1)}",
          ),
        ],
        
        const Divider(height: 32),
        
        // Contact information
        _buildDetailRow(
          Icons.phone_rounded,
          "Driver Contact",
          driverContact,
          isSelectable: true,
        ),
        
        // Vehicle info if available
        if (ride['vehicle'] != null) ...[
          const SizedBox(height: 16),
          const Text(
            "Vehicle Details",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF0F9D58),
            ),
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.directions_car_rounded,
            "Vehicle",
            ride['vehicle']['name']?.toString() ?? 'Not specified',
          ),
          if (ride['vehicle']['numberPlate'] != null)
            _buildDetailRow(
              Icons.confirmation_number_rounded,
              "Number Plate",
              ride['vehicle']['numberPlate'].toString(),
            ),
        ],
        
        const SizedBox(height: 32),
        
        // authAction buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _refreshSingleRide(ride);
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text("Refresh", style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F9D58),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    bool isSelectable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: Colors.black54),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBottomSheet(String title, String message) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _refreshRides() async {
    setState(() {
      _isLoading = true;
    });
    
    // Small delay to show loading state
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _refreshSingleRide(Map<String, dynamic> ride) async {
    final rideId = ride['_id']?.toString();
    final passengersData = ride['passengersBooked'];
    
    if (rideId != null && passengersData != null) {
      // You can add specific ride refresh logic here
      _refreshRides();
    }
  }

  void _showDeleteDialog(Map<String, dynamic> ride) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Ride"),
        content: const Text("Are you sure you want to remove this ride from your history?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final rideId = ride['_id']?.toString();
              if (rideId != null) {
                await Authservices.removeBookedRide(rideId);
                _refreshRides();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Ride removed from history")),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear All Rides"),
        content: const Text(
          "Are you sure you want to remove all booked rides from your history? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Authservices.clearAllBookedRides();
              _refreshRides();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("All rides cleared from history")),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Clear All"),
          ),
        ],
      ),
    );
  }

  Future<void> _syncWithServer() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // This will validate all rides and remove invalid ones
      await Authservices.getBookedRides();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sync completed successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sync failed: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}