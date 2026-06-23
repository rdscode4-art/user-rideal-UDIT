import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rideal/screens/signUp/PersonalDetailScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rideal/authservices.dart';
import 'otpverification.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  final phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const Color brandGreen = Color(0xFF0F9D58);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) return 'Please enter mobile number';
    String cleaned = value.replaceAll(RegExp(r'[\s\-\+]'), '');
    if (cleaned.startsWith('91') && cleaned.length > 10) cleaned = cleaned.substring(2);
    if (!RegExp(r'^[0-9]+$').hasMatch(cleaned)) return 'Only digits allowed';
    if (cleaned.length != 10) return 'Must be 10 digits';
    if (!RegExp(r'^[6-9]').hasMatch(cleaned)) return 'Must start with 6, 7, 8, or 9';
    return null;
  }

  Future<void> sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    String cleanedPhone = phoneController.text.replaceAll(RegExp(r'[\s\-\+]'), '');
    if (cleanedPhone.startsWith('91') && cleanedPhone.length > 10) {
      cleanedPhone = cleanedPhone.substring(2);
    }
    setState(() => isLoading = true);
    final success = await Authservices.requestOtp(cleanedPhone);
    setState(() => isLoading = false);
    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(phoneNumber: cleanedPhone),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send OTP. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Green hero background top section
          Container(
            height: size.height * 0.42,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [brandGreen, Color(0xFF34A853)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40.r),
                bottomRight: Radius.circular(40.r),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      children: [
                        SizedBox(height: 20.w),

                        // Back button row
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: EdgeInsets.all(9.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
                            ),
                          ),
                        ),

                        SizedBox(height: 24.w),

                        // Logo
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            "assets/images/logorideal.png",
                            height: 64.w,
                            width: 64.w,
                          ),
                        ),

                        SizedBox(height: 20.w),

                        // Hero text
                        Text(
                          'Welcome Back!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6.w),
                        Text(
                          'Sign in to continue your journey',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 14.sp,
                          ),
                        ),

                        SizedBox(height: 40.w),

                        // Card form
                        Container(
                          padding: EdgeInsets.all(28.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mobile Number',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 10.w),

                                // Phone input
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(14.r),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 14.w, vertical: 16.w),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            right: BorderSide(color: Colors.grey.shade200),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Text('🇮🇳', style: TextStyle(fontSize: 18.sp)),
                                            SizedBox(width: 6.w),
                                            Text(
                                              '+91',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15.sp,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: TextFormField(
                                          controller: phoneController,
                                          keyboardType: TextInputType.phone,
                                          validator: _validatePhoneNumber,
                                          maxLength: 10,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                            LengthLimitingTextInputFormatter(10),
                                          ],
                                          decoration: InputDecoration(
                                            hintText: '10-digit number',
                                            hintStyle: TextStyle(color: Colors.grey, fontSize: 14.sp),
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(horizontal: 14.w),
                                            counterText: '',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: 24.w),

                                // Send OTP button
                                SizedBox(
                                  width: double.infinity,
                                  height: 54.w,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: brandGreen,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14.r),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: isLoading ? null : sendOtp,
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
                                                'Send OTP',
                                                style: TextStyle(
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),

                                SizedBox(height: 20.w),

                                // Divider with "or"
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: Colors.grey.shade200)),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                                      child: Text(
                                        'or',
                                        style: TextStyle(color: Colors.grey.shade400, fontSize: 13.sp),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: Colors.grey.shade200)),
                                  ],
                                ),

                                SizedBox(height: 16.w),

                                // Sign up link
                                Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const PersonalDetailScreen(),
                                        ),
                                      );
                                    },
                                    child: RichText(
                                      text: TextSpan(
                                        text: "Don't have an account? ",
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14.sp),
                                        children: [
                                          TextSpan(
                                            text: 'Sign Up',
                                            style: TextStyle(
                                              color: brandGreen,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 32.w),

                        // Security note
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline_rounded, size: 14, color: Colors.grey.shade400),
                            SizedBox(width: 6.w),
                            Text(
                              'Your data is encrypted and secured',
                              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                        SizedBox(height: 24.w),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}