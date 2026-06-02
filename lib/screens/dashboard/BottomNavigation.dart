import 'package:flutter/material.dart';
import 'package:rideal/intro/Intropage.dart';
import 'package:rideal/screens/CommunityFeed/communityfeed.dart';
import 'package:rideal/screens/FutureRides/FutureRides.dart';
import 'package:rideal/screens/home/home2.dart';
import 'package:rideal/screens/profile/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'CustomBottomNav.dart';

class BottomNavigationLogic extends StatefulWidget {
  final int currentIndex;
  const BottomNavigationLogic({super.key, this.currentIndex = 0});

  @override
  State<BottomNavigationLogic> createState() => _BottomNavigationLogicState();
}


class _BottomNavigationLogicState extends State<BottomNavigationLogic> {
  int currentIndex = 0;

  final List<Widget> _screens = [
    Home2(),
    // Wallet(),
    RiDealFeedScreen(),
    FutureRides(),
    Profile(),
  ];

  @override
  void initState() {
    super.initState();
    _checkLogin();
    currentIndex = widget.currentIndex;
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const IntroScreen()),
      );
    }
  }

  void onTabChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Enables the floating bottom nav effect
      body: _screens[currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentIndex,
        onTap: onTabChanged,
      ),
    );
  }
}
