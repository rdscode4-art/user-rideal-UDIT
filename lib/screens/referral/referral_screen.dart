import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:rideal/authservices.dart';
import 'package:rideal/model/referral_model.dart';
import 'package:rideal/model/ridermodel.dart';
import 'package:rideal/services/referral_api_service.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> with SingleTickerProviderStateMixin {
  bool isLoading = true;
  ReferralResponse? referralData;
  Rider? rider;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    _loadData();
  }

  Future<void> _loadData() async {
    final cachedRider = await Authservices.getCachedRiderProfile();
    final data = await ReferralApiService.fetchReferralData();
    
    if (mounted) {
      setState(() {
        rider = cachedRider;
        referralData = data;
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _shareReferralCode(double refereeBonus) {
    final String code = rider?.referralCode ?? 'RIDEAL123';
    String bonusText = refereeBonus > 0
        ? '✅ ₹${refereeBonus.toInt()} bonus for new riders\n'
        : '';
    final String message = '''
🚗 Join RiDeal and start riding!

Use my referral code: $code
When you sign up, you get amazing benefits!
✅ Fast & secure rides
✅ Great discounts
$bonusText
Download the app and start your journey today!
https://play.google.com/store/apps/details?id=com.rds.ridealuser
''';
    Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Refer & Earn',
          style: GoogleFonts.inter(
            color: const Color(0xFF1F2937),
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroBanner(),
                    SizedBox(height: 24.w),
                    _buildReferralCodeSection(),
                    SizedBox(height: 24.w),
                    _buildStatisticsSection(),
                    SizedBox(height: 24.w),
                    _buildSectionTitle('How it Works'),
                    SizedBox(height: 16.w),
                    _buildHowItWorksSteps(),
                    SizedBox(height: 24.w),
                    if (referralData != null && referralData!.friends.isNotEmpty) ...[
                      _buildSectionTitle('Recent Referrals'),
                      SizedBox(height: 16.w),
                      _buildRecentReferralsList(),
                      SizedBox(height: 40.w),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeroBanner() {
    final referrerBonus = referralData?.rewardScheme?.referrerBonus ?? 50.0;
    final refereeBonus = referralData?.rewardScheme?.refereeBonus ?? 20.0;

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.card_giftcard, size: 48.w, color: Colors.white),
          SizedBox(height: 16.w),
          Text(
            'Invite Friends & Earn',
            style: GoogleFonts.inter(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.w),
          Text(
            referrerBonus > 0 && refereeBonus > 0
                ? 'Get ₹${referrerBonus.toInt()} for each successful rider referral upon sign up, and your friend gets ₹${refereeBonus.toInt()}.'
                : referrerBonus > 0
                ? 'Get ₹${referrerBonus.toInt()} for each successful rider referral upon sign up.'
                : refereeBonus > 0
                ? 'Invite a friend and they get ₹${refereeBonus.toInt()} upon sign up.'
                : 'Invite your friends to join RiDeal!',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCodeSection() {
    final code = rider?.referralCode ?? 'RIDEAL123';
    final refereeBonus = referralData?.rewardScheme?.refereeBonus ?? 20.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Referral Code',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        SizedBox(height: 12.w),
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      code,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.w),
              ElevatedButton.icon(
                onPressed: () => _shareReferralCode(refereeBonus),
                icon: Icon(Icons.share_rounded, size: 20.w, color: Colors.white),
                label: Text(
                  'Share Code',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection() {
    final totalEarnings = referralData?.totalEarnings ?? 0.0;
    final totalFriends = referralData?.totalFriends ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Your Rewards'),
        SizedBox(height: 16.w),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Earned',
                '₹${totalEarnings.toInt()}',
                const Color(0xFF10B981),
                Icons.account_balance_wallet_rounded,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _buildStatCard(
                'Friends Joined',
                '$totalFriends',
                const Color(0xFF3B82F6),
                Icons.people_alt_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 20.w),
          ),
          SizedBox(height: 12.w),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 4.w),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksSteps() {
    final referrerBonus = referralData?.rewardScheme?.referrerBonus ?? 50.0;
    final refereeBonus = referralData?.rewardScheme?.refereeBonus ?? 20.0;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStepItem(
            '1',
            'Share Code',
            'Share your referral code with friends.',
            isLast: false,
          ),
          _buildStepItem(
            '2',
            'Friend Signs Up',
            'Friend successfully registers on the app.',
            isLast: false,
          ),
          _buildStepItem(
            '3',
            'Earn Reward',
            referrerBonus > 0 && refereeBonus > 0
                ? 'You get ₹${referrerBonus.toInt()} & your friend gets ₹${refereeBonus.toInt()}.'
                : referrerBonus > 0
                ? 'You get ₹${referrerBonus.toInt()}.'
                : refereeBonus > 0
                ? 'Your friend gets ₹${refereeBonus.toInt()}.'
                : 'You both enjoy the RiDeal experience.',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String step, String title, String subtitle, {required bool isLast}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  step,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(width: 2.w, height: 40.w, color: Colors.grey[200]),
          ],
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 15.sp,
                  color: const Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: 4.w),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: const Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
              if (!isLast) SizedBox(height: 16.w),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentReferralsList() {
    if (referralData == null || referralData!.friends.isEmpty) return const SizedBox.shrink();
    
    return Column(
      children: referralData!.friends.map((friend) {
        return _buildReferralListItem(
          name: friend.name,
          status: 'Joined on ${friend.createdAt.day}/${friend.createdAt.month}/${friend.createdAt.year}',
          amount: '₹${friend.referrerBonus.toInt()}',
          isCompleted: friend.referrerBonus > 0,
        );
      }).toList(),
    );
  }

  Widget _buildReferralListItem({
    required String name,
    required String status,
    required String amount,
    required bool isCompleted,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15.sp,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 4.w),
                Row(
                  children: [
                    Icon(
                      isCompleted ? Icons.check_circle_rounded : Icons.pending_rounded,
                      size: 14.w,
                      color: isCompleted ? const Color(0xFF10B981) : Colors.amber,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      status,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: isCompleted ? const Color(0xFF10B981) : Colors.grey[600],
                        fontWeight: isCompleted ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 15.sp,
                  color: isCompleted ? const Color(0xFF10B981) : Colors.grey[500],
                ),
              ),
              if (isCompleted) ...[
                SizedBox(height: 2.w),
                Icon(Icons.stars_rounded, color: const Color(0xFF10B981), size: 16.w),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1F2937),
      ),
    );
  }
}
