import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rideal/authservices.dart';
import 'package:rideal/screens/dashboard/BottomNavigation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key, required this.rideId});
  final String rideId;

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _rating = 0;
  bool _isLoading = false;
  String? rideId;
  final TextEditingController _feedbackController = TextEditingController();
  int feedbackLength = 0;

  static const Color brandGreen = Color(0xFF0F9D58);

  @override
  void initState() {
    super.initState();
    getRideId();
    _feedbackController.addListener(() {
      setState(() {
        feedbackLength = _feedbackController.text.length;
      });
    });
  }

  void getRideId() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedId = prefs.getString('rideId');
    setState(() {
      rideId = savedId;
    });
    print("RIDE ID-------$rideId");
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Please select a rating"),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
      );
      return;
    }

    final activeRideId = (rideId != null && rideId!.isNotEmpty) ? rideId! : widget.rideId;
    if (activeRideId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Ride ID not found"),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Authservices.rateRide(
        rideId: activeRideId,
        rating: _rating,
        feedback: _feedbackController.text.trim(),
      );

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("💚 Rating submitted successfully!"),
          backgroundColor: brandGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => BottomNavigationLogic()),
        (route) => false,
      );

    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to submit rating: $e"),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
      );
    }
  }

  String getRatingText(int rating) {
    switch (rating) {
      case 1:
        return "Very Bad..";
      case 2:
        return "Bad..";
      case 3:
        return "OK..";
      case 4:
        return "OK, but had an issue..";
      case 5:
        return "Perfect!!!";
      default:
        return "Tap to rate";
    }
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
              padding: EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(10.w),
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
                      ),
                      child: Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                    ),
                  ),
                  Text(
                    "Rate Your Ride",
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(width: 40.w), // spacer for balance
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Floating Card Container
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.w),
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Dynamic sentiment icon with premium glow
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: EdgeInsets.all(18.w),
                            decoration: BoxDecoration(
                              color: _rating == 5
                                  ? Colors.green.shade50
                                  : _rating >= 3
                                      ? Colors.blue.shade50
                                      : _rating > 0
                                          ? Colors.orange.shade50
                                          : brandGreen.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _rating == 5
                                  ? Icons.sentiment_very_satisfied_rounded
                                  : _rating >= 3
                                      ? Icons.sentiment_satisfied_rounded
                                      : _rating > 0
                                          ? Icons.sentiment_dissatisfied_rounded
                                          : Icons.rate_review_outlined,
                              color: _rating == 5
                                  ? Colors.green
                                  : _rating >= 3
                                      ? Colors.blue
                                      : _rating > 0
                                          ? Colors.orange
                                          : brandGreen,
                              size: 44,
                            ),
                          ),
                          SizedBox(height: 20.w),

                          Text(
                            "How was your ride?",
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 6.w),
                          Text(
                            "Your feedback helps us improve",
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          SizedBox(height: 28.w),

                          // Stars Rating Selector
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              final isSelected = index < _rating;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _rating = index + 1;
                                  });
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                                  child: AnimatedScale(
                                    scale: isSelected ? 1.15 : 1.0,
                                    duration: const Duration(milliseconds: 150),
                                    child: Icon(
                                      isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                                      color: isSelected ? Colors.amber.shade600 : Colors.grey.shade300,
                                      size: 46,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),

                          SizedBox(height: 12.w),

                          // Dynamic rating label
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              getRatingText(_rating),
                              key: ValueKey<int>(_rating),
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                                color: _rating > 0 ? Colors.amber.shade800 : Colors.grey.shade400,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),

                          SizedBox(height: 28.w),

                          // Feedback input field with active highlight
                          Focus(
                            child: Builder(
                              builder: (context) {
                                final isFocused = Focus.of(context).hasFocus;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(
                                      color: isFocused ? brandGreen : Colors.grey.shade100,
                                      width: isFocused ? 1.5 : 1,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _feedbackController,
                                    maxLines: 4,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: "Write feedback (optional)...",
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.all(16.w),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20.w),

                    // Submit Button
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56.w,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitRating,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28.r),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 22.w,
                                  height: 22.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  "Submit Rating",
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    SizedBox(height: 12.w),

                    // Skip button
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            },
                      child: Text(
                        "Skip for now",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(height: 30.w),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
}