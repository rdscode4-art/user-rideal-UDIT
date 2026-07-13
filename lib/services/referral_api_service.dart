import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rideal/authservices.dart';
import 'package:rideal/model/referral_model.dart';

class ReferralApiService {
  static Future<ReferralResponse?> fetchReferralData() async {
    try {
      final token = await Authservices.getToken();

      if (token == null) {
        print("❌ No auth token found for referrals.");
        return null;
      }

      final url = Uri.parse('${Authservices.baseUrl}/api/auth/referrals');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        return ReferralResponse.fromJson(decodedData);
      } else {
        print("❌ Failed to fetch referrals. Status Code: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Error fetching referrals: $e");
      return null;
    }
  }
}
