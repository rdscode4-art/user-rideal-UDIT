import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

import 'onboardScreen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  int currentIndex = 0;

  final List<Map<String, String>> pages = [
    {
      'image': 'assets/images/intro1green.png',
      'title': 'Book Ride Anytime,Anywhere',
      'subtitle':
          'Get a ride in minutes with our easy-to-use app.\n No more waiting, just ride!',
    },
    {
      'image': 'assets/images/intro1green.png',
      'title': 'Book a Ride',
      'subtitle':
          'Find a taxi near your location and get going within minutes.',
    },
    // {
    //   'image': 'assets/images/introImage3.png',
    //   'title': 'Track Everything',
    //   'subtitle': 'Track your rides in real-time and stay safe and updated.',
    // },
  ];

  void nextPage() {
    if (currentIndex < pages.length - 1) {
      setState(() {
        currentIndex++;
      });
    } else {
      // Navigate to next screen (e.g., login)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final page = pages[currentIndex];

    return UpgradeAlert(
      showIgnore: false,
      showLater: false,
      barrierDismissible: false,
      upgrader: Upgrader(
        durationUntilAlertAgain: const Duration(seconds: 1),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 20.w),
                  Image.asset(
                    "assets/images/logorideal.png",
                    height: size.height * 0.15,
                  ),
                  SizedBox(height: 10.w),
                  Center(
                    child: Image.asset(
                      page['image']!,
                      height: size.height * 0.35,
                    ),
                  ),

                  SizedBox(height: 40.w),

                  Text(
                    page['title']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: 16.w),

                  Text(
                    page['subtitle']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.black45,
                      height: 1.5.w,
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              top: 16.w,
              right: 24.w,
              child: TextButton(
                onPressed: () {
                  // Skip to last page or directly navigate
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WelcomeScreen(),
                    ),
                  );
                },
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 32.w,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: nextPage,
                  child: Container(
                    width: 60.w,
                    height: 60.w,
                    decoration:  BoxDecoration(
                      color: Colors.green.shade800,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: currentIndex == pages.length - 1
                          ? Text(
                              'Go',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
