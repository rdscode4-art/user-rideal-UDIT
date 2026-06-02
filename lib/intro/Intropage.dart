import 'package:flutter/material.dart';

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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Image.asset(
                    "assets/images/logorideal.png",
                    height: size.height * 0.15,
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Image.asset(
                      page['image']!,
                      height: size.height * 0.35,
                    ),
                  ),

                  const SizedBox(height: 40),

                  Text(
                    page['title']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    page['subtitle']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black45,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              top: 16,
              right: 24,
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
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: nextPage,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration:  BoxDecoration(
                      color: Colors.green.shade800,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: currentIndex == pages.length - 1
                          ? const Text(
                              'Go',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
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
    );
  }
}
