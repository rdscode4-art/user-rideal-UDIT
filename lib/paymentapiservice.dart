import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  static const String baseUrl = 'https://backend.ridealmobility.com';

  // Create Razorpay order
  // Maybe the endpoint should be different for completed rides?
  static Future<Map<String, dynamic>?> createRazorpayOrder({
    required String rideId,
    required String token,
  }) async {
    try {
      // Try different endpoint for completed rides
      final response = await http.post(
        Uri.parse(
          '$baseUrl/rides/rider/pay',
        ), // or maybe '/rides/completed/pay'
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'rideId': rideId,
          'status': 'completed', // Maybe need to specify status
        }),
      );

      print('🔍 Payment order response status: ${response.statusCode}');
      print('🔍 Payment order response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error creating order: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception in createRazorpayOrder: $e');
      return null;
    }
  }

  // Verify payment
  static Future<bool> verifyPayment({
    required String rideId,
    required String orderId,
    required String paymentId,
    required String signature,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rides/rider/verify-payment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'rideId': rideId,
          'orderId': orderId,
          'paymentId': paymentId,
          'signature': signature,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Exception in verifyPayment: $e');
      return false;
    }
  }

  // Get ride details
  // Add this to PaymentService.getRideDetails method
  static Future<Map<String, dynamic>?> getRideDetails({
    required String rideId,
    required String token,
  }) async {
    try {
      final url = '$baseUrl/rides/$rideId';
      print('🌐 PaymentScreen calling API: $url');
      print('🔑 Token present: ${token.isNotEmpty ? "Yes" : "No"}');
      print('🆔 RideId: $rideId');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json', // Add this header
        },
      );

      print('📡 PaymentScreen API Response status: ${response.statusCode}');
      print('📡 PaymentScreen API Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('❌ PaymentScreen API Error - Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ PaymentScreen API Exception: $e');
      return null;
    }
  }
}
