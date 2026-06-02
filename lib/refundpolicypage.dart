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
        title: const Text('Refund Policy',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.green[700],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.green[700]!, Colors.green[700]!],
                ),
              ),
              child: Column(
                children: [
                  Image.asset("assets/images/logo.png",height: 120,),
                  const SizedBox(height: 16),
                  const Text(
                    'RiDeal Mobility Drive Private Limited',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Refund & Cancellation Policy',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Effective Date: November 2025',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Introduction Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700], size: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'We strive to provide transparent and fair refund policies for all our customers.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

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
                        const SizedBox(height: 12),
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
                        const SizedBox(height: 12),
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
                        const SizedBox(height: 12),
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
                        const SizedBox(height: 12),
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
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.email, color: Colors.blue[700], size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Or email us at:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'support@ridealmobility.com',
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontSize: 13,
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

                  const SizedBox(height: 24),

                  // Important Notice Card
                  Card(
                    elevation: 2,
                    color: Colors.amber[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.amber[200]!),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber, color: Colors.amber[800], size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Important Notice',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'RiDeal Mobility Drive Private Limited reserves the right to modify this refund policy at any time. Changes will be communicated through the app and email. Continued use of our services after policy changes constitutes acceptance of the modified terms.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[800],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Contact Card
                  // Card(
                  //   elevation: 3,
                  //   shape: RoundedRectangleBorder(
                  //     borderRadius: BorderRadius.circular(12),
                  //   ),
                  //   child: Padding(
                  //     padding: const EdgeInsets.all(20),
                  //     child: Column(
                  //       children: [
                  //         Text(
                  //           'Need Help?',
                  //           style: TextStyle(
                  //             fontSize: 18,
                  //             fontWeight: FontWeight.bold,
                  //             color: Colors.blue[700],
                  //           ),
                  //         ),
                  //         const SizedBox(height: 16),
                  //         _buildContactItem(
                  //           Icons.phone,
                  //           'Customer Support',
                  //           '1800-XXX-XXXX',
                  //         ),
                  //         const Divider(height: 24),
                  //         _buildContactItem(
                  //           Icons.email,
                  //           'Email Support',
                  //           'support@ridealmobility.com',
                  //         ),
                  //         const Divider(height: 24),
                  //         _buildContactItem(
                  //           Icons.access_time,
                  //           'Support Hours',
                  //           '24/7 Available',
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),

                  const SizedBox(height: 32),
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
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedSection = isExpanded ? null : index;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ...points.map((point) => _buildBulletPoint(point)),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.blue[700],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String method, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.blue[700],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.5,
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
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
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