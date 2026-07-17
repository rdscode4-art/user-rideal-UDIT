import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatApiService {
  static const String baseUrl = 'https://backend.ridealmobility.com';

  /// Sends a chat message to the receiver.
  static Future<bool> sendMessage({
    required String rideId,
    required String receiverId,
    required String message,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        print("❌ Chat Error: No auth token found");
        return false;
      }

      final url = Uri.parse('$baseUrl/chat/send');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'rideId': rideId,
          'receiverId': receiverId,
          'message': message,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print("❌ Chat Send Error: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Chat Send Exception: $e");
      return false;
    }
  }

  /// Fetches the chat history for a specific ride.
  static Future<List<dynamic>> getChatHistory(String rideId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        print("❌ Chat Error: No auth token found");
        return [];
      }

      final url = Uri.parse('$baseUrl/chat/history?rideId=$rideId');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        
        if (decodedData is List) {
          return decodedData;
        } else if (decodedData is Map && decodedData['history'] is List) {
          return decodedData['history'];
        } else if (decodedData is Map && decodedData['data'] is List) {
          return decodedData['data'];
        } else if (decodedData is Map && decodedData['messages'] is List) {
          return decodedData['messages'];
        }
        
        return [];
      } else {
        print("❌ Chat History Error: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      print("❌ Chat History Exception: $e");
      return [];
    }
  }
}
