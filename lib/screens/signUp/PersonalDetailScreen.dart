import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rideal/screens/signUp/otpverification.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rideal/authservices.dart';
import 'SignInScreen.dart';

class PersonalDetailScreen extends StatefulWidget {
  const PersonalDetailScreen({super.key});

  @override
  State<PersonalDetailScreen> createState() => _PersonalDetailScreenState();
}

class _PersonalDetailScreenState extends State<PersonalDetailScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _referralCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedGender;
  bool _isLoading = false;

  // Validate phone number
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter mobile number';
    }

    // Remove any spaces, dashes, or +91 prefix
    String cleaned = value.replaceAll(RegExp(r'[\s\-\+]'), '');
    
    // Remove country code if present
    if (cleaned.startsWith('91') && cleaned.length > 10) {
      cleaned = cleaned.substring(2);
    }

    // Check if it contains only digits
    if (!RegExp(r'^[0-9]+$').hasMatch(cleaned)) {
      return 'Mobile number must contain only digits';
    }

    // Check if it's exactly 10 digits
    if (cleaned.length != 10) {
      return 'Mobile number must be 10 digits';
    }

    // Check if it starts with valid digits (6-9)
    if (!RegExp(r'^[6-9]').hasMatch(cleaned)) {
      return 'Mobile number must start with 6, 7, 8, or 9';
    }

    return null;
  }

  // Validate name
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can only contain letters';
    }
    return null;
  }

  // Validate address
  String? _validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your address';
    }
    if (value.length < 5) {
      return 'Address must be at least 5 characters';
    }
    return null;
  }

  Future<void> _signUp() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your gender")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Clean phone number before sending
    String cleanedPhone = _phoneController.text.replaceAll(RegExp(r'[\s\-\+]'), '');
    if (cleanedPhone.startsWith('91') && cleanedPhone.length > 10) {
      cleanedPhone = cleanedPhone.substring(2);
    }

    final success = await Authservices.registerUser(
      cleanedPhone,
      _nameController.text.trim(),
      _selectedGender!,
      _addressController.text.trim(),
      referralCode: _referralCodeController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            phoneNumber: cleanedPhone,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration failed. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Floating Back Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                    ),
                  ),
                ),
                SizedBox(height: 24.w),
                
                // Logo in white circle with shadow
                Center(
                  child: Container(
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
                      height: size.height * 0.12,
                      width: size.height * 0.12,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: 32.w),
                
                Text(
                  'Sign up',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 24.w),

                // Name Field (Pill Shaped Container)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _nameController,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp),
                    decoration: InputDecoration(
                      hintText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline_rounded, color: Colors.black45),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.w),
                    ),
                    validator: _validateName,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                    ],
                  ),
                ),
                SizedBox(height: 16.w),

                // Phone Field (Pill Shaped Container)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp),
                    decoration: InputDecoration(
                      hintText: 'Mobile Number',
                      prefixIcon: Icon(Icons.phone_outlined, color: Colors.black45),
                      prefixText: '+91 ',
                      prefixStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp, color: Colors.black87),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.w),
                      counterText: '',
                    ),
                    validator: _validatePhoneNumber,
                    maxLength: 10,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),
                ),
                SizedBox(height: 16.w),

                // Address Field (Pill Shaped Container)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _addressController,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp),
                    decoration: InputDecoration(
                      hintText: 'Address',
                      prefixIcon: Icon(Icons.location_on_outlined, color: Colors.black45),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.w),
                    ),
                    validator: _validateAddress,
                    maxLines: 2,
                  ),
                ),
                SizedBox(height: 16.w),

                // Gender Field (Pill Shaped Container)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      hintText: 'Gender',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.people_outline_rounded, color: Colors.black45),
                      contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.w),
                    ),
                    value: _selectedGender,
                    items: ['Male', 'Female', 'Other']
                        .map((gender) =>
                            DropdownMenuItem(value: gender, child: Text(gender, style: TextStyle(fontWeight: FontWeight.w600))))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedGender = value);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select your gender';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 16.w),
                // Referral Code Field (Optional)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _referralCodeController,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp),
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Referral Code (Optional)',
                      prefixIcon: Icon(Icons.card_giftcard_rounded, color: Colors.black45),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.w),
                    ),
                  ),
                ),
                SizedBox(height: 32.w),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F9D58),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _signUp,
                    child: _isLoading
                        ? SizedBox(
                            width: 24.w,
                            height: 24.w,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 24.w),

                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.black12)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Text('or', style: TextStyle(color: Colors.black45)),
                    ),
                    Expanded(child: Divider(color: Colors.black12)),
                  ],
                ),
                SizedBox(height: 24.w),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ', style: TextStyle(color: Colors.black54)),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignInScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Sign in',
                        style: TextStyle(
                          color: Color(0xFF0F9D58),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.w),
              ],
            ),
          ),
        ),
      ),
    );
  }
}