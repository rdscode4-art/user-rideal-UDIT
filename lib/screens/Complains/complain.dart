import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:rideal/authservices.dart';

class ComplainScreen extends StatefulWidget {
  final String rideId;
  const ComplainScreen({super.key, required this.rideId});

  @override
  State<ComplainScreen> createState() => _ComplainScreenState();
}

class _ComplainScreenState extends State<ComplainScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController messageController = TextEditingController();
  bool isLoading = false;
  String selectedReason = 'Vehicle not clean';
  int characterCount = 0;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const Color brandGreen = Color(0xFF0F9D58);

  final List<Map<String, dynamic>> reasons = [
    {'label': 'Vehicle not clean', 'icon': Icons.cleaning_services_rounded},
    {'label': 'Driver rude', 'icon': Icons.sentiment_very_dissatisfied_rounded},
    {'label': 'Overcharged', 'icon': Icons.money_off_rounded},
    {'label': 'Late arrival', 'icon': Icons.timer_off_rounded},
    {'label': 'Wrong route', 'icon': Icons.wrong_location_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();

    messageController.addListener(() {
      setState(() {
        characterCount = messageController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    messageController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (messageController.text.isEmpty || messageController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Please write at least 10 characters"),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await Authservices.createTicket(
        selectedReason,
        messageController.text,
        widget.rideId,
      );
      setState(() => isLoading = false);
      messageController.clear();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const ComplaintSuccessDialog(),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: $e"),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              // Signature Custom Header Row
              Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      "Lodge a Complaint",
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(width: 40.w), // Balanced spacing
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    children: [
                      // Editorial Support Banner Card
                      Container(
                        width: double.infinity,
                        height: 110.w,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [brandGreen, Colors.green.shade700],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: [
                            BoxShadow(
                              color: brandGreen.withOpacity(0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Decorative circles
                            Positioned(
                              right: -20,
                              top: -20,
                              child: Container(
                                width: 130.w,
                                height: 130.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.06),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 80.w,
                              bottom: -30,
                              child: Container(
                                width: 90.w,
                                height: 90.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.04),
                                ),
                              ),
                            ),
                            // Main content
                            Padding(
                              padding: EdgeInsets.all(20.w),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12.w),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(16.r),
                                    ),
                                    child: Icon(
                                      Icons.support_agent_rounded,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  ),
                                  SizedBox(width: 16.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'We take complains seriously',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16.sp,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        SizedBox(height: 4.w),
                                        Text(
                                          'Ride ID: ${widget.rideId}',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.85),
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.w),

                      // Issue selection card
                      Container(
                        padding: EdgeInsets.all(20.w),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: brandGreen.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.category_rounded,
                                    color: brandGreen,
                                    size: 18,
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Text(
                                  'Select Issue Type',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 18.w),
                            ...reasons.map((reason) {
                              final isSelected = selectedReason == reason['label'];
                              return GestureDetector(
                                onTap: () => setState(() => selectedReason = reason['label']),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: EdgeInsets.only(bottom: 10.w),
                                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.w),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? brandGreen.withOpacity(0.04)
                                        : const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                      color: isSelected ? brandGreen : Colors.grey.shade100,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8.w),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? brandGreen.withOpacity(0.1)
                                              : Colors.grey.shade200,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          reason['icon'] as IconData,
                                          size: 16,
                                          color: isSelected ? brandGreen : Colors.grey.shade500,
                                        ),
                                      ),
                                      SizedBox(width: 14.w),
                                      Expanded(
                                        child: Text(
                                          reason['label'] as String,
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                            color: isSelected ? Colors.black87 : Colors.black54,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: brandGreen,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.w),

                      // Describe Issue card
                      Container(
                        padding: EdgeInsets.all(20.w),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8.w),
                                      decoration: BoxDecoration(
                                        color: brandGreen.withOpacity(0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.edit_note_rounded,
                                        color: brandGreen,
                                        size: 18,
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Text(
                                      'Describe Your Issue',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black87,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '$characterCount char',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                    color: characterCount >= 10 ? brandGreen : Colors.orange.shade600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 18.w),
                            Focus(
                              child: Builder(
                                builder: (context) {
                                  final isFocused = Focus.of(context).hasFocus;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F9FA),
                                      borderRadius: BorderRadius.circular(18.r),
                                      border: Border.all(
                                        color: isFocused ? brandGreen : Colors.grey.shade100,
                                        width: isFocused ? 1.5 : 1,
                                      ),
                                    ),
                                    child: TextField(
                                      controller: messageController,
                                      minLines: 4,
                                      maxLines: 7,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Write your complaint here (min. 10 characters)...',
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

                      SizedBox(height: 28.w),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 56.w,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submitTicket,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28.r),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width: 22.w,
                                  height: 22.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.send_rounded, size: 18),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Submit Complaint',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      SizedBox(height: 40.w),
                    ],
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

class ComplaintSuccessDialog extends StatelessWidget {
  const ComplaintSuccessDialog({super.key});

  static const Color brandGreen = Color(0xFF0F9D58);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
      child: Padding(
        padding: EdgeInsets.all(28.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                color: brandGreen.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: brandGreen,
                size: 54,
              ),
            ),
            SizedBox(height: 20.w),
            Text(
              'Complaint Submitted!',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 10.w),
            Text(
              'Your complaint has been sent successfully. Our team will review it shortly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14.sp,
                height: 1.5.w,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 26.w),
            SizedBox(
              width: double.infinity,
              height: 50.w,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text(
                  'Done',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
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