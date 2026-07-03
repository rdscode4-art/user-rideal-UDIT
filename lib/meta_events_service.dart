import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';

class MetaEventsService {
  static final FacebookAppEvents _facebookAppEvents = FacebookAppEvents();

  static Future<void> initialize() async {
    try {
      await _facebookAppEvents.setAutoLogAppEventsEnabled(true);
      await _facebookAppEvents.setAdvertiserTracking(
        enabled: true,
      ); // Required for iOS 14+
      print("✅ Meta App Events initialized successfully.");
    } catch (e) {
      print("❌ Failed to initialize Meta App Events: $e");
    }
  }

  // 1. Log App Activate
  static Future<void> logAppActivate() async {
    try {
      // The SDK typically handles this automatically when auto log is true,
      // but we can manually force a log if needed.
      // await _facebookAppEvents.logEvent(name: 'fb_mobile_activate_app');
    } catch (e) {
      print("Error logging app activate: $e");
    }
  }

  // 2. Log Login
  static Future<void> logLogin({String? method}) async {
    try {
      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_login',
        parameters: {if (method != null) 'method': method},
      );
      print("✅ Logged Meta Event: Login");
    } catch (e) {
      print("Error logging login: $e");
    }
  }

  // 3. Log Registration
  static Future<void> logRegistration({String? registrationMethod}) async {
    try {
      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_complete_registration',
        parameters: {
          if (registrationMethod != null)
            'registration_method': registrationMethod,
        },
      );
      print("✅ Logged Meta Event: Complete Registration");
    } catch (e) {
      print("Error logging registration: $e");
    }
  }

  // 4. Log Ride Booking
  static Future<void> logRideBooking({
    required String rideId,
    required double price,
    String rideType = 'Future',
  }) async {
    try {
      await _facebookAppEvents.logPurchase(
        amount: price,
        currency: "INR",
        parameters: {
          'content_type': 'Ride_Booking',
          'content_id': rideId,
          'ride_type': rideType,
        },
      );
      await _facebookAppEvents.logEvent(
        name: 'Ride_Booking',
        parameters: {'rideId': rideId, 'price': price, 'rideType': rideType},
      );
      print("✅ Logged Meta Event: Ride Booking & Purchase for $price INR");
    } catch (e) {
      print("Error logging ride booking: $e");
    }
  }

  // 5. Log Payment (Wallet Top-up)
  static Future<void> logWalletTopup({required double amount}) async {
    try {
      // Log as a purchase as well
      await _facebookAppEvents.logPurchase(
        amount: amount,
        currency: "INR",
        parameters: {'content_type': 'Wallet_Recharge'},
      );
      await _facebookAppEvents.logEvent(
        name: 'Wallet_Recharge',
        parameters: {'amount': amount},
      );
      print("✅ Logged Meta Event: Wallet Recharge for $amount INR");
    } catch (e) {
      print("Error logging wallet topup: $e");
    }
  }
}
