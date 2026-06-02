import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactInfoSection extends StatefulWidget {
  const ContactInfoSection({super.key});

  @override
  State<ContactInfoSection> createState() => _ContactInfoSectionState();
}

class _ContactInfoSectionState extends State<ContactInfoSection>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _buttonScaleAnimation;

  bool _showPhoneNumbers = false;
  bool _showEmails = false;

  final List<ContactItem> _phoneNumbers = [
    ContactItem(
      icon: Icons.phone,
      label: 'Toll-free Support',
      value: '06792 451322',
      description: 'Available 24/7 for emergency support',
    ),
    ContactItem(
      icon: Icons.phone,
      label: 'Delhi HQ',
      value: '+91 7859815062',
      description: 'Delhi headquarters office',
    ),
    ContactItem(
      icon: Icons.phone,
      label: 'Baripada HQ',
      value: '+91 8926273794',
      description: 'Baripada headquarters office',
    ),
  ];

  final List<ContactItem> _emails = [
    ContactItem(
      icon: Icons.email,
      label: 'General Information',
      value: 'info@ridealmobility.com',
      description: 'General inquiries and information',
    ),
    ContactItem(
      icon: Icons.email,
      label: 'Support',
      value: 'rideal794@gmail.com',
      description: 'Technical support and assistance',
    ),
    ContactItem(
      icon: Icons.email,
      label: 'HR Department',
      value: 'hr@ridealmobility.com',
      description: 'Human resources and recruitment',
    ),
    ContactItem(
      icon: Icons.email,
      label: 'CEO Office',
      value: 'ceo@ridealmobility.com',
      description: 'Executive communication',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _headerAnimationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _buttonAnimationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _buttonScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    // Start animations with delay
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        _headerAnimationController.forward();
      }
    });

    Future.delayed(Duration(milliseconds: 800), () {
      if (mounted) {
        _buttonAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      _showErrorSnackBar('Could not launch phone dialer');
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      _showErrorSnackBar('Could not launch email app');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Animated Header
          AnimatedBuilder(
            animation: _headerAnimationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _headerFadeAnimation,
                child: SlideTransition(
                  position: _headerSlideAnimation,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[100]!, Colors.purple[100]!],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.contact_support,
                          color: Colors.blue[700],
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contact RiDeal',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              'Tap to call or email',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // Animated Action Buttons
          AnimatedBuilder(
            animation: _buttonAnimationController,
            builder: (context, child) {
              return ScaleTransition(
                scale: _buttonScaleAnimation,
                child: Row(
                  children: [
                    // Call Button
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.phone,
                        label: 'Call',
                        color: Colors.green,
                        onTap: () {
                          setState(() {
                            _showPhoneNumbers = !_showPhoneNumbers;
                            if (_showPhoneNumbers) _showEmails = false;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 12),
                    // Email Button
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.email,
                        label: 'Email',
                        color: Colors.blue,
                        onTap: () {
                          setState(() {
                            _showEmails = !_showEmails;
                            if (_showEmails) _showPhoneNumbers = false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Animated Phone Numbers List
          AnimatedContainer(
            duration: Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            height: _showPhoneNumbers ? null : 0,
            child:
                _showPhoneNumbers
                    ? Column(
                      children: [
                        SizedBox(height: 14),
                        ..._phoneNumbers.asMap().entries.map((entry) {
                          return _buildAnimatedContactItem(
                            entry.value,
                            entry.key,
                            () => _makePhoneCall(entry.value.value),
                          );
                        }),
                      ],
                    )
                    : SizedBox.shrink(),
          ),

          // Animated Emails List
          AnimatedContainer(
            duration: Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            height: _showEmails ? null : 0,
            child:
                _showEmails
                    ? Column(
                      children: [
                        SizedBox(height: 14),
                        ..._emails.asMap().entries.map((entry) {
                          return _buildAnimatedContactItem(
                            entry.value,
                            entry.key,
                            () => _sendEmail(entry.value.value),
                          );
                        }),
                      ],
                    )
                    : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedContactItem(
    ContactItem item,
    int index,
    VoidCallback onTap,
  ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + (index * 100)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        // Clamp the value to ensure it stays within 0.0-1.0 range for opacity
        final clampedOpacity = value.clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: clampedOpacity,
            child: Container(
              margin: EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            item.icon == Icons.phone
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.blue.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.08),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color:
                                item.icon == Icons.phone
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.blue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.icon,
                            color:
                                item.icon == Icons.phone
                                    ? Colors.green[700]
                                    : Colors.blue[700],
                            size: 18,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                item.value,
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      item.icon == Icons.phone
                                          ? Colors.green[700]
                                          : Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (item.description != null) ...[
                                SizedBox(height: 2),
                                Text(
                                  item.description!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          item.icon == Icons.phone ? Icons.call : Icons.send,
                          color:
                              item.icon == Icons.phone
                                  ? Colors.green[600]
                                  : Colors.blue[600],
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ContactItem {
  final IconData icon;
  final String label;
  final String value;
  final String? description;

  ContactItem({
    required this.icon,
    required this.label,
    required this.value,
    this.description,
  });
}
