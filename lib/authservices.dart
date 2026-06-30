import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rideal/screens/RideHistory/ridehistory.dart';
import 'model/ridermodel.dart';
import 'model/ridetypemodel.dart';

class Authservices {
  static const String baseUrl = "https://backend.ridealmobility.com";
  static const String _tokenKey = 'auth_token';
  static const String _riderIdKey = 'rider_id';
  //-------------------- Save token after login or OTP verification
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // ---------------------Get token anywhere in the app
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // ----------------------Save riderid after login or OTP verification
  static Future<void> saveRiderId(String riderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_riderIdKey, riderId);
  }

  // ------------------------Get riderid anywhere in the app
  static Future<String?> getRiderId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_riderIdKey);
  }

  //---------------------------- Request OTP
  static Future<bool> requestOtp(String phoneNumber) async {
    final url = Uri.parse('$baseUrl/auth/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phoneNumber}),
    );

    if (response.statusCode == 200) {
      print("📩 OTP sent successfully");
      return true;
    } else {
      print("❌ OTP request failed: ${response.body}");
      return false;
    }
  }

  /// -------------------------Verify OTP and save token
  static Future<bool> verifyOtp(
    String phoneNumber,
    String otp,
    String fcmToken,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phoneNumber,
          'otp': otp,
          'fcmToken': fcmToken, // 👈 Added missing field
        }),
      );

      print("📬 Verify OTP Status: ${response.statusCode}");
      print("📨 Verify OTP Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['rider']['token'];
        final riderId = data['rider']['_id'];

        if (token != null && token is String) {
          await saveToken(token);
          if (riderId != null && riderId is String) {
            await saveRiderId(riderId);
            print("✅ Rider ID saved: $riderId");
          }
          print("✅ OTP verified, token = $token");
          return true;
        } else {
          print("❌ OTP verified but token missing in response");
          return false;
        }
      } else {
        print("❌ Failed to verify OTP: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ Error verifying OTP: $e");
      return false;
    }
  }

  //------------------------------------ LOGOUT USER
  static Future<bool> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    if (token.isEmpty) {
      print("⚠️ No token found — cannot logout");
      return false;
    }

    final url = Uri.parse('$baseUrl/auth/logout');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      await prefs.remove('auth_token'); // remove only after success
      await prefs.remove('cached_rider_profile'); // Clear cached profile
      await prefs.remove('rider_id'); // Clear rider ID
      print('🚪 Logout successful');
      return true;
    } else {
      print('❌ Logout failed: ${response.body}');
      return false;
    }
  }

  // -------------------------BOOK RIDE (token auto-retrieved from SharedPreferences)
  static Future<Map<String, dynamic>?> bookRide({
    required String? pickupLocation,
    required String? dropoffLocation,
    required String? rideType,
    required double? pickupLat,
    required double? pickupLng,
    required double? dropLat,
    required double? dropLng,
    double? fare,
    String? promoCode, // Added promo code parameter
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return null;

    // 🚦 Check if a ride is already ongoing
    final currentRideId = prefs.getString('current_ride_id');

    if (currentRideId != null) {
      // Verify the ride is actually still active
      try {
        final statusResponse = await http.get(
          Uri.parse("$baseUrl/rides/status/$currentRideId"),
          headers: {"Authorization": "Bearer $token"},
        );

        if (statusResponse.statusCode == 200) {
          final statusData = jsonDecode(statusResponse.body);
          final status = (statusData['status'] ?? '').toString().toLowerCase();

          if (status == 'completed' || status == 'cancelled') {
            // Old ride is done, clear it
            await _clearRideData(prefs);
            print("✅ Cleared old ride, proceeding with new booking");
          } else {
            // Ride is still active
            print("🚫 Booking blocked: ride still $status");
            return {
              "error": "You already have an active ride",
              "rideId": currentRideId,
              "status": status,
            };
          }
        } else if (statusResponse.statusCode == 404) {
          // Ride not found, clear it
          await _clearRideData(prefs);
          print("✅ Old ride not found, proceeding with new booking");
        }
      } catch (e) {
        print("⚠️ Error checking ride status: $e");
        // On error, allow booking but log it
      }
    }

    // Validate required parameters
    if (pickupLocation == null ||
        pickupLocation.isEmpty ||
        dropoffLocation == null ||
        dropoffLocation.isEmpty ||
        rideType == null ||
        rideType.isEmpty) {
      print("❌ Missing required booking parameters");
      return null;
    }

    final url = Uri.parse("$baseUrl/rides/book");
    final body = {
      "pickupLocation": pickupLocation,
      "dropoffLocation": dropoffLocation,
      "rideType": rideType,
      "pickupLat": pickupLat,
      "pickupLng": pickupLng,
      "dropLat": dropLat,
      "dropLng": dropLng,
      if (fare != null) "fare": fare,
      if (promoCode != null && promoCode.isNotEmpty) "promoCode": promoCode,
    };
    print("📤 Booking with body: $body"); // ✅ Add debug log
    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      print("📬 Book Ride Response: $data");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final rideId = data['rideId'] ?? data['ride']?['_id'];
        final status = data['ride']?['status'] ?? 'pending';
        final otp = data['ride']?['otp'] ?? '';

        // Save ride details
        await _storeRideType(prefs, rideId, rideType);
        await prefs.setString('rideId', rideId);
        await prefs.setString('current_ride_id', rideId);
        await prefs.setString('rideStatus', status);
        await prefs.setString('pickupLocation', pickupLocation);
        await prefs.setString('dropoffLocation', dropoffLocation);
        await prefs.setString('rideType', rideType);
        await prefs.setString('rideOtp', otp);

        print("✅ Ride booked successfully: $rideId");
        return {"rideId": rideId, "status": status};
      } else {
        print(
          "❌ Failed to book ride: ${response.statusCode}, body: ${response.body}",
        );
        return null;
      }
    } catch (e) {
      print("⚠️ Exception in bookRide: $e");
      return null;
    }
  }

  static Future<void> _storeRideType(
    SharedPreferences prefs,
    String rideId,
    String rideType,
  ) async {
    try {
      // Get existing ride types map
      final rideTypesJson = prefs.getString('ride_types_map') ?? '{}';
      final Map<String, dynamic> rideTypesMap = jsonDecode(rideTypesJson);

      // Add new ride type
      rideTypesMap[rideId] = rideType;

      // Save back to prefs
      await prefs.setString('ride_types_map', jsonEncode(rideTypesMap));
      print("💾 Stored ride type: $rideId -> $rideType");
    } catch (e) {
      print("❌ Error storing ride type: $e");
    }
  }

  static Future<String?> getStoredRideType(String rideId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rideTypesJson = prefs.getString('ride_types_map') ?? '{}';
      final Map<String, dynamic> rideTypesMap = jsonDecode(rideTypesJson);

      final rideType = rideTypesMap[rideId]?.toString();
      if (rideType != null) {
        print("📖 Retrieved stored ride type: $rideId -> $rideType");
      }
      return rideType;
    } catch (e) {
      print("❌ Error retrieving ride type: $e");
      return null;
    }
  }

  static Future<void> _clearRideData(SharedPreferences prefs) async {
    await prefs.remove('rideId');
    await prefs.remove('current_ride_id');
    await prefs.remove('rideStatus');
    await prefs.remove('pickupLocation');
    await prefs.remove('dropoffLocation');
    await prefs.remove('rideType');
    await prefs.remove('rideOtp');
    await prefs.remove('ongoingRideIds');
    await prefs.remove('last_pickup_lat');
    await prefs.remove('last_pickup_lng');
    await prefs.remove('last_drop_lat');
    await prefs.remove('last_drop_lng');
    await prefs.remove('last_pickup_address');
    await prefs.remove('last_drop_address');
    print("🧹 Cleared all ride data");
  }

  //------------------------------------CANCEL RIDE
  static Future<Map<String, dynamic>?> cancelRide(String rideId) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse("$baseUrl/rides/cancel"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"rideId": rideId}),
      );

      print("Cancel ride response: ${response.statusCode}");
      print("Cancel ride body: ${response.body}");

      if (response.statusCode == 200) {
        // ✅ Clear all stored ride data after successful cancellation
        final prefs = await SharedPreferences.getInstance();
        await _clearRideData(prefs);
        print("✅ Ride cancelled and data cleared");

        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print("Error cancelling ride: $e");
      return null;
    }
  }
// Add this method to your Authservices class

static Future<Map<String, dynamic>?> deleteAccountRequest(String reason) async {
  try {
    final token = await getToken(); // Your method to get rider token
    
    if (token == null) {
      print("⚠️ No token found");
      return null;
    }

    final response = await http.post(
      Uri.parse('https://backend.ridealmobility.com/auth/rider/delete-account-request'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'reason': reason,
      }),
    );

    print('🔍 Delete Account Response: ${response.statusCode}');
    print('📄 Response Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      print('❌ Failed to delete account: ${response.statusCode}');
      return {
        'success': false,
        'message': 'Failed to submit delete request'
      };
    }
  } catch (e) {
    print('❌ Error in deleteAccountRequest: $e');
    return null;
  }
}


  //---------------------------------------CHECK RIDE STATUS
  static Future<Map<String, dynamic>?> getRideStatus(String rideId) async {
    if (rideId.isEmpty) {
      print("❌ getRideStatus called with empty rideId");
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      print("❌ No auth token found");
      return null;
    }

    final url = Uri.parse("$baseUrl/rides/status/$rideId");

    print("📡 Fetching ride status from: $url");
    print("🔑 Using token: ${token.substring(0, 10)}...");

    try {
      final response = await http
          .get(
            url,
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
            },
          )
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              print("⏱️ getRideStatus timeout after 10 seconds");
              throw TimeoutException('Request timeout');
            },
          );

      print("📬 getRideStatus response code: ${response.statusCode}");
      print("📨 getRideStatus response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ Successfully parsed ride status");
        return data;
      } else if (response.statusCode == 404) {
        // ✅ CRITICAL FIX: When ride is completed, backend returns 404
        // But we should try to get ride details from history instead of returning null
        print("⚠️ Ride status API returned 404 - checking ride history");

        try {
          // Try to get ride details from history endpoint
          final historyResponse = await http
              .get(
                Uri.parse("$url/rides/history"),
                headers: {
                  "Authorization": "Bearer $token",
                  "Content-Type": "application/json",
                },
              )
              .timeout(Duration(seconds: 10));

          if (historyResponse.statusCode == 200) {
            final historyData = jsonDecode(historyResponse.body);
            List<dynamic> ridesData = [];

            if (historyData is Map<String, dynamic> &&
                historyData.containsKey('rides')) {
              ridesData = historyData['rides'] as List;
            } else if (historyData is List) {
              ridesData = historyData;
            }

            // Find the specific ride
            final rideJson = ridesData.firstWhere(
              (ride) => ride['_id'] == rideId || ride['id'] == rideId,
              orElse: () => null,
            );

            if (rideJson != null) {
              print("✅ Found ride in history - Status: ${rideJson['status']}");
              return {
                'rideId': rideJson['_id'] ?? rideJson['id'],
                'status': rideJson['status'] ?? 'completed',
                'paymentStatus': rideJson['paymentStatus'] ?? 'unpaid',
                'estimatedFare': rideJson['estimatedFare'],
                'from_history': true, // Flag to indicate it came from history
              };
            }
          }
        } catch (historyError) {
          print("❌ Error fetching from history: $historyError");
        }

        // If not found in history, return completed status
        print("⚠️ Ride not found in history - assuming completed");
        return {
          'rideId': rideId,
          'status': 'completed',
          'paymentStatus': 'unknown',
          'message': 'Ride might be completed/cancelled',
          'from_history': false,
        };
      } else {
        print("❌ Failed to fetch ride status: ${response.statusCode}");
        print("Response body: ${response.body}");
        return null;
      }
    } on TimeoutException catch (e) {
      print("❌ Timeout exception in getRideStatus: $e");
      return null;
    } catch (e) {
      print("❌ Exception in getRideStatus: $e");
      return null;
    }
  }

  //------------------------------------PHONE NUMBER REGISTERATION
  static Future<bool> registerUser(
    String phone,
    String name,
    String gender,
    String Address,
  ) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final body = jsonEncode({
      "phone": phone,
      "name": name,
      "gender": gender,
      "address": Address,
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      print("Status: ${response.statusCode}");
      print("Response: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Registration OTP sent successfully
        return true;
      } else {
        // Registration failed
        return false;
      }
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getRiderIdFromApi(
    String riderDbId,
  ) async {
    try {
      final url = '$baseUrl/auth/riderridial/$riderDbId';

      print('🚀 Fetching Rider ID from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('📥 Rider ID Response Status: ${response.statusCode}');
      print('📥 Rider ID Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Rider ID API call successful');
          return data;
        } else {
          print('⚠️ API returned success: false');
          return null;
        }
      } else {
        print('❌ Failed to fetch Rider ID: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Exception in getRiderIdFromApi: $e');
      return null;
    }
  }

  //-------------------------------------------FETCH RIDE TYPES
 static Future<List<RideType>?> fetchRideTypes() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  
  if (token == null || token.isEmpty) {
    print("❌ No token found, cannot fetch ride types");
    return null;
  }

  final url = Uri.parse('$baseUrl/api/fare'); // Updated endpoint
  
  try {
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      print("✅ Ride types fetched successfully");
      final Map<String, dynamic> data = jsonDecode(response.body);
      
      if (data['success'] == true && data['fareRates'] != null) {
        final Map<String, dynamic> fareRates = data['fareRates'];
        final Map<String, dynamic>? vehicleImages = data['vehicleImages'];
        
        List<RideType> rideTypes = [];
        
        fareRates.forEach((key, value) {
          rideTypes.add(RideType.fromJson(key, value, vehicleImages));
        });
        
        print("✅ Parsed ${rideTypes.length} ride types");
        return rideTypes;
      } else {
        print('❌ Invalid response structure');
        return null;
      }
    } else {
      print('❌ Failed to fetch ride types: ${response.statusCode} | ${response.body}');
      return null;
    }
  } catch (e) {
    print('❌ Error fetching ride types: $e');
    return null;
  }
}

  //--------------------------SCHEDULE FUTURE RIDES WITH ALL PARAMETERS
  static Future<List<dynamic>> searchFutureRides({
    required String fromAddress,
    required String toAddress,
    required String date,
    required String time,
    required String numOfPassengers,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");

    final url = Uri.parse(
      "$baseUrl/api/future-rides/user/search"
      "?fromAddress=${Uri.encodeComponent(fromAddress)}"
      "&toAddress=${Uri.encodeComponent(toAddress)}"
      "&date=$date"
      "&time=$time"
      "&numOfPassengers=$numOfPassengers",
    );

    print("🔗 Request URL: $url");

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    print("🔍 Search response: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['rides'] ?? [];
    } else {
      print("❌ Failed to fetch rides: ${response.body}");
      return [];
    }
  }

  // ------------------------Convert 12-hour format time to 24-hour format for API
  static String convertTo24HourFormat(String time12Hour) {
    try {
      // Parse the time string (e.g., "2:30 PM")
      final timeParts = time12Hour.split(' ');
      final timeOnly = timeParts[0];
      final amPm = timeParts[1];

      final hourMinute = timeOnly.split(':');
      int hour = int.parse(hourMinute[0]);
      final minute = hourMinute[1];

      if (amPm.toUpperCase() == 'PM' && hour != 12) {
        hour += 12;
      } else if (amPm.toUpperCase() == 'AM' && hour == 12) {
        hour = 0;
      }

      return '${hour.toString().padLeft(2, '0')}:$minute';
    } catch (e) {
      // If conversion fails, return the original time
      return time12Hour;
    }
  }

  static Future<Map<String, dynamic>?> getRiderRatings(String riderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      if (token == null) {
        print("⚠️ No token found in storage.");
        return null;
      }

      final response = await http.get(
        Uri.parse("$baseUrl/rides/riders/$riderId/ratings"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          "avgRating": (data["avgRating"] as num?)?.toDouble() ?? 0.0,
          "totalRatings": data["totalRatings"] ?? 0,
        };
      } else {
        print("❌ Failed to fetch ratings: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Error in getRiderRatings: $e");
      return null;
    }
  }

  // --------------------------------Validate ride data before sending
  static String? validateRideData({
    required String pickupLocation,
    required String dropoffLocation,

    required String date,
    required String time,
    required String numberOfPersons,
  }) {
    if (pickupLocation.trim().isEmpty) {
      return 'Please enter pickup location';
    }
    if (dropoffLocation.trim().isEmpty) {
      return 'Please enter drop-off location';
    }

    if (date.trim().isEmpty) {
      return 'Please select date';
    }
    if (time.trim().isEmpty) {
      return 'Please select time';
    }
    if (numberOfPersons.trim().isEmpty) {
      return 'Please enter number of persons';
    }

    //----------------------------- Validate number of persons is a valid number
    try {
      final persons = int.parse(numberOfPersons);
      if (persons <= 0) {
        return 'Number of persons must be greater than 0';
      }
      if (persons > 4) {
        return 'Number of persons cannot exceed 4';
      }
    } catch (e) {
      return 'Please enter a valid number of persons';
    }

    return null; // No validation errors
  }

  //-----------------------------------------------COMMUNITY FEED
  static Future<Map<String, dynamic>> getCommunityFeed() async {
    try {
      final token = await getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found. Please login first.',
          'data': [],
        };
      }

      print("📡 Fetching community feed...");

      final response = await http.get(
        Uri.parse('$baseUrl/api/community/feed'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("📬 Community Feed Status: ${response.statusCode}");
      print("📨 Community Feed Response: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        return {
          'success': true,
          'message': 'Community feed loaded successfully!',
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to load community feed',
          'data': [],
        };
      }
    } catch (e) {
      print("❌ Error fetching community feed: $e");
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': [],
      };
    }
  }

  //-----------------------------------------FETCH RIDE HISTORY
  static Future<List<Ride>> fetchRideHistory() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse("$baseUrl/rides/history"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print('🚀 RESPONSE STATUS: ${response.statusCode}');
      print('🔍 Raw API response length: ${response.body.length} chars');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print('🔍 Parsed JSON type: ${decoded.runtimeType}');

        List<dynamic> ridesData = [];

        // Case 1: API returns { "rides": [...] } - YOUR ACTUAL CASE
        if (decoded is Map<String, dynamic> && decoded.containsKey('rides')) {
          print('🔍 Found "rides" key');
          ridesData = decoded['rides'] as List;
        }
        // Case 2: API returns { "data": [...] }
        else if (decoded is Map<String, dynamic> &&
            decoded.containsKey('data')) {
          print('🔍 Found "data" key');
          ridesData = decoded['data'] as List;
        }
        // Case 3: API returns plain list [ {...}, {...} ]
        else if (decoded is List) {
          print('🔍 Found plain list');
          ridesData = decoded;
        }
        // Case 4: Single ride object
        else if (decoded is Map<String, dynamic>) {
          print('🔍 Found single ride object');
          ridesData = [decoded];
        }

        print('🔍 Processing ${ridesData.length} rides');

        final rides = <Ride>[];
        for (int i = 0; i < ridesData.length; i++) {
          try {
            final rideJson = ridesData[i] as Map<String, dynamic>;
            print('\n🔄 Parsing ride $i with ID: ${rideJson['_id']}');
            final ride = Ride.fromJson(rideJson);
            rides.add(ride);
            print('✅ Successfully parsed ride $i: ${ride.stops.length} stops');
          } catch (e, stackTrace) {
            print('❌ Error parsing ride $i: $e');
            print('Stack trace: $stackTrace');
            // Continue with next ride instead of failing completely
          }
        }

        print(
          '✅ Successfully parsed ${rides.length}/${ridesData.length} rides',
        );
        return rides;
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        throw Exception("Failed to load ride history: ${response.statusCode}");
      }
    } catch (e, stackTrace) {
      print('❌ Exception in fetchRideHistory: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Debug function to check ride structure
  static Future<void> debugRideStructure(String rideId) async {
    try {
      final rides = await fetchRideHistory();
      final ride = rides.firstWhere(
        (r) => r.id == rideId,
        orElse: () => throw Exception('Ride not found'),
      );

      print('\n🔍 DEBUG: Ride Structure for $rideId');
      print('Status: ${ride.status}');
      print('Type: ${ride.type}');
      print('Created: ${ride.createdAt}');
      print('Stops: ${ride.stops.length}');
      for (var stop in ride.stops) {
        print('  - ${stop.type}: ${stop.address} (${stop.lat}, ${stop.lng})');
      }
    } catch (e) {
      print('❌ Debug error: $e');
    }
  }

  //-------------------------EDIT PROFILE WITH IMAGE
  static Future<Rider> updateRiderProfileWithImage(
    String riderId,
    String? name,
    String? phone,
    String? imagePath,
  ) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception("No token found. Please login first.");
      }

      print("🔄 Updating profile for Rider ID: $riderId");

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/auth/edit-profile/$riderId'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      if (name != null && name.isNotEmpty) {
        request.fields['name'] = name;
      }
      if (phone != null && phone.isNotEmpty) {
        request.fields['phone'] = phone;
      }

      // Add image file if provided
      if (imagePath != null && imagePath.isNotEmpty) {
        try {
          print("🖼️ Adding image file: $imagePath");

          // Get the file extension to determine MIME type
          String extension = imagePath.toLowerCase().split('.').last;
          String contentType;

          switch (extension) {
            case 'jpg':
            case 'jpeg':
              contentType = 'image/jpeg';
              break;
            case 'png':
              contentType = 'image/png';
              break;
            case 'gif':
              contentType = 'image/gif';
              break;
            case 'webp':
              contentType = 'image/webp';
              break;
            default:
              contentType = 'image/jpeg'; // Default to JPEG
          }

          print("🎯 Setting content type: $contentType");

          var file = await http.MultipartFile.fromPath(
            'profilePhoto', // Keep the original field name
            imagePath,
            contentType: http_parser.MediaType.parse(contentType),
          );
          request.files.add(file);
          print(
            "✅ Image file added successfully with content type: $contentType",
          );
        } catch (e) {
          print("❌ Error adding image file: $e");
          throw Exception("Failed to process image file: $e");
        }
      }

      print("🚀 Sending request to: ${request.url}");
      print("📋 Fields: ${request.fields}");
      print("📁 Files count: ${request.files.length}");

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("📬 Update Profile Status: ${response.statusCode}");
      print("📨 Update Profile Response: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print("🔍 Parsed response data: $data");

        if (data['success'] == true && data['rider'] != null) {
          print("✅ Profile update successful, parsing rider data...");
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('cached_rider_profile', jsonEncode(data['rider']));
            
            // Cache profile image instantly
            final profileImageUrl = data['rider']['profileImage'] ?? data['rider']['profilePhoto'];
            if (imagePath != null && imagePath.isNotEmpty) {
              try {
                final file = File(imagePath);
                if (await file.exists()) {
                  final bytes = await file.readAsBytes();
                  final base64Image = base64Encode(bytes);
                  await prefs.setString('cached_profile_image_base64', base64Image);
                  print("✅ Profile image base64 cached instantly from local file path");
                } else if (profileImageUrl != null && profileImageUrl.toString().isNotEmpty) {
                  _downloadAndCacheProfileImage(profileImageUrl.toString());
                }
              } catch (e) {
                print("⚠️ Error caching local image: $e");
                if (profileImageUrl != null && profileImageUrl.toString().isNotEmpty) {
                  _downloadAndCacheProfileImage(profileImageUrl.toString());
                }
              }
            } else if (profileImageUrl != null && profileImageUrl.toString().isNotEmpty) {
              _downloadAndCacheProfileImage(profileImageUrl.toString());
            } else {
              await prefs.remove('cached_profile_image_base64');
            }

            final updatedRider = Rider.fromJson(data['rider']);
            print("✅ Rider parsed successfully: ${updatedRider.name}");
            return updatedRider;
          } catch (e) {
            print("❌ Error parsing rider data: $e");
            print("🔍 Rider data structure: ${data['rider']}");
            throw Exception("Failed to parse updated rider data: $e");
          }
        } else {
          throw Exception("Invalid response structure: $data");
        }
      } else {
        throw Exception(
          "Failed to update profile. Status: ${response.statusCode}, Body: ${response.body}",
        );
      }
    } catch (e) {
      print("❌ Exception in updateRiderProfileWithImage: $e");
      rethrow;
    }
  }

  //-------------------------EDIT PROFILE (OLD METHOD)
  // Add this method to your Authservices class

  static Future<Rider> updateRiderProfile(
    String riderId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception("No token found. Please login first.");
      }

      print("🔄 Updating profile for Rider ID: $riderId with data: $updates");

      final response = await http.put(
        Uri.parse('$baseUrl/auth/edit-profile/$riderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updates),
      );

      print("📬 Update Profile Status: ${response.statusCode}");
      print("📨 Update Profile Response: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Check if the response contains the expected structure
        if (data['success'] == true && data['rider'] != null) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('cached_rider_profile', jsonEncode(data['rider']));
            
            // Update profile image cache
            final profileImageUrl = data['rider']['profileImage'] ?? data['rider']['profilePhoto'];
            if (profileImageUrl != null && profileImageUrl.toString().isNotEmpty) {
              _downloadAndCacheProfileImage(profileImageUrl.toString());
            } else {
              await prefs.remove('cached_profile_image_base64');
            }
            return Rider.fromJson(data['rider']);
          } catch (e) {
            print("❌ Error parsing rider data: $e");
            print("🔍 Rider data received: ${data['rider']}");
            throw Exception("Failed to parse updated rider data: $e");
          }
        } else {
          throw Exception("Invalid response structure: $data");
        }
      } else {
        throw Exception(
          "Failed to update rider profile. Status: ${response.statusCode}, Body: ${response.body}",
        );
      }
    } catch (e) {
      print("❌ Exception in updateRiderProfile: $e");
      rethrow;
    }
  }

  //-----------------------FETCH PROFILE
  static Future<Rider> getRiderProfile(String riderId) async {
    final token = await getToken();

    if (token == null) {
      throw Exception("No token found. Please login first.");
    }

    final response = await http.get(
      Uri.parse('$baseUrl/auth/riders/$riderId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print("📬 Rider Profile Status: ${response.statusCode}");
    print("📨 Rider Profile Response: ${response.body}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_rider_profile', response.body);
        
        // Cache the profile image in the background
        final profileImageUrl = data['profileImage'] ?? data['profilePhoto'];
        if (profileImageUrl != null && profileImageUrl.toString().isNotEmpty) {
          _downloadAndCacheProfileImage(profileImageUrl.toString());
        }
      } catch (e) {
        print("⚠️ Failed to cache profile locally: $e");
      }
      return Rider.fromJson(data);
    } else {
      throw Exception("Failed to fetch rider profile: ${response.body}");
    }
  }

  //-----------------------GET CACHED PROFILE
  static Future<Rider?> getCachedRiderProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cached_rider_profile');
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(cachedJson);
        return Rider.fromJson(data);
      }
    } catch (e) {
      print("⚠️ Error reading cached profile: $e");
    }
    return null;
  }

  //-----------------------DOWNLOAD AND CACHE PROFILE IMAGE AS BASE64
  static Future<void> _downloadAndCacheProfileImage(String urlPath) async {
    try {
      String fullUrl = urlPath;
      if (!urlPath.startsWith('http')) {
        fullUrl = '$baseUrl$urlPath';
      }
      final response = await http.get(Uri.parse(fullUrl));
      if (response.statusCode == 200) {
        final base64Image = base64Encode(response.bodyBytes);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_profile_image_base64', base64Image);
        print("✅ Profile image base64 cached successfully");
      }
    } catch (e) {
      print("⚠️ Error downloading/caching profile image: $e");
    }
  }

  //-----------------------GET CACHED PROFILE IMAGE BASE64
  static Future<String?> getCachedProfileImageBase64() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('cached_profile_image_base64');
    } catch (e) {
      print("⚠️ Error reading cached base64 profile image: $e");
    }
    return null;
  }

  //--------------------MULTISTOP RIDE
  static Future<Map<String, dynamic>?> createMultiStopRide(
    List<Map<String, dynamic>> stops,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        print("❌ No auth token found");
        return null;
      }

      // Validate stops
      if (stops.length < 2 || stops.length > 4) {
        print("❌ Invalid number of stops: ${stops.length}. Must be 2-4 stops.");
        return null;
      }

      // Ensure all stops have required fields
      final validatedStops =
          stops.map((stop) {
            if (stop['lat'] == null || stop['lng'] == null) {
              throw Exception("Invalid coordinates in stop: $stop");
            }
            return {
              "name": stop["name"] ?? "Stop location",
              "lat": (stop["lat"] as num).toDouble(),
              "lng": (stop["lng"] as num).toDouble(),
            };
          }).toList();

      final requestBody = {"stops": validatedStops};

      print("📤 Creating multi-stop route with ${validatedStops.length} stops");
      print("📦 Request body: ${jsonEncode(requestBody)}");

      final response = await http.post(
        Uri.parse("$baseUrl/location/multi-stop"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(requestBody),
      );

      print("📬 Status: ${response.statusCode}");
      print("📨 Response: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print("❌ Failed to create multi-stop route: ${response.statusCode}");
        print("Response: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Error creating multi-stop route: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> bookMultiRide({
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> drop,
    required List<Map<String, dynamic>> stops,
    required String type,
    required double fare,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        print("❌ No auth token found");
        return null;
      }

      // 🚦 Check if a ride is already ongoing
      final ongoingRides = prefs.getStringList('ongoingRideIds') ?? [];
      if (ongoingRides.isNotEmpty) {
        print("🚫 Multi-ride booking blocked: ride already ongoing");
        return {
          "error": "You already have an ongoing ride",
          "rideId": ongoingRides.first,
          "status": "ongoing",
        };
      }

      // Prepare intermediate stops (excluding pickup and drop)
      List<Map<String, dynamic>> intermediateStops = [];
      if (stops.length > 2) {
        // Take stops between first (pickup) and last (drop)
        intermediateStops =
            stops
                .sublist(1, stops.length - 1)
                .map(
                  (stop) => {
                    "lat": (stop["lat"] as num).toDouble(),
                    "lng": (stop["lng"] as num).toDouble(),
                    "address":
                        stop["address"] ?? stop["name"] ?? "Intermediate stop",
                  },
                )
                .toList();
      }

      final requestBody = {
        "pickup": {
          "lat": (pickup["lat"] as num).toDouble(),
          "lng": (pickup["lng"] as num).toDouble(),
          "address": pickup["address"] ?? "Pickup location",
        },
        "drop": {
          "lat": (drop["lat"] as num).toDouble(),
          "lng": (drop["lng"] as num).toDouble(),
          "address": drop["address"] ?? "Drop location",
        },
        "stops": intermediateStops, // Only intermediate stops
        "type": type,
        "estimatedFare": fare.toInt(),
      };

      print("📤 Booking multi-stop ride");
      print("📦 Pickup: ${requestBody['pickup']}");
      print("📦 Drop: ${requestBody['drop']}");
      print(
        "📦 Intermediate stops (${intermediateStops.length}): $intermediateStops",
      );
      print("📦 Type: $type, Fare: ₹${fare.toInt()}");

      final response = await http.post(
        Uri.parse("$baseUrl/rides/multi"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(requestBody),
      );

      print("📬 Book Multi Ride Status: ${response.statusCode}");
      print("📨 Book Multi Ride Response: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final rideId = data['rideId'].toString();
        String otp = data['otp'] ?? '';
        final status = data['status'] ?? 'pending';

        // Save ride details
        await prefs.setString('rideId', rideId);
        await prefs.setString('rideOtp', otp);
        await prefs.setString('rideStatus', status);
        await prefs.setString('rideType', type);

        // ✅ Add to ongoing rides
        List<String> currentRides = prefs.getStringList('ongoingRideIds') ?? [];
        currentRides.add(rideId);
        await prefs.setStringList('ongoingRideIds', currentRides);

        return {"rideId": rideId, "status": status, "otp": otp};
      } else {
        print("❌ Failed to book multi ride: ${response.statusCode}");
        // Try to parse error message
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage =
              errorData['msg'] ?? errorData['message'] ?? 'Unknown error';
          print("Error message: $errorMessage");

          // Specific error handling
          if (errorMessage.toLowerCase().contains(
            'provide up to 3 additional stops',
          )) {
            print(
              "⚠️ Backend expects exactly 3 intermediate stops, got ${intermediateStops.length}",
            );
            if (intermediateStops.length < 3) {
              print("💡 Consider adjusting the booking logic for fewer stops");
            }
          }
        } catch (parseError) {
          print("Could not parse error response: $parseError");
        }
        return null;
      }
    } catch (e) {
      print("❌ Error booking multi ride: $e");
      return null;
    }
  }

  // //---------------------MULTISTOP BOOK RIDE
  // Alternative booking method that handles backend requirements more strictly
  static Future<Map<String, dynamic>?> bookMultiRideStrict({
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> drop,
    required List<Map<String, dynamic>> allStops,
    required String type,
    required double fare,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        print("❌ No auth token found");
        return null;
      }

      // Backend expects exactly 3 intermediate stops
      List<Map<String, dynamic>> intermediateStops = [];

      if (allStops.length > 2) {
        // Get intermediate stops (between pickup and drop)
        final intermediate = allStops.sublist(1, allStops.length - 1);

        // Ensure we have exactly 3 intermediate stops by padding if necessary
        for (int i = 0; i < 3; i++) {
          if (i < intermediate.length) {
            intermediateStops.add({
              "lat": (intermediate[i]["lat"] as num).toDouble(),
              "lng": (intermediate[i]["lng"] as num).toDouble(),
              "address":
                  intermediate[i]["address"] ??
                  intermediate[i]["name"] ??
                  "Stop ${i + 1}",
            });
          } else {
            // Pad with drop location if we don't have enough intermediate stops
            intermediateStops.add({
              "lat": (drop["lat"] as num).toDouble(),
              "lng": (drop["lng"] as num).toDouble(),
              "address": drop["address"] ?? "Drop location",
            });
          }
        }
      } else {
        // If only pickup and drop, pad with drop location
        for (int i = 0; i < 3; i++) {
          intermediateStops.add({
            "lat": (drop["lat"] as num).toDouble(),
            "lng": (drop["lng"] as num).toDouble(),
            "address": drop["address"] ?? "Drop location",
          });
        }
      }

      final requestBody = {
        "pickup": {
          "lat": (pickup["lat"] as num).toDouble(),
          "lng": (pickup["lng"] as num).toDouble(),
          "address": pickup["address"] ?? "Pickup location",
        },
        "drop": {
          "lat": (drop["lat"] as num).toDouble(),
          "lng": (drop["lng"] as num).toDouble(),
          "address": drop["address"] ?? "Drop location",
        },
        "stops": intermediateStops, // Always exactly 3 stops
        "type": type,
        "fare": fare.toInt(),
      };

      print("📤 Booking multi-stop ride (strict mode)");
      print("📦 Request body: ${jsonEncode(requestBody)}");

      final response = await http.post(
        Uri.parse("$baseUrl/rides/multi"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(requestBody),
      );

      print("📬 Status: ${response.statusCode}");
      print("📨 Response: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final rideId = data['rideId'].toString();
        await _storeRideType(prefs, rideId, type);
        return data;
      } else {
        print("❌ Failed to book multi ride: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Error booking multi ride: $e");
      return null;
    }
  }

  //----------------------RIDE DETAILS
  static Future<Ride?> getRideDetail(String rideId) async {
    final token = await getToken();
    try {
      print("🔍 Fetching ride detail for ID: $rideId from history");

      var response = await http
          .get(
            Uri.parse("$baseUrl/rides/history"),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(Duration(seconds: 10));

      print("📡 History response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<dynamic> ridesData = [];
        if (data is Map<String, dynamic> && data.containsKey('rides')) {
          ridesData = data['rides'] as List;
        } else if (data is List) {
          ridesData = data;
        }

        print("🔍 Found ${ridesData.length} rides in history");

        // Find the specific ride by ID
        final rideJson = ridesData.firstWhere(
          (ride) => ride['_id'] == rideId || ride['id'] == rideId,
          orElse: () => null,
        );

        if (rideJson == null) {
          print("❌ Ride not found in history: $rideId");
          return null;
        }
        print("🔍 Raw ride type from API: ${rideJson['rideType']}");
        print("🔍 Raw type from API: ${rideJson['type']}");
        print("✅ Found ride in history");
        print("🔍 Ride JSON keys: ${rideJson.keys.toList()}");

        return Ride.fromJson(rideJson);
      } else {
        print("❌ HTTP Error ${response.statusCode}: ${response.body}");
        throw Exception('Failed to load ride history: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ Error fetching ride detail: $e");
      rethrow;
    }
  }

  static Future<void> debugSpecificRide(String rideId) async {
    final token = await getToken();
    try {
      var response = await http.get(
        Uri.parse("$baseUrl/rides/$rideId"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("🔍 RAW API RESPONSE for $rideId:");
      print("Status: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print("🔍 DECODED JSON:");
        print(const JsonEncoder.withIndent('  ').convert(decoded));
      }
    } catch (e) {
      print("❌ Debug error: $e");
    }
  }

  // Also add this method to help debug what the actual API structure looks like
  // static Future<void> debugRideStructure(String rideId) async {
  //   final token = await getToken();
  //   try {
  //     final response = await http.get(
  //       Uri.parse('$baseUrl/api/rides/$rideId'),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization': 'Bearer $token',
  //       },
  //     );

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);

  //       print("=== RIDE STRUCTURE DEBUG ===");
  //       print("Response Type: ${data.runtimeType}");

  //       if (data is Map<String, dynamic>) {
  //         print("Root Keys: ${data.keys.toList()}");

  //         // Check each key and its structure
  //         data.forEach((key, value) {
  //           print("Key '$key':");
  //           print("  Type: ${value.runtimeType}");
  //           if (value is Map<String, dynamic>) {
  //             print("  Sub-keys: ${value.keys.toList()}");

  //             // Look for location-related data
  //             value.forEach((subKey, subValue) {
  //               if (subKey.toString().toLowerCase().contains('lat') ||
  //                   subKey.toString().toLowerCase().contains('lng') ||
  //                   subKey.toString().toLowerCase().contains('location') ||
  //                   subKey.toString().toLowerCase().contains('address')) {
  //                 print("    🎯 Location-related: '$subKey' = $subValue");
  //               }
  //             });
  //           } else if (value is List) {
  //             print("  Array length: ${value.length}");
  //             if (value.isNotEmpty) {
  //               print("  First item type: ${value.first.runtimeType}");
  //               if (value.first is Map) {
  //                 print("  First item keys: ${(value.first as Map).keys.toList()}");
  //               }
  //             }
  //           } else {
  //             print("  Value: $value");
  //           }
  //         });
  //       }
  //       print("=== END DEBUG ===");
  //     }
  //   } catch (e) {
  //     print("❌ Debug error: $e");
  //   }
  // }
  //---------------------RATE RIDE
  static Future<void> rateRide({
    required String rideId,
    required int rating,
    required String feedback,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final url = Uri.parse("$baseUrl/ride/rate");

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "rideId": rideId,
        "rating": rating,
        "feedback": feedback,
      }),
    );

    if (response.statusCode == 200) {
      print("✅ Ride rated successfully: ${response.body}");
    } else {
      print("❌ Failed to rate ride: ${response.statusCode} - ${response.body}");
    }
  }

  //---------------------CREATE TICKET
  static Future<void> createTicket(
    String subject,
    String message,
    String rideId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    if (token.isEmpty) {
      throw Exception('No authentication token found');
    }

    final url = Uri.parse("$baseUrl/api/rider/create");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "subject": subject,
          "message": message,
          "rideId": rideId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Ticket created successfully: ${response.body}");
      } else {
        print("Error: ${response.statusCode} -> ${response.body}");
        throw Exception('Failed to create ticket: ${response.statusCode}');
      }
    } catch (e) {
      print("Network error: $e");
      throw Exception('Network error occurred while creating ticket');
    }
  }

  //---------------------GET DRIVER LOCATION AND DRIVER DETAILS
  static Future<Map<String, dynamic>?> getDriverLocation(String rideId) async {
    final String? token = await getToken(); // ✅ Use your defined method

    if (token == null) {
      print('⚠️ No auth token found in storage');
      return null;
    }

    final String url = '$baseUrl/rides/$rideId/driver-location';
    print('🌍 Fetching driver location from: $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('📄 HTTP Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print(
          '🚗 Driver Lat: ${data["lat"]}, Lng: ${data["lng"]}, Name: ${data["name"]}',
        );
        return data;
      } else {
        print(
          '⚠️ Failed to fetch driver location. Status code: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      print('❌ Exception during driver location fetch: $e');
      return null;
    }
  }

  // COMPREHENSIVE STATUS CHECK - Multiple fallback methods
  // Simple status check function using the correct API endpoint
  // FIXED: Updated status check method with better error handling
  static Future<Map<String, dynamic>> getBookingStatus(
    String rideId,
    String bookingId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      if (token == null) {
        return {
          'error': 'No authentication token',
          'bookingStatus': 'unknown',
          'driverContact': 'Not available',
        };
      }

      final url = Uri.parse(
        "$baseUrl/api/future-rides/user/status/$rideId/$bookingId",
      );
      print("🔍 Checking status at: $url");
      print("  - Ride ID: $rideId");
      print("  - Booking ID: $bookingId");

      final response = await http
          .get(url, headers: {"Authorization": "Bearer $token"})
          .timeout(Duration(seconds: 10));

      print("📊 Status response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'bookingStatus': data['bookingStatus'] ?? 'unknown',
          'driverContact': data['driverContact'] ?? 'Not available',
          'otp': data['otp'],
          'success': true,
        };
      } else if (response.statusCode == 404) {
        // Booking not found - this usually means wrong IDs
        print("❌ Booking not found - checking for ID mismatch");
        return {
          'error':
              'Booking not found. The ride or booking ID may be incorrect.',
          'bookingStatus': 'not_found',
          'driverContact': 'Not available',
          'needsIdResolution': true, // Flag to indicate ID resolution needed
        };
      } else {
        return {
          'error': 'Failed to get status: ${response.statusCode}',
          'bookingStatus': 'error',
          'driverContact': 'Not available',
        };
      }
    } catch (e) {
      print("❌ Error checking booking status: $e");
      return {
        'error': e.toString(),
        'bookingStatus': 'error',
        'driverContact': 'Not available',
      };
    }
  }

  static Future<Map<String, dynamic>?> bookFutureRide({
    required String rideId,
    required int numOfSeats,
    required Map<String, dynamic> rideData,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      if (token == null) {
        print("No token found. Please login first.");
        return null;
      }

      final url = Uri.parse("$baseUrl/api/future-rides/user/book/$rideId");
      print("Booking URL: $url");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"numOfSeats": numOfSeats}),
      );

      print("Booking Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final res = jsonDecode(response.body);
        final bookingData = res['booking'];

        // IMPORTANT: Use the ride ID from the booking response, not the parameter
        final actualRideId =
            res['rideId']?.toString() ??
            bookingData['rideId']?.toString() ??
            rideId;
        final bookingId = bookingData['_id']?.toString();

        print("🔍 Booking created:");
        print("  - Actual Ride ID: $actualRideId");
        print("  - Booking ID: $bookingId");
        print("  - Rider ID: ${bookingData['riderId']}");

        // Local storage for future rides is now disabled. 
        // Rides are fetched directly from the backend via my-bookings API.
        print(
          "✅ Ride booked successfully with actual IDs: ride=$actualRideId, booking=$bookingId",
        );

        return res;
      } else {
        print("Booking failed: ${response.statusCode}");
        return {"error": response.body};
      }
    } catch (e) {
      print("Error booking future ride: $e");
      return {"error": e.toString()};
    }
  }

  // Helper function to get the actual booking ID from search results
  static Future<String?> getActualBookingId(
    String rideId,
    String riderId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      if (token == null) return null;

      // Get stored ride data to reconstruct search
      final ridesJson = prefs.getStringList("booked_rides") ?? [];

      for (String rideJsonStr in ridesJson) {
        try {
          final storedRide = jsonDecode(rideJsonStr);
          if (storedRide['_id'] == rideId) {
            final fromLocation = storedRide['fromLocation'];
            final toLocation = storedRide['toLocation'];
            final date = storedRide['date'];

            if (fromLocation != null && toLocation != null && date != null) {
              final searchUrl = Uri.parse(
                "$baseUrl/api/future-rides/user/search"
                "?fromAddress=${Uri.encodeComponent(fromLocation['address'])}"
                "&toAddress=${Uri.encodeComponent(toLocation['address'])}"
                "&date=${date.split('T')[0]}"
                "&numOfPassengers=1",
              );

              final searchResponse = await http
                  .get(searchUrl, headers: {"Authorization": "Bearer $token"})
                  .timeout(Duration(seconds: 8));

              if (searchResponse.statusCode == 200) {
                final searchData = jsonDecode(searchResponse.body);
                final rides = searchData['rides'] as List?;

                if (rides != null) {
                  // Look for our booking in any ride
                  for (var ride in rides) {
                    final passengers = ride['passengersBooked'] as List?;
                    if (passengers != null) {
                      for (var passenger in passengers) {
                        if (passenger['riderId'] == riderId) {
                          print(
                            "Found actual booking ID: ${passenger['_id']} in ride: ${ride['_id']}",
                          );
                          return passenger['_id']; // This is the actual booking ID
                        }
                      }
                    }
                  }
                }
              }
            }
            break;
          }
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      print("Error getting actual booking ID: $e");
    }
    return null;
  }

  static Future<Map<String, String>?> getCorrectBookingIds(
    String riderId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      if (token == null) return null;

      print("🔍 Searching for correct booking IDs for rider: $riderId");

      // Get stored ride data to reconstruct search
      final ridesJson = prefs.getStringList("booked_rides") ?? [];

      for (String rideJsonStr in ridesJson) {
        try {
          final storedRide = jsonDecode(rideJsonStr);
          final passengersData = storedRide['passengersBooked'] as List?;

          if (passengersData != null && passengersData.isNotEmpty) {
            final passenger = passengersData[0] as Map<String, dynamic>?;
            if (passenger != null && passenger['riderId'] == riderId) {
              final fromLocation = storedRide['fromLocation'];
              final toLocation = storedRide['toLocation'];
              final date = storedRide['date'];

              if (fromLocation != null && toLocation != null && date != null) {
                print("🔍 Searching rides for date: ${date.split('T')[0]}");

                final searchUrl = Uri.parse(
                  "$baseUrl/api/future-rides/user/search"
                  "?fromAddress=${Uri.encodeComponent(fromLocation['address'])}"
                  "&toAddress=${Uri.encodeComponent(toLocation['address'])}"
                  "&date=${date.split('T')[0]}"
                  "&numOfPassengers=1",
                );

                final searchResponse = await http
                    .get(searchUrl, headers: {"Authorization": "Bearer $token"})
                    .timeout(Duration(seconds: 8));

                print("📊 Search response: ${searchResponse.statusCode}");

                if (searchResponse.statusCode == 200) {
                  final searchData = jsonDecode(searchResponse.body);
                  final rides = searchData['rides'] as List?;

                  if (rides != null) {
                    print(
                      "🔍 Found ${rides.length} rides, searching for our booking...",
                    );

                    // Look for our booking in any ride
                    for (var ride in rides) {
                      final passengers = ride['passengersBooked'] as List?;
                      if (passengers != null) {
                        for (var passenger in passengers) {
                          if (passenger['riderId'] == riderId) {
                            final correctRideId = ride['_id']?.toString();
                            final correctBookingId =
                                passenger['_id']?.toString();

                            print("✅ Found correct IDs:");
                            print("  - Correct Ride ID: $correctRideId");
                            print("  - Correct Booking ID: $correctBookingId");

                            return {
                              'rideId': correctRideId ?? '',
                              'bookingId': correctBookingId ?? '',
                            };
                          }
                        }
                      }
                    }
                  }
                }
              }
              break;
            }
          }
        } catch (e) {
          print("❌ Error processing stored ride: $e");
          continue;
        }
      }
    } catch (e) {
      print("❌ Error getting correct booking IDs: $e");
    }

    print("❌ Could not find correct booking IDs");
    return null;
  }

  // Updated method to check status with automatic booking ID resolution
  static Future<Map<String, dynamic>> getStatusWithAutoResolve(
    String rideId,
    String bookingId,
  ) async {
    print("🔍 Calling getBookingStatus directly with rideId: $rideId, bookingId: $bookingId");
    return await getBookingStatus(rideId, bookingId);
  }


  //--------------------GET BOOKED RIDES (API MIGRATED)
  static Future<List<Map<String, dynamic>>> getBookedRides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      
      if (token == null) {
        print("No token found for fetching booked rides");
        return [];
      }

      final url = Uri.parse("$baseUrl/api/future-rides/user/my-bookings");
      print("Fetching booked rides from API: $url");
      
      final response = await http.get(url, headers: {
        "Authorization": "Bearer $token"
      }).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> bookings = data['bookings'] ?? [];
        
        List<Map<String, dynamic>> mappedRides = bookings.map((b) {
          final bookingObj = b['booking'] ?? {};
          final driverObj = b['driver'] ?? {};
          return {
            '_id': b['rideId'],
            'fromLocation': b['fromLocation'] ?? {'address': 'Unknown location'},
            'toLocation': b['toLocation'] ?? {'address': 'Unknown location'},
            'date': b['date'] ?? '',
            'time': b['time'] ?? 'Not set',
            'pricePerPassenger': b['pricePerPassenger'] ?? 0,
            'passengersBooked': [
              {
                '_id': bookingObj['bookingId'],
                'bookingId': bookingObj['bookingId'],
                'riderId': bookingObj['bookingId'],
                'numOfSeats': bookingObj['numOfSeats'],
                'status': bookingObj['status'] ?? 'pending',
                'otp': bookingObj['otp'],
              }
            ],
            'serverStatus': bookingObj['status'] ?? 'pending',
            'serverDriverContact': driverObj['phone'] ?? 'Not available'
          };
        }).toList();

        print("Fetched ${mappedRides.length} booked rides from API");
        return mappedRides;
      } else {
        print("Failed to fetch booked rides. Status: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error fetching booked rides: $e");
      return [];
    }
  }

  //---------------------SAVE BOOKED RIDE (DISABLED)
  static Future<void> saveBookedRide(Map<String, dynamic> ride) async {
    // Local storage disabled. We rely on the backend API.
  }

  //---------------------REMOVE BOOKED RIDE FROM SHARED PREFERENCES (DISABLED)
  static Future<void> removeBookedRide(String rideId) async {
    // Local storage disabled. We rely on the backend API.
  }

  //---------------------CLEAR ALL BOOKED RIDES (DISABLED)
  static Future<void> clearAllBookedRides() async {
    // Local storage disabled. We rely on the backend API.
  }
}

//---------------------GOOGLE PLACES AUTOCOMPLETE
class PlacesService {
  final String apiKey;

  PlacesService(this.apiKey);

  Future<List<Map<String, dynamic>>> getSuggestions(String input) async {
    final String url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey&components=country:in"
        '&key=$apiKey'
        '&components=country:in' // Restrict to India
        '&types=establishment|geocode';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data["status"] == "OK") {
        final predictions = data["predictions"] as List;
        return predictions
            .map(
              (p) => {
                "description": p["description"],
                "place_id": p["place_id"],
              },
            )
            .toList();
      } else {
        print("Google API error: ${data["status"]}");
        return [];
      }
    } else {
      print("HTTP error: ${response.statusCode}");
      return [];
    }
  }
}
