import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  final List<Map<String, String>> _policyItems = const [
    {
      'title': '1. Information Collection',
      'content': 'We collect only the information necessary to provide mobility and utility services:\n\n• Personal Information: Name, phone number, email address\n• Location Data: Precise location only during active rides/duty for navigation, pickup, drop, fare calculation, and safety\n• Trip Information: Pickup/drop locations, trip history, fare details\n• Driver Information (Driver App): Driving License, Vehicle RC, vehicle details, profile photo (for verification & safety only)\n• Device Information: App version, device type, OS (for performance & security)\n\nMandatory vs Optional Data:\n• Mandatory: Phone number (for account creation), location (during rides)\n• Optional: Email address, profile photo\n\nYou can choose not to provide optional information, though some features may be limited.'
    },
    {
      'title': '2. Use of Information',
      'content': 'Your information is used strictly for:\n\n• Ride booking, assignment, and trip completion\n• Navigation, fare calculation, and service delivery\n• Driver and user verification for safety and fraud prevention\n• Customer support and dispute resolution\n• Legal and regulatory compliance\n• App functionality improvements\n\nWe do NOT use your data for:\n• Selling or renting to third parties\n• Unsolicited marketing or advertising\n• Profiling for purposes unrelated to service delivery'
    },
    {
      'title': '3. Location Data Usage',
      'content': 'RiDeal collects location data ONLY when required:\n\n• During an active ride (Customer App)\n• During active duty status (Driver App)\n\nLocation data is:\n• NOT collected when app is idle or driver is offline\n• NOT used for advertising or marketing\n• NOT tracked in the background unnecessarily\n• Automatically stopped after trip completion\n\nYou can revoke location permissions anytime through your device settings, but this will limit service functionality.'
    },
    {
      'title': '4. Data Sharing',
      'content': 'RiDeal does NOT sell or rent your personal data.\n\nData may be shared only with:\n• Trusted third-party service providers: Payment gateways (for transactions), map services (for navigation), SMS services (for OTP), analytics tools (for app performance)\n• Government/legal authorities: When required by law or for safety investigations\n\nAll third-party partners:\n• Are contractually bound to protect your data\n• Can only use data for specified purposes\n• Must comply with applicable data protection laws\n\nYou can request a list of our third-party partners by contacting us.'
    },
    {
      'title': '5. Your Rights & Data Control',
      'content': 'As a RiDeal user, you have the following rights:\n\n• Right to Access: Request a copy of your personal data\n• Right to Correction: Update or correct inaccurate information\n• Right to Deletion: Request account and data deletion (via app or email)\n• Right to Data Portability: Request your data in a machine-readable format\n• Right to Restrict Processing: Limit how we use your data\n• Right to Withdraw Consent: Revoke permissions at any time\n\nTo exercise these rights:\n• Use the "Delete Account" option in Settings, or\n• Email: info@ridealmobility.com\n• Response time: 7-10 working days (subject to legal requirements)\n\nNote: Some data may be retained for legal, safety, or regulatory compliance even after deletion requests.'
    },
    {
      'title': '6. Data Security',
      'content': 'We implement industry-standard security measures:\n\n• Encryption of sensitive data during transmission and storage\n• Secure authentication protocols\n• Regular security audits and vulnerability assessments\n• Access controls and employee training\n• Secure payment processing through certified gateways\n\nYour Responsibility:\n• Keep your login credentials confidential\n• Use strong passwords\n• Log out from shared devices\n• Report suspicious activity immediately\n\nData Breach Notification:\nIn the unlikely event of a data breach affecting your personal information, we will notify you within 72 hours via email, SMS, or in-app notification.'
    },
    {
      'title': '7. Data Retention & Deletion',
      'content': 'Personal data is retained only as long as necessary:\n\n• Active Users: Data retained while account is active\n• Inactive Users: Data may be anonymized or deleted after 3 years of inactivity\n• Trip Records: Retained for 5 years for legal and tax compliance\n• Driver Verification Documents: Retained as per regulatory requirements\n\nAccount Deletion:\n• Use in-app "Delete Account" option in Settings\n• Or email: info@ridealmobility.com\n• Processing time: 7-10 working days\n• Post-deletion: Some anonymized data may be retained for analytics\n\nNote: Deletion requests may be delayed if data is required for ongoing legal proceedings, disputes, or regulatory compliance.'
    },
    {
      'title': '8. Cookies & Tracking',
      'content': 'RiDeal apps may use:\n\n• Essential Cookies: For app functionality and security\n• Analytics: To understand app usage and improve performance (anonymized)\n• Device Identifiers: For fraud prevention and account security\n\nWe do NOT use:\n• Advertising cookies or trackers\n• Cross-app tracking for marketing purposes\n\nYou can manage tracking preferences through your device settings, though this may affect app functionality.'
    },
    {
      'title': '9. Children\'s Privacy',
      'content': 'RiDeal services are intended ONLY for individuals 18 years of age or older.\n\n• We do not knowingly collect data from minors\n• If we discover data from a minor has been collected, it will be deleted immediately\n• Parents/guardians can contact us if they believe a minor has provided information\n\nIf you are under 18, please do not use our services or provide any personal information.'
    },
    {
      'title': '10. Third-Party Links & Services',
      'content': 'Our app may contain links to third-party websites or integrate with third-party services (payment gateways, maps, etc.).\n\n• RiDeal is NOT responsible for the privacy practices of third parties\n• We encourage you to review their privacy policies\n• Third-party services have their own terms and conditions\n\nIntegrated Services:\n• Payment Gateways: For secure transactions\n• Map Services: For navigation and location\n• SMS Services: For OTP and notifications\n• Analytics Tools: For app performance (anonymized data only)'
    },
    {
      'title': '11. User Consent & Choices',
      'content': 'By using RiDeal, you provide explicit consent to:\n• Collection and processing of data as described\n• Use of location services during active rides\n• Communication via SMS, email, or push notifications\n\nYour Choices:\n• Opt-out of promotional communications (via Settings)\n• Disable location services (limits service functionality)\n• Refuse optional permissions\n• Delete your account anytime\n\nWithdrawing consent may limit or prevent access to certain features. You can withdraw consent at any time through app settings or by contacting us.'
    },
    {
      'title': '12. International Data Transfer',
      'content': 'RiDeal primarily operates in India. Your data is stored and processed within India on secure servers.\n\n• Data may be transferred to third-party service providers located outside India only when necessary for service delivery\n• All international transfers comply with applicable data protection laws\n• Adequate safeguards are in place to protect your data during transfer\n\nIf you are accessing RiDeal from outside India, your data may be transferred to India for processing.'
    },
    {
      'title': '13. Updates to This Policy',
      'content': 'RiDeal may update this Privacy Policy from time to time to reflect:\n• Changes in services or features\n• Legal or regulatory requirements\n• Security enhancements\n\nNotification of Changes:\n• Significant changes will be communicated via in-app notification, email, or SMS\n• Updated policy will be posted in the app\n• Continued use after changes constitutes acceptance\n\nLast Updated: 23 December 2025\n\nYou can view the policy version history by contacting us.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Floating Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
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
                      child: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                    ),
                  ),
                  const Text(
                    "Privacy Policy",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 40), // spacer for balance
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    // Intro Info Card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Logo with shadow
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.08),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logorideal.png',
                              height: 60,
                              width: 100,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Company name
                          Text(
                            'RiDeal Mobility Drive Pvt. Ltd.',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F9D58),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Effective date
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Effective Date: 23 December 2025',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Welcome text
                          const Text(
                            'Your Privacy Matters',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'At RiDeal Mobility Drive Pvt. Ltd. ("RiDeal", "we", "our", "us"), we are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, store, share, and protect your data when you use the RiDeal Customer App, RiDeal Driver App, or related services.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'You have complete control over your data, including the right to access, correct, and delete your information at any time.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F9D58).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'By using RiDeal, you agree to the practices described in this Privacy Policy',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F9D58),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Policy sections
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: _policyItems.map((item) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F9D58),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          item['title']!,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    item['content']!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.5,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Contact Information Section
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F9D58),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                '14. Contact Information',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'If you have any questions, concerns, or requests regarding this Privacy Policy or your personal data, please contact us:',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildContactItem(Icons.business_outlined, 'Company Name', 'RiDeal Mobility Drive Pvt. Ltd.'),
                          const SizedBox(height: 10),
                          _buildContactItem(Icons.location_on_outlined, 'Address', 'Ward No. 24, Kalikapur, Palabani Chhak\nMayurbhanj, Baripada, Odisha – 757001\nIndia'),
                          const SizedBox(height: 10),
                          _buildContactItem(Icons.email_outlined, 'Email', 'info@ridealmobility.com'),
                          const SizedBox(height: 10),
                          _buildContactItem(Icons.phone_outlined, 'Contact', '+91-9040545756'),
                          const SizedBox(height: 10),
                          _buildContactItem(Icons.public_outlined, 'Country', 'India'),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F9D58).withOpacity(0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF0F9D58).withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, color: Color(0xFF0F9D58), size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'For data deletion or correction requests, use the "Delete Account" option in Settings or email us directly.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade800,
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Footer with compliance badges
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFF0F9D58), Colors.green.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F9D58).withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            color: Colors.white,
                            size: 36,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Your Privacy, Our Priority',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'We use industry-standard security measures and give you full control over your data. Your information is never sold or used for purposes beyond providing you with safe, reliable mobility services.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildComplianceBadge('✓ User Rights Protected'),
                              _buildComplianceBadge('✓ Data Deletion Available'),
                              _buildComplianceBadge('✓ No Data Selling'),
                              _buildComplianceBadge('✓ Transparent Practices'),
                              _buildComplianceBadge('✓ Secure & Encrypted'),
                              _buildComplianceBadge('✓ India Based'),
                              _buildComplianceBadge('✓ Legal Compliant'),
                              _buildComplianceBadge('✓ 24/7 Support'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0F9D58)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComplianceBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}