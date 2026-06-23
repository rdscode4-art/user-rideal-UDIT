import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';
import 'package:rideal/authservices.dart';
import 'package:rideal/emergencycontacts.dart';
import 'package:rideal/helpsupport.dart';
import 'package:rideal/model/ridermodel.dart';
import 'package:rideal/refundpolicypage.dart';
import 'package:rideal/screens/home/editprofilescreen.dart';
import 'package:rideal/screens/settings/privacypolicy.dart';
import 'package:flutter/material.dart';
import 'package:rideal/intro/Intropage.dart';
import 'package:rideal/screens/RideHistory/ridehistory.dart';
import 'package:rideal/screens/home/aboutus.dart';
import 'package:rideal/screens/home/termsconditions.dart';
import 'package:rideal/screens/wallet/wallet.dart';

class CustomDrawer extends StatefulWidget {
  final Future<bool> Function()? logoutUser;
  const CustomDrawer({
    super.key,
    required this.logoutUser,
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
  
  
}

class _CustomDrawerState extends State<CustomDrawer> {
  Rider? rider;
  bool isLoading = true;
  String? cachedProfileImageBase64;

   @override
   void initState() {
     super.initState();
      _fetchProfile();
   }

  Future<void> _fetchProfile() async {
    // 1. Instantly read cached profile if available to display user name/phone immediately
    try {
      final cachedRider = await Authservices.getCachedRiderProfile();
      if (cachedRider != null) {
        if (mounted) {
          setState(() {
            rider = cachedRider;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("⚠️ Error loading cached profile in Drawer: $e");
    }

    // 2. Instantly read cached profile image (base64) to show the image immediately
    try {
      final cachedBase64 = await Authservices.getCachedProfileImageBase64();
      if (cachedBase64 != null && mounted) {
        setState(() {
          cachedProfileImageBase64 = cachedBase64;
        });
      }
    } catch (e) {
      print("⚠️ Error loading cached profile image in Drawer: $e");
    }

    // 3. Fetch the fresh profile data from the server in the background
    try {
      final riderId = await Authservices.getRiderId();
      if (riderId == null) {
        print("⚠️ No Rider ID found in storage.");
        if (mounted) setState(() => isLoading = false);
        return;
      }
      final fetchedRider = await Authservices.getRiderProfile(riderId);

      if (mounted) {
        setState(() {
          rider = fetchedRider;
          isLoading = false;
        });
      }

      // Update image cache base64 locally after server profile retrieval completes
      final updatedBase64 = await Authservices.getCachedProfileImageBase64();
      if (updatedBase64 != null && mounted) {
        setState(() {
          cachedProfileImageBase64 = updatedBase64;
        });
      }
    } catch (e) {
      print("❌ Error loading profile from server in Drawer: $e");
      if (rider == null && mounted) {
        setState(() => isLoading = false);
      }
    }
  }
  ImageProvider? _getProfileImage() {
    // 1. If base64 cached image is available, load it instantly from memory
    if (cachedProfileImageBase64 != null) {
      try {
        return MemoryImage(base64Decode(cachedProfileImageBase64!));
      } catch (e) {
        print("⚠️ Error decoding cached base64 image: $e");
      }
    }

    // 2. Fallback to network image
    if (rider?.profileImage != null && rider!.profileImage!.isNotEmpty) {
      if (rider!.profileImage!.startsWith('http')) {
        return NetworkImage(rider!.profileImage!);
      } else {
        return NetworkImage(
          'https://backend.ridealmobility.com${rider!.profileImage}',
        );
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.78,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(32.r),
            bottomRight: Radius.circular(32.r),
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button & logo row
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 8.0.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                      ),
                    ),
                    Image.asset(
                      "assets/images/logorideal.png",
                      height: 36.w,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.w),

              // Profile Section Card
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Editprofilescreen()),
                  );
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.w),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F9D58).withOpacity(0.04),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: const Color(0xFF0F9D58).withOpacity(0.08),
                      width: 1.5.w,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.grey.shade100,
                            backgroundImage: _getProfileImage(),
                            child: _getProfileImage() == null
                                ? Icon(Icons.person, color: Colors.grey, size: 28)
                                : null,
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rider?.name ?? "Guest User",
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.w),
                            Text(
                              rider?.phone != null && rider!.phone.isNotEmpty ? "+91 ${rider!.phone}" : "View Profile",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12.w),

              // Menu Items List
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(bottom: 24.w),
                  children: [
                    _buildDrawerItem(Icons.person_outline_rounded, "Edit Profile", context, const Editprofilescreen()),
                    _buildDrawerItem(Icons.chat_bubble_outline_rounded, "Help And Support", context, SupportChatScreen()),
                    _buildDrawerItem(Icons.history_rounded, "History", context, const History()),
                    _buildDrawerItem(Icons.account_balance_wallet_outlined, "Wallet", context, const Wallet()),
                    _buildDrawerItem(Icons.report_problem_outlined, "Refund Policy", context, RefundPolicyPage()),
                    _buildDrawerItem(Icons.description_outlined, "Terms And Conditions", context, const TermsAndConditionsScreen()),
                    _buildDrawerItem(Icons.emergency_outlined, "Emergency", context, EmergencyContactsScreen()),
                    _buildDrawerItem(Icons.info_outline_rounded, "About Us", context, const AboutUsScreen()),
                    _buildDrawerItem(Icons.security_rounded, "Privacy Policy", context, const PrivacyPolicyScreen()),
                    _buildDrawerItem(Icons.logout_rounded, "Logout", context, const IntroScreen()),                 
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, BuildContext context, Widget screen) {
    final isLogout = title == "Logout";
    final iconColor = isLogout ? Colors.red.shade600 : const Color(0xFF0F9D58);
    final bgColor = isLogout ? Colors.red.shade50 : const Color(0xFF0F9D58).withOpacity(0.08);
    final textColor = isLogout ? Colors.red.shade700 : Colors.black87;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.w),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        trailing: isLogout
            ? null
            : Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 20),
        onTap: () async {
          Navigator.pop(context);

          if (isLogout && widget.logoutUser != null) {
            bool success = await widget.logoutUser!();
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logout successful')),
              );
              // Delay to show snackbar before navigating
              await Future.delayed(const Duration(seconds: 1));
              Navigator.pushAndRemoveUntil( 
                context,
                MaterialPageRoute(builder: (_) => const IntroScreen()),
                (Route<dynamic> route) => false,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logout failed')),
              );
            }
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => screen),
            );
          }
        },
      ),
    );
  }
}