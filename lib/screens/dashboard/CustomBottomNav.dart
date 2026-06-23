import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_nav_bar/google_nav_bar.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.home,
      // Icons.wallet,
      Icons.feed,
      Icons.time_to_leave,
      Icons.person,
    ];
    final labels = [
      'Home',
      // 'Wallet',
      'RiDeal Feed',
      'Future Rides',
      'Profile',
    ];

    return SafeArea(
      child: Container(
        margin: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 15.w), // Reduced horizontal margins
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5.w),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.w), // Reduced horizontal padding
              child: GNav(
            selectedIndex: currentIndex,
            onTabChange: onTap,
            rippleColor: Colors.grey.shade100,
            hoverColor: Colors.grey.shade50,
            haptic: true,
            tabBorderRadius: 20,
            curve: Curves.easeOutExpo,
            duration: const Duration(milliseconds: 400),
            gap: 6, // Slightly reduced gap
            color: Colors.grey.shade500,
            activeColor: const Color(0xFF0F9D58),
            iconSize: 24,
            tabBackgroundColor: const Color(0xFF0F9D58).withOpacity(0.1),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.w), // Reduced horizontal padding
            tabs: List.generate(4, (i) {
              return GButton(
                icon: icons[i],
                text: labels[i],
                textStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                  color: Color(0xFF0F9D58),
                ),
              );
            }),
          ),
            ),
          ),
        ),
      ),
    );
  }
}
