import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';

class RefundPolicyPage extends StatefulWidget {
  const RefundPolicyPage({super.key});

  @override
  State<RefundPolicyPage> createState() => _RefundPolicyPageState();
}

class _RefundPolicyPageState extends State<RefundPolicyPage> {
  int? _expandedSection;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Refund Policy',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.green[700],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.green[700]!, Colors.green[700]!],
                ),
              ),
              child: Column(
                children: [
                  Image.asset("assets/images/logo.png",height: 120.w,),
                  SizedBox(height: 16.w),
                  Text(
                    'RiDeal Mobility Drive Private Limited',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.w),
                  Text(
                    'Refund & Cancellation Policy',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 16.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      'Effective Date: November 2025',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  // Introduction Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700], size: 28),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Text(
                              'We strive to provide transparent and fair refund policies for all our customers.',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[700],
                                height: 1.5.w,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16.w),

                  // Expandable Sections
                  _buildExpandableSection(
                    index: 0,
                    title: 'Ride Cancellation Refunds',
                    icon: Icons.cancel,
                    iconColor: Colors.orange,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSubsection(
                          'Passenger-Initiated Cancellations:',
                          [
                            'Free cancellation: Within 2 minutes of booking with 100% refund',
                            'After 2 minutes: ₹20 cancellation fee will be deducted',
                            'No-show: No refund if driver arrives at pickup location and passenger is unavailable',
                          ],
                        ),
                        SizedBox(height: 12.w),
                        _buildSubsection(
                          'Driver-Initiated Cancellations:',
                          [
                            'Full refund (100%) if driver cancels the ride',
                            'Refund processed automatically to original payment method',
                          ],
                        ),
                      ],
                    ),
                  ),

                  _buildExpandableSection(
                    index: 1,
                    title: 'Wallet & Payment Refunds',
                    icon: Icons.account_balance_wallet,
                    iconColor: Colors.green,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSubsection(
                          'Wallet Refunds:',
                          [
                            'Credited instantly to RiDeal wallet',
                            'Can be used for future rides immediately',
                            'No expiry on wallet balance',
                          ],
                        ),
                        SizedBox(height: 12.w),
                        _buildSubsection(
                          'Card/UPI Refunds:',
                          [
                            'Processing time: 5-7 business days',
                            'Refund to original payment method',
                            'Bank processing times may vary',
                          ],
                        ),
                      ],
                    ),
                  ),

                  _buildExpandableSection(
                    index: 2,
                    title: 'Overcharge & Technical Issues',
                    icon: Icons.error_outline,
                    iconColor: Colors.red,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSubsection(
                          'Overcharge Claims:',
                          [
                            'Report within 24 hours of ride completion',
                            'Submit through app support or email',
                            'Investigation period: 48-72 hours',
                            'Valid claims receive full refund of excess amount',
                          ],
                        ),
                        SizedBox(height: 12.w),
                        _buildSubsection(
                          'Technical Failures:',
                          [
                            'Multiple debits: Extra charges refunded within 7 days',
                            'App crashes during payment: Auto-refund if ride not confirmed',
                            'GPS/route issues: Case-by-case evaluation',
                          ],
                        ),
                      ],
                    ),
                  ),

                  _buildExpandableSection(
                    index: 3,
                    title: 'Promotional Credits & Offers',
                    icon: Icons.local_offer,
                    iconColor: Colors.purple,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBulletPoint(
                          'Promotional credits are non-refundable and non-transferable',
                        ),
                        _buildBulletPoint(
                          'Valid only for specified period mentioned in offer terms',
                        ),
                        _buildBulletPoint(
                          'Cannot be exchanged for cash',
                        ),
                        _buildBulletPoint(
                          'Expired credits cannot be reactivated or refunded',
                        ),
                      ],
                    ),
                  ),

                  _buildExpandableSection(
                    index: 4,
                    title: 'Subscription & Pass Refunds',
                    icon: Icons.card_membership,
                    iconColor: Colors.indigo,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSubsection(
                          'Monthly/Weekly Passes:',
                          [
                            'Full refund if cancelled within 24 hours of purchase (unused)',
                            'Pro-rated refund not available after usage begins',
                            'Auto-renewal can be cancelled anytime before next billing cycle',
                          ],
                        ),
                        SizedBox(height: 12.w),
                        _buildSubsection(
                          'Premium Subscriptions:',
                          [
                            'Cancellation allowed anytime',
                            'Benefits continue until end of paid period',
                            'No partial refunds for unused subscription days',
                          ],
                        ),
                      ],
                    ),
                  ),

                  _buildExpandableSection(
                    index: 5,
                    title: 'Refund Processing Timeline',
                    icon: Icons.schedule,
                    iconColor: Colors.teal,
                    content: Column(
                      children: [
                        _buildTimelineItem(
                          'RiDeal Wallet',
                          'Instant',
                          Colors.green,
                        ),
                        _buildTimelineItem(
                          'UPI',
                          '1-3 business days',
                          Colors.blue,
                        ),
                        _buildTimelineItem(
                          'Credit/Debit Card',
                          '5-7 business days',
                          Colors.orange,
                        ),
                        _buildTimelineItem(
                          'Net Banking',
                          '5-7 business days',
                          Colors.purple,
                        ),
                      ],
                    ),
                  ),

                  _buildExpandableSection(
                    index: 6,
                    title: 'Non-Refundable Scenarios',
                    icon: Icons.block,
                    iconColor: Colors.red[700]!,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBulletPoint(
                          'Completed rides that were taken as per booking',
                        ),
                        _buildBulletPoint(
                          'Late cancellations after driver has traveled significant distance',
                        ),
                        _buildBulletPoint(
                          'No-show by passenger after driver arrival',
                        ),
                        _buildBulletPoint(
                          'Rides cancelled due to passenger misconduct',
                        ),
                        _buildBulletPoint(
                          'Service fees and convenience charges',
                        ),
                        _buildBulletPoint(
                          'Expired promotional credits or vouchers',
                        ),
                      ],
                    ),
                  ),

                  _buildExpandableSection(
                    index: 7,
                    title: 'How to Request a Refund',
                    icon: Icons.support_agent,
                    iconColor: Colors.blue[700]!,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStepItem(1, 'Open the RiDeal app and go to "My Rides"'),
                        _buildStepItem(2, 'Select the ride you want to dispute'),
                        _buildStepItem(3, 'Tap on "Report an Issue" or "Request Refund"'),
                        _buildStepItem(4, 'Choose the appropriate reason'),
                        _buildStepItem(5, 'Submit with details and supporting evidence if any'),
                        SizedBox(height: 16.w),
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.email, color: Colors.blue[700], size: 20),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Or email us at:',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 4.w),
                                    Text(
                                      'support@ridealmobility.com',
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontSize: 13.sp,
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

                  SizedBox(height: 24.w),

                  // Important Notice Card
                  Card(
                    elevation: 2,
                    color: Colors.amber[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      side: BorderSide(color: Colors.amber[200]!),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber, color: Colors.amber[800], size: 28),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  'Important Notice',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.w),
                          Text(
                            'RiDeal Mobility Drive Private Limited reserves the right to modify this refund policy at any time. Changes will be communicated through the app and email. Continued use of our services after policy changes constitutes acceptance of the modified terms.',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey[800],
                              height: 1.5.w,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 25.w),

                  // Contact Card
                  // Card(
                  //   elevation: 3,
                  //   shape: RoundedRectangleBorder(
                  //     borderRadius: BorderRadius.circular(12.r),
                  //   ),
                  //   child: Padding(
                  //     padding: EdgeInsets.all(20.w),
                  //     child: Column(
                  //       children: [
                  //         Text(
                  //           'Need Help?',
                  //           style: TextStyle(
                  //             fontSize: 18.sp,
                  //             fontWeight: FontWeight.bold,
                  //             color: Colors.blue[700],
                  //           ),
                  //         ),
                  //         SizedBox(height: 16.w),
                  //         _buildContactItem(
                  //           Icons.phone,
                  //           'Customer Support',
                  //           '1800-XXX-XXXX',
                  //         ),
                  //         Divider(height: 24.w),
                  //         _buildContactItem(
                  //           Icons.email,
                  //           'Email Support',
                  //           'support@ridealmobility.com',
                  //         ),
                  //         Divider(height: 24.w),
                  //         _buildContactItem(
                  //           Icons.access_time,
                  //           'Support Hours',
                  //           '24/7 Available',
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),

                  SizedBox(height: 32.w),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required int index,
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget content,
  }) {
    final isExpanded = _expandedSection == index;

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedSection = isExpanded ? null : index;
              });
            },
            borderRadius: BorderRadius.circular(12.r),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: content,
            ),
        ],
      ),
    );
  }

  Widget _buildSubsection(String title, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8.w),
        ...points.map((point) => _buildBulletPoint(point)),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.w, left: 8.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6.w),
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(
              color: Colors.blue[700],
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey[700],
                height: 1.5.w,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String method, String time, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.w),
      child: Row(
        children: [
          Container(
            width: 4.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.w),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              color: Colors.blue[700],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 4.w),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey[700],
                  height: 1.5.w,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue[700], size: 24),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4.w),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}