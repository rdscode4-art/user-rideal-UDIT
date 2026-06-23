import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String aboutustext = '''Rideal is a modern mobility platform dedicated to providing safe, reliable, and affordable rides for everyone. Built with a vision to transform the way India commutes, Rideal connects riders with trusted drivers through a seamless mobile experience. Our mission is not only to make travel more convenient but also to promote road safety, responsible driving, and community well-being.

At Rideal, we believe every journey matters. We are committed to supporting initiatives that prevent accidents, discourage unsafe practices such as drinking and driving, and encourage citizens to contribute towards safer roads. With innovative technology, transparent services, and a strong focus on customer trust, Rideal strives to be more than just a ride-sharing app — we aim to be a partner in building a safer and smarter Bharat.''';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // Rideal Logo in App Bar
            
            SizedBox(width: 12.w),
            Text(
              "About Us",
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section with Large Logo
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                  // Large Rideal Logo
                  Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(
                      
                      borderRadius: BorderRadius.circular(25.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Image.asset("assets/images/logorideal.png")
                  ),
                  SizedBox(height: 20.w),
                  
                  // Company Tagline
                  Text(
                    "Your Journey, Our Priority",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(height: 8.w),
                  Text(
                    "Making India's roads safer, one ride at a time",
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: 8.w),

            // About Content Section
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "About Rideal",
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16.w),
                  
                  Text(
                    aboutustext,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.black87,
                      height: 1.6.w,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 8.w),

            // Values Section
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Our Core Values",
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 20.w),
                  
                  _buildValueCard(
                    Icons.security,
                    "Safety First",
                    "Every ride is secured with safety protocols and trusted drivers",
                    Colors.red,
                  ),
                  SizedBox(height: 16.w),
                  
                  _buildValueCard(
                    Icons.handshake,
                    "Reliability",
                    "Consistent and dependable service you can count on",
                    Colors.blue,
                  ),
                  SizedBox(height: 16.w),
                  
                  _buildValueCard(
                    Icons.eco,
                    "Sustainability",
                    "Contributing to a greener future through shared mobility",
                    Colors.green,
                  ),
                ],
              ),
            ),

            SizedBox(height: 8.w),

            // Patriotic Section
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade100,
                          Colors.white,
                          Colors.green.shade100,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      children: [
                        AutoSizeText(
                          "🇮🇳वंदे मातरम🇮🇳",
                          style: TextStyle(
                            fontSize: 40.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          minFontSize: 16,
                          overflow: TextOverflow.visible,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12.w),
                        Text(
                          "Proud to serve Bharat",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.w),
          ],
        ),
      ),
    );
  }

  Widget _buildValueCard(IconData icon, String title, String description, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.w),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}