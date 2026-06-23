import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rideal/screens/signUp/SignInScreen.dart';
import 'package:flutter/material.dart';

import '../screens/signUp/PersonalDetailScreen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              
      SizedBox(height: 20.w),
                  Image.asset(
                    "assets/images/logorideal.png",
                    height: size.height * 0.15,
                  ),
                  // SizedBox(height: 5.w),
              // Illustration Image
              Image.asset(
                'assets/images/intro1green.png',
                height: size.height * 0.4,
              ),

              // Text Section
              Column(
                children: [
                  FittedBox(
  fit: BoxFit.scaleDown,
  child: Text(
    'Drive Smart. Ride Safe. Go Green With RiDeal',
    style: TextStyle(
      fontSize: 24.sp,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    ),
  ),
)
,
                  SizedBox(height: 8.w),
                  Text(
                    'Have a better sharing experience',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.sp, color: Colors.black45),
                  ),
                ],
              ),

              // Buttons Section
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: EdgeInsets.symmetric(vertical: 16.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PersonalDetailScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Create an account',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.w),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.w),
                        side: BorderSide(color: Colors.green.shade700),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(context,MaterialPageRoute(builder: (context)=>SignInScreen()));
                      },
                      child: Text(
                        'Log In',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.w),
            ],
          ),
        ),
      ),
    );
  }
}
