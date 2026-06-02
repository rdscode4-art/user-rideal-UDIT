import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rideal/model/promocodemodel.dart';

class PromoCodeService {
  static const String baseUrl = "https://backend.ridealmobility.com";

  // Get all available promo codes for a specific ride type and amount
  static Future<List<PromoCode>> getAvailablePromoCodes({
    required String rideType,
    required double estimatedAmount,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      if (token == null) {
        print("❌ No auth token found");
        return [];
      }

      final url = Uri.parse(
        "$baseUrl/api/promo-codes/available?rideType=$rideType&estimatedAmount=$estimatedAmount",
      );

      print("🎟️ Fetching promo codes:");
      print("  - URL: $url");
      print("  - Ride Type: $rideType");
      print("  - Amount: $estimatedAmount");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("📥 Promo codes response: ${response.statusCode}");
      print("📥 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Backend sends: { "success": true, "data": [...] }
        List<dynamic> promoCodesJson = [];

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data') &&
              responseData['data'] is List) {
            promoCodesJson = responseData['data'];
          } else if (responseData.containsKey('promoCodes')) {
            promoCodesJson = responseData['promoCodes'];
          }
        } else if (responseData is List) {
          promoCodesJson = responseData;
        }

        final promoCodes =
            promoCodesJson
                .map((json) => PromoCode.fromJson(json as Map<String, dynamic>))
                .toList();

        print("✅ Fetched ${promoCodes.length} promo codes");
        for (var promo in promoCodes) {
          print("  📌 ${promo.code} - ${promo.description}");
        }
        return promoCodes;
      } else {
        print("❌ Failed to fetch promo codes: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ Error fetching promo codes: $e");
      print("🔍 Stack trace: ${StackTrace.current}");
      return [];
    }
  }

  // Validate a promo code before applying
  static Future<ValidatePromoResponse?> validatePromoCode({
    required String code,
    required double originalAmount,
    required String rideType,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      if (token == null) {
        print("❌ No auth token found");
        return ValidatePromoResponse(
          valid: false,
          message: "Authentication required",
        );
      }

      final url = Uri.parse("$baseUrl/api/promo-codes/validate");

      final request = ValidatePromoRequest(
        code: code,
        originalAmount: originalAmount,
        rideType: rideType,
      );

      print("🔍 Validating promo code:");
      print("  - Code: $code");
      print("  - Amount: $originalAmount");
      print("  - Ride Type: $rideType");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(request.toJson()),
      );

      print("📥 Validation response: ${response.statusCode}");
      print("📥 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        print("🔍 Parsing validation response:");
        print("  - Full response: $responseData");

        // Handle backend response format
        Map<String, dynamic> data = responseData;
        if (responseData.containsKey('data') && responseData['data'] is Map) {
          data = responseData['data'];
          print("  - Extracted data object: $data");
        }

        // Pass the entire responseData to include 'success' field
        final validationResponse = ValidatePromoResponse.fromJson(responseData);

        print("🔍 Parsed validation result:");
        print("  - Valid: ${validationResponse.valid}");
        print("  - Message: ${validationResponse.message}");
        print("  - Discount: ${validationResponse.discount}");

        if (validationResponse.valid) {
          print("✅ Promo code validated successfully");
          print("  - Code: ${validationResponse.discount?.code}");
          print(
            "  - Discount: ₹${validationResponse.discount?.discountAmount}",
          );
          print(
            "  - Final Amount: ₹${validationResponse.discount?.finalAmount}",
          );
        } else {
          print(
            "❌ Promo code validation failed: ${validationResponse.message}",
          );
        }

        return validationResponse;
      } else {
        print("❌ Failed to validate promo code: ${response.statusCode}");
        try {
          final errorData = jsonDecode(response.body);
          return ValidatePromoResponse(
            valid: false,
            message:
                errorData['message'] ??
                errorData['error'] ??
                'Validation failed',
          );
        } catch (e) {
          return ValidatePromoResponse(
            valid: false,
            message: 'Validation failed: ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      print("❌ Error validating promo code: $e");
      return ValidatePromoResponse(valid: false, message: "Error: $e");
    }
  }

  // Calculate discount amount based on promo code
  static double calculateDiscount({
    required PromoCode promoCode,
    required double originalAmount,
  }) {
    double discount = 0.0;

    if (promoCode.discountType == 'percentage') {
      discount = (originalAmount * promoCode.discountValue) / 100;

      // Apply max discount cap if exists
      if (promoCode.maxDiscount != null && discount > promoCode.maxDiscount!) {
        discount = promoCode.maxDiscount!;
      }
    } else if (promoCode.discountType == 'flat') {
      discount = promoCode.discountValue;
    }

    // Ensure discount doesn't exceed original amount
    if (discount > originalAmount) {
      discount = originalAmount;
    }

    return discount;
  }

  // Check if promo code is applicable for given ride type and amount
  static bool isPromoCodeApplicable({
    required PromoCode promoCode,
    required String rideType,
    required double amount,
  }) {
    // Check if active
    if (!promoCode.isActive) {
      return false;
    }

    // Check ride type
    if (promoCode.applicableRideTypes.isNotEmpty &&
        !promoCode.applicableRideTypes.contains(rideType)) {
      return false;
    }

    // Check minimum amount
    if (promoCode.minAmount != null && amount < promoCode.minAmount!) {
      return false;
    }

    // Check validity dates
    final now = DateTime.now();
    if (promoCode.validFrom != null && now.isBefore(promoCode.validFrom!)) {
      return false;
    }
    if (promoCode.validUntil != null && now.isAfter(promoCode.validUntil!)) {
      return false;
    }

    return true;
  }

  // Format discount text for display
  static String getDiscountText(PromoCode promoCode) {
    if (promoCode.discountType == 'percentage') {
      final percentText = '${promoCode.discountValue.toInt()}% OFF';
      if (promoCode.maxDiscount != null) {
        return '$percentText up to ₹${promoCode.maxDiscount!.toInt()}';
      }
      return percentText;
    } else {
      return 'Flat ₹${promoCode.discountValue.toInt()} OFF';
    }
  }
}
