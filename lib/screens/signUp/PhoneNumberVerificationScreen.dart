import 'package:flutter/material.dart';
import '../service/Responsive.dart';

class PhoneNumberVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  const PhoneNumberVerificationScreen({super.key, required this.phoneNumber});

  @override
  State<PhoneNumberVerificationScreen> createState() =>
      _PhoneNumberVerificationScreenState();
}

class _PhoneNumberVerificationScreenState extends State<PhoneNumberVerificationScreen> {
  final TextEditingController phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      resizeToAvoidBottomInset: true, // ✅ prevents overflow when keyboard shows
      backgroundColor: Colors.white,
      body: Form(
        key: _formKey,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: Responsive.h(5)),

                  // SizedBox(height: Responsive.h(18)),
                  const Image(
                    image: AssetImage("assets/images/logorideal.png"),
                  ),

                  const SizedBox(height: 5),
                  // Phone number input
                  PhoneNumberField(
                    controller: phoneController,
                  ),

                  const SizedBox(height: 24),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        // if (_formKey.currentState!.validate()) {
                        //   final phoneWithCode = phoneController.text;
                        //   bool isSuccess =
                        //       // await Authservices.registerUser(phoneWithCode);
                        //   if (isSuccess) {
                        //     Navigator.pushReplacement(
                        //       context,
                        //       MaterialPageRoute(
                        //         builder: (context) => OtpVerificationScreen(
                        //           phoneNumber: phoneWithCode,
                        //         ),
                        //       ),
                        //     );
                        //   }
                        // }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // WhatsApp updates checkbox
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Checkbox(
                        checkColor: Colors.white,
                        activeColor: Theme.of(context).primaryColor,
                        value: isChecked,
                        onChanged: (bool? value) {
                          setState(() {
                            isChecked = value ?? false;
                          });
                        },
                      ),
                      const Text("Get Order updates on Whatsapp"),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Terms & conditions
                  const Text(
                    "By verifying, you agree to our",
                    style: TextStyle(fontSize: 12),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Open terms & privacy
                    },
                    child: const Text(
                      "Terms & Conditions and Privacy Policy",
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PhoneNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isEnable;

  const PhoneNumberField({
    super.key,
    required this.controller,
    this.isEnable = true,
    this.hintText = 'Mobile Number*',
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      maxLength: 10,
      textAlign: TextAlign.left,
      enabled: isEnable,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 12, right: 8),
          child: Text(
            '',
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your mobile number';
        } else if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
          return 'Enter a valid 10-digit Indian number';
        }
        return null;
      },
    );
  }
}
