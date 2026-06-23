import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rideal/authservices.dart';
import 'package:rideal/screens/dashboard/BottomNavigation.dart';
import 'package:rideal/widget/OtpFileds.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  const OtpVerificationScreen({required this.phoneNumber, super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  List<TextEditingController> otpControllers = List.generate(6, (_) => TextEditingController());
  bool isLoading = false;
  

  int secondsRemaining = 30;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    timer?.cancel();
    setState(() => secondsRemaining = 30);
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsRemaining > 0) {
        setState(() => secondsRemaining--);
      } else {
        t.cancel();
      }
    });
  }

  Future<void> resendOtp() async {
    // Call your API to resend the OTP here
    await Authservices.requestOtp(widget.phoneNumber); // <-- make sure you have this method

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("OTP has been resent")),
    );

    startTimer();
  }

 Future<void> verifyOtp() async {
  final otpCode = otpControllers.map((c) => c.text).join();

  if (otpCode.length != 6) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please enter a valid 6-digit OTP")),
    );
    return;
  }

  setState(() => isLoading = true);
  
  String? fcmToken;
  try {
    fcmToken = await FirebaseMessaging.instance.getToken();
    print('FCM Token obtained: $fcmToken');
  } catch (e) {
    print('Error getting FCM token: $e');
    fcmToken = null;
  }
  
  final success = await Authservices.verifyOtp(
    widget.phoneNumber, 
    otpCode, 
    fcmToken ?? ''
  );

  setState(() => isLoading = false);

  if (success) {
    // ✅ Puri stack clear karke main screen par jao
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => BottomNavigationLogic()),
      (route) => false, // Sab previous routes remove ho jayengi
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Invalid OTP")),
    );
  }
}
  @override
  void dispose() {
    timer?.cancel();
    for (var c in otpControllers) {
      c.dispose();
    }
    super.dispose();
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
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
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
                      child: Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Text(
                    "Verify OTP",
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.w),
                child: Column(
                  children: [
                    // Floating card container for OTP form
                    Container(
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Enter verification code",
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8.w),
                          Text(
                            "We've sent a 6-digit code to ${widget.phoneNumber}",
                            style: TextStyle(fontSize: 14.sp, color: Colors.black54),
                          ),
                          SizedBox(height: 32.w),

                          OtpFields(controllers: otpControllers),
                          SizedBox(height: 24.w),

                          // Timer or Resend button row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Didn't receive the code?",
                                style: TextStyle(fontSize: 14.sp, color: Colors.black54),
                              ),
                              if (secondsRemaining > 0)
                                Text(
                                  "00:${secondsRemaining.toString().padLeft(2, '0')}",
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                )
                              else
                                TextButton(
                                  onPressed: resendOtp,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    "Resend OTP",
                                    style: TextStyle(
                                      color: Color(0xFF0F9D58),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          SizedBox(height: 32.w),
                          
                          // Verify button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : verifyOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F9D58),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16.w),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24.r),
                                ),
                                elevation: 0,
                              ),
                              child: isLoading
                                  ? SizedBox(
                                      width: 24.w,
                                      height: 24.w,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      "Verify & Proceed",
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40.w),

                    // Terms footer
                    Center(
                      child: Column(
                        children: [
                          Text(
                            "By continuing, you agree to our",
                            style: TextStyle(fontSize: 12.sp, color: Colors.black38),
                          ),
                          SizedBox(height: 4.w),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              "Terms & Conditions and Privacy Policy",
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.w),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
