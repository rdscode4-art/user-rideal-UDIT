import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  State<TermsAndConditionsScreen> createState() => _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  String texttermsandconditions = '''
1. Acceptance of Terms
By downloading, accessing, or using the Rideal application, you agree to be bound by these Terms and Conditions. If you do not agree, you must refrain from using the App.

2. Compliance with Law
Users agree to strictly adhere to all applicable traffic laws, motor vehicle regulations, and public safety rules in India while using Rideal.

3. Prohibited Conduct
The following actions are strictly prohibited and will result in immediate suspension or termination of User access to the App without notice:
• Operating a vehicle under the influence of alcohol, drugs, or any other intoxicating substance.
• Engaging in reckless, dangerous, or unlawful driving practices.
• Misuse of the App for purposes contrary to law or public safety.

4. Suspension and Termination
If a User is found guilty of, or reasonably suspected of, involvement in drunk driving cases or any activity jeopardizing road safety, Rideal reserves the right to suspend or permanently terminate the User's account immediately.

5. Commitment to Public Safety
Rideal is committed to supporting national efforts to prevent road accidents and unlawful activities on Indian roads. By using the App, Users acknowledge their duty as responsible citizens and agree to cooperate in making Bharat's roads safer for all.

6. Limitation of Liability
Rideal shall not be held liable for any accidents, legal violations, or consequences arising out of the User's negligence, unlawful conduct, or violation of these Terms.

7. Amendments
Rideal reserves the right to modify or update these Terms at any time. Continued use of the App after such modifications constitutes acceptance of the revised Terms.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: Row(
          children: [
            // Rideal Logo
            
         
            SizedBox(width: 12.w),
            // Title
            Expanded(
              child: Text(
                "Terms & Conditions",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(0),
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  // Large Logo
                  Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Image.asset("assets/images/logorideal.png")
                  ),
                  SizedBox(height: 16.w),
                  Text(
                    "Terms & Conditions",
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8.w),
                  Text(
                    "Please read these terms carefully before using our service",
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
            
            // Content Section
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Last Updated Info
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                        SizedBox(width: 8.w),
                        Text(
                          "Last updated: ${DateTime.now().toString().substring(0, 10)}",
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24.w),
                  
                  // Terms Content
                  Text(
                    texttermsandconditions,
                    style: TextStyle(
                      fontSize: 15.sp,
                      height: 1.6.w,
                      color: Colors.black87,
                      letterSpacing: 0.2,
                    ),
                  ),
                  
                  SizedBox(height: 32.w),
                  
                  // // Contact Info
                  // Container(
                  //   padding: EdgeInsets.all(16.w),
                  //   decoration: BoxDecoration(
                  //     color: Colors.green.shade50,
                  //     borderRadius: BorderRadius.circular(12.r),
                  //     border: Border.all(color: Colors.green.shade200),
                  //   ),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       Row(
                  //         children: [
                  //           Icon(Icons.contact_support, color: Colors.green.shade600),
                  //           SizedBox(width: 8.w),
                  //           Text(
                  //             "Need Help?",
                  //             style: TextStyle(
                  //               fontSize: 16.sp,
                  //               fontWeight: FontWeight.bold,
                  //               color: Colors.green.shade700,
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //       SizedBox(height: 8.w),
                  //       Text(
                  //         "If you have any questions about these Terms and Conditions, please contact our support team.",
                  //         style: TextStyle(
                  //           fontSize: 14.sp,
                  //           color: Colors.grey.shade700,
                  //         ),
                  //       ),
                  //       SizedBox(height: 12.w),
                  //       Row(
                  //         children: [
                  //           Icon(Icons.email, size: 16, color: Colors.green.shade600),
                  //           SizedBox(width: 8.w),
                  //           Text(
                  //             "support@rideal.com",
                  //             style: TextStyle(
                  //               fontSize: 14.sp,
                  //               color: Colors.green.shade700,
                  //               fontWeight: FontWeight.w500,
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            ),
            
            SizedBox(height: 20.w),
          ],
        ),
      ),
    );
  }
}