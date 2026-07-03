import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'meta_events_service.dart';

class WalletAuthServices {
  static const String baseUrl = 'https://backend.ridealmobility.com';
  static const String tokenKey = 'auth_token';

  // Save token after login or OTP verification
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  // Get token anywhere in the app
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  // Fetch wallet balance from API
  static Future<Map<String, dynamic>?> getWalletBalance() async {
    try {
      final token = await getToken();
      if (token == null) {
        return null;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/auth/wallet'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        print('❌ Failed to fetch wallet balance: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching wallet balance: $e');
      return null;
    }
  }

  // 1. CREATE ORDER for wallet top-up
  static Future<Map<String, dynamic>?> createWalletOrder(double amount) async {
    try {
      final token = await getToken();
      if (token == null) {
        print('❌ No auth token found');
        return null;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/wallet/add'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'amount': (amount ).toInt(), // Convert to paise properly
        }),
      );

      print('🔍 Wallet Order Response Status: ${response.statusCode}');
      print('🔍 Wallet Order Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Wallet order created: ${data['orderId']}');
        return data;
      } else {
        print('❌ Failed to create wallet order: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error creating wallet order: $e');
      return null;
    }
  }

  // Add money to wallet (placeholder - implement based on your API)
  static Future<bool> addMoney(double amount, String paymentId) async {
    try {
      final token = await getToken();
      if (token == null) {
        print('No auth token found');
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/wallet/add'), // Adjust endpoint as needed
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'amount': amount, 'paymentId': paymentId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Money added successfully to wallet');
        await MetaEventsService.logWalletTopup(amount: amount);
        return true;
      } else {
        print('Failed to add money: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error adding money: $e');
      return false;
    }
  }

  // Verify payment and add money to wallet
  // 2. VERIFY wallet payment
  static Future<bool> verifyWalletPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        print('❌ No auth token found');
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/wallet/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "razorpay_order_id": razorpayOrderId,
          "razorpay_payment_id": razorpayPaymentId,
          "razorpay_signature": razorpaySignature,
        }),
      );

      print("🟢 Wallet Verify - orderId: $razorpayOrderId");
      print("🟢 Wallet Verify - paymentId: $razorpayPaymentId");
      print("🟢 Wallet Verify - signature: $razorpaySignature");
      print("🔍 Wallet Verify Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print("❌ Wallet Verify Error: $e");
      return false;
    }
  }

  // 4. CREATE ORDER for ride payment (existing)
  static Future<Map<String, dynamic>?> createRideOrder({
    required String rideId,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        print('❌ No auth token found');
        return null;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/rides/complete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'rideId': rideId,
          'paymentMethod': 'online', // This creates Razorpay order
        }),
      );

      print('🔍 Ride Order Response Status: ${response.statusCode}');
      print('🔍 Ride Order Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('❌ Error creating ride order: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception in createRideOrder: $e');
      return null;
    }
  }

  // 5. VERIFY ride payment
  static Future<bool> verifyRidePayment({
    required String rideId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        print('❌ No auth token found');
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/rides/verify-payment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "rideId": rideId,
          "razorpay_order_id": razorpayOrderId,
          "razorpay_payment_id": razorpayPaymentId,
          "razorpay_signature": razorpaySignature,
        }),
      );

      print("🟢 Ride Verify Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print("❌ Ride Verify Error: $e");
      return false;
    }
  }

  // 6. COMPLETE RIDE with wallet payment (no Razorpay)
  static Future<bool> payRideViaWallet({required String rideId}) async {
    try {
      final token = await getToken();
      if (token == null) {
        print('❌ No auth token found');
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/rides/rider/wallet-pay'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'rideId': rideId,
          'paymentMethod': 'wallet', // This deducts from wallet directly
        }),
      );

      print("🔍 Wallet Payment Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print("❌ Wallet Payment Error: $e");
      return false;
    }
  }
}
