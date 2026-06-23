import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:rideal/authservices.dart';
import 'package:rideal/paymentapiservice.dart';
import 'package:rideal/paymenthandler.dart';
import 'package:rideal/screens/wallet/AddAmount.dart';
import 'package:rideal/walletauthservices.dart';

class PaymentScreen extends StatefulWidget {
  final String rideId;
  final String userToken;

  const PaymentScreen({
    super.key,
    required this.rideId,
    required this.userToken,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  late RazorpayPaymentHandler _paymentHandler;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  Map<String, dynamic>? _rideDetails;
  String _selectedPaymentMethod = 'wallet';
  double _walletBalance = 0.0;
  bool _isLoadingWallet = true;

  // Brand green
  static const Color brandGreen = Color(0xFF0F9D58);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _initializePaymentHandler();
    _loadRideDetails();
    _loadWalletBalance();
    _animationController.forward();
  }

  void _initializePaymentHandler() {
    _paymentHandler = RazorpayPaymentHandler(
      onSuccess: _handlePaymentSuccess,
      onError: _handlePaymentError,
      onWallet: _handleExternalWallet,
    );
  }

  Future<void> _loadWalletBalance() async {
    try {
      final walletData = await WalletAuthServices.getWalletBalance();
      setState(() {
        _walletBalance = walletData?['wallet']?.toDouble() ?? 0.0;
        _isLoadingWallet = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingWallet = false;
      });
    }
  }

  Future<void> _loadRideDetails() async {
    setState(() { _isLoading = true; });
    final rideDetails = await PaymentService.getRideDetails(
      rideId: widget.rideId,
      token: widget.userToken,
    );
    setState(() {
      _rideDetails = rideDetails;
      _isLoading = false;
    });
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == 'wallet') {
      await _payWithWallet();
    } else {
      await _initiateRazorpayPayment();
    }
  }

  Future<void> _payWithWallet() async {
    if (_rideDetails == null) { _showToast('Ride details not available'); return; }

    final rideAmount = double.tryParse(_rideDetails!['estimatedFare'].toString()) ?? 0.0;
    if (_walletBalance < rideAmount) {
      _showToast('❌ Insufficient wallet balance');
      _showAddMoneyDialog();
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final success = await WalletAuthServices.payRideViaWallet(rideId: widget.rideId);
      setState(() { _isLoading = false; });
      if (success) {
        _showToast('✅ Payment successful!');
        Navigator.of(context).pop(true);
      } else {
        _showToast('Wallet payment failed. Please try again.');
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      _showToast('Error processing wallet payment: $e');
    }
  }

  Future<void> _initiateRazorpayPayment() async {
    if (_rideDetails == null) { _showToast('Ride details not available'); return; }

    setState(() { _isLoading = true; });

    final orderResponse = await PaymentService.createRazorpayOrder(
      rideId: widget.rideId,
      token: widget.userToken,
    );
    setState(() { _isLoading = false; });

    if (orderResponse != null && orderResponse['success'] == true) {
      final riderId = await Authservices.getRiderId();
      final fetchedRider = await Authservices.getRiderProfile(riderId ?? "");
      _paymentHandler.openRazorpay(
        orderId: orderResponse['orderId'],
        amount: orderResponse['amount'] ?? 0,
        name: fetchedRider.name,
        description: 'Payment for RideId #${widget.rideId}',
        contact: fetchedRider.phone,
      );
    } else {
      _showToast('Failed to create payment order');
    }
  }

  void _handlePaymentSuccess(String paymentId, String orderId, String signature) async {
    _showToast('Payment successful!');
    setState(() { _isLoading = true; });
    final isVerified = await PaymentService.verifyPayment(
      rideId: widget.rideId,
      orderId: orderId,
      paymentId: paymentId,
      signature: signature,
      token: widget.userToken,
    );
    setState(() { _isLoading = false; });
    if (isVerified) {
      _showToast('✅ Payment verified!');
      Navigator.of(context).pop(true);
    } else {
      _showToast('Payment verification failed');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _showToast('Payment failed: ${response.message}');
  }

  void _handleExternalWallet() {
    _showToast('External wallet selected');
  }

  void _showAddMoneyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
            SizedBox(width: 10.w),
            Text(
              'Low Balance',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18.sp),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your wallet balance is insufficient for this payment.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14.sp, height: 1.4.w),
            ),
            SizedBox(height: 18.w),
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Current Balance:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13.sp, color: Colors.black54)),
                      Text('₹${_walletBalance.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, color: Colors.red.shade600)),
                    ],
                  ),
                  SizedBox(height: 8.w),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Required Fare:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13.sp, color: Colors.black54)),
                      Text('₹${_rideDetails!['estimatedFare'] ?? 'N/A'}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, color: brandGreen)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Amount()),
              ).then((result) {
                if (result == true) _loadWalletBalance();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: brandGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.w),
              elevation: 0,
            ),
            child: Text('Add Money', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: brandGreen,
      textColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _paymentHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Signature Header
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
                    "Complete Payment",
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(width: 40.w),
                ],
              ),
            ),

            // Body content
            Expanded(
              child: _isLoading || _isLoadingWallet
                  ? _buildLoadingScreen()
                  : _rideDetails == null
                      ? _buildErrorScreen()
                      : _buildPaymentContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(22.w),
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
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(brandGreen),
            ),
          ),
          SizedBox(height: 24.w),
          Text(
            'Retrieving secure payment details...',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
          ),
          SizedBox(height: 24.w),
          Text(
            'Failed to retrieve ride details',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: Colors.black87),
          ),
          SizedBox(height: 8.w),
          Text(
            'Please check your connection and try again.',
            style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 24.w),
          ElevatedButton(
            onPressed: _loadRideDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: brandGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.w),
              elevation: 0,
            ),
            child: Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(bottom: 24.w),
                child: Column(
                  children: [
                    // Secure Payment Banner
                    _buildBannerCard(),
                    SizedBox(height: 16.w),
                    // Ride Summary Receipt Card
                    _buildRideDetailsCard(),
                    SizedBox(height: 16.w),
                    // Payment Selector Options Card
                    _buildPaymentMethodCard(),
                    SizedBox(height: 16.w),
                    // SSL Security Indicator
                    _buildSecurityBadge(),
                  ],
                ),
              ),
            ),
            // Floating Payment Bottom Button Bar
            _buildPaymentButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      height: 100.w,
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
          // Background graphic spheres
          Positioned(
            right: -25,
            top: -25,
            child: Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            left: 70.w,
            bottom: -35,
            child: Container(
              width: 90.w,
              height: 90.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          // Banner row content
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(Icons.lock_outline_rounded, color: Colors.white, size: 24),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Secure Checkout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 3.w),
                      Text(
                        'Complete your ride payment safely',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12.sp,
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
    );
  }

  Widget _buildRideDetailsCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
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
                child: Icon(Icons.receipt_long_rounded, color: brandGreen, size: 18),
              ),
              SizedBox(width: 12.w),
              Text(
                'Ride Receipt Summary',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.w),
          _buildDetailRow(
            icon: Icons.tag_rounded,
            label: 'Ride ID',
            value: '#${widget.rideId}',
          ),
          SizedBox(height: 12.w),
          _buildDetailRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Estimated Fare',
            value: '₹${_rideDetails!['estimatedFare'] ?? 'N/A'}',
            isAmount: true,
          ),
          if (_rideDetails!['promoCodeUsed'] != null) ...[
            SizedBox(height: 16.w),
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: brandGreen.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: brandGreen.withOpacity(0.12)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_offer_rounded, color: brandGreen, size: 14),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Promo: ${_rideDetails!['promoCodeUsed']['code']}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: brandGreen,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.w),
                  _buildDetailRow(
                    icon: Icons.money_off_rounded,
                    label: 'Original Fare',
                    value: '₹${_rideDetails!['promoCodeUsed']['originalAmount'] ?? _rideDetails!['estimatedFare']}',
                    valueStyle: TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey.shade400, fontSize: 13.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8.w),
                  _buildDetailRow(
                    icon: Icons.discount_rounded,
                    label: 'Discount',
                    value: '- ₹${_rideDetails!['promoCodeUsed']['discountAmount'] ?? 0}',
                    valueStyle: TextStyle(color: brandGreen, fontWeight: FontWeight.w800, fontSize: 13.sp),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.w),
                    child: Divider(height: 1.w),
                  ),
                  _buildDetailRow(
                    icon: Icons.payments_rounded,
                    label: 'Final Amount',
                    value: '₹${_rideDetails!['estimatedFare']}',
                    isAmount: true,
                    valueStyle: TextStyle(color: brandGreen, fontWeight: FontWeight.bold, fontSize: 15.sp),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 12.w),
          _buildDetailRow(
            icon: Icons.info_outline_rounded,
            label: 'Ride Status',
            value: '${_rideDetails!['status'] ?? 'N/A'}',
            isStatus: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    final rideAmount = double.tryParse(_rideDetails!['estimatedFare'].toString()) ?? 0.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
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
                child: Icon(Icons.payment_rounded, color: brandGreen, size: 18),
              ),
              SizedBox(width: 12.w),
              Text(
                'Payment Method',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: Colors.black87, letterSpacing: -0.3),
              ),
            ],
          ),
          SizedBox(height: 18.w),

          // Wallet Payment Option card
          GestureDetector(
            onTap: () => setState(() => _selectedPaymentMethod = 'wallet'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedPaymentMethod == 'wallet' ? brandGreen : Colors.grey.shade100,
                  width: _selectedPaymentMethod == 'wallet' ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(16.r),
                color: _selectedPaymentMethod == 'wallet'
                    ? brandGreen.withOpacity(0.04)
                    : const Color(0xFFF8F9FA),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: _selectedPaymentMethod == 'wallet'
                          ? brandGreen.withOpacity(0.1)
                          : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: _selectedPaymentMethod == 'wallet' ? brandGreen : Colors.grey.shade500,
                      size: 18,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pay with Wallet",
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: _selectedPaymentMethod == 'wallet' ? Colors.black87 : Colors.black54,
                          ),
                        ),
                        SizedBox(height: 3.w),
                        Text(
                          "Balance: ₹${_walletBalance.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: _walletBalance >= rideAmount
                                ? brandGreen
                                : Colors.red.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_walletBalance < rideAmount)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.w),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        "Low",
                        style: TextStyle(fontSize: 10.sp, color: Colors.red.shade600, fontWeight: FontWeight.bold),
                      ),
                    ),
                  SizedBox(width: 8.w),
                  Radio<String>(
                    value: 'wallet',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
                    activeColor: brandGreen,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 10.w),

          // Razorpay/Online Payment Option card
          GestureDetector(
            onTap: () => setState(() => _selectedPaymentMethod = 'online'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedPaymentMethod == 'online' ? brandGreen : Colors.grey.shade100,
                  width: _selectedPaymentMethod == 'online' ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(16.r),
                color: _selectedPaymentMethod == 'online'
                    ? brandGreen.withOpacity(0.04)
                    : const Color(0xFFF8F9FA),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: _selectedPaymentMethod == 'online'
                          ? brandGreen.withOpacity(0.1)
                          : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.credit_card_rounded,
                      color: _selectedPaymentMethod == 'online' ? brandGreen : Colors.grey.shade500,
                      size: 18,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Text(
                      "Pay Online (UPI, Card, NetBanking)",
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: _selectedPaymentMethod == 'online' ? Colors.black87 : Colors.black54,
                      ),
                    ),
                  ),
                  Radio<String>(
                    value: 'online',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
                    activeColor: brandGreen,
                  ),
                ],
              ),
            ),
          ),

          // Add money container link if low balance
          if (_selectedPaymentMethod == 'wallet' && _walletBalance < rideAmount) ...[
            SizedBox(height: 14.w),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Amount()),
                ).then((result) {
                  if (result == true) _loadWalletBalance();
                });
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12.w),
                decoration: BoxDecoration(
                  border: Border.all(color: brandGreen, width: 1.5.w),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline_rounded, color: brandGreen, size: 18),
                    SizedBox(width: 8.w),
                    Text(
                      "Add Money to Wallet",
                      style: TextStyle(
                        color: brandGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isAmount = false,
    bool isStatus = false,
    TextStyle? valueStyle,
  }) {
    return Row(
      children: [
        Icon(icon, color: brandGreen.withOpacity(0.5), size: 16),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isAmount || isStatus ? 10 : 8,
            vertical: isAmount || isStatus ? 5 : 3,
          ),
          decoration: BoxDecoration(
            color: isAmount
                ? brandGreen.withOpacity(0.08)
                : isStatus
                    ? Colors.blue.withOpacity(0.08)
                    : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            value,
            style: valueStyle ??
                TextStyle(
                  fontSize: isAmount ? 14 : 12,
                  fontWeight: isAmount ? FontWeight.bold : FontWeight.w700,
                  color: isAmount
                      ? brandGreen
                      : isStatus
                          ? Colors.blue.shade700
                          : Colors.black87,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityBadge() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_outlined, color: brandGreen, size: 18),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              '256-bit SSL encryption ensures your payment is secure',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    final rideAmount = double.tryParse(_rideDetails!['estimatedFare'].toString()) ?? 0.0;
    final isWalletInsufficient = _selectedPaymentMethod == 'wallet' && _walletBalance < rideAmount;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56.w,
            child: ElevatedButton(
              onPressed: _isLoading || isWalletInsufficient ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.r),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoading) ...[
                    SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 10.w),
                  ] else ...[
                    Icon(
                      _selectedPaymentMethod == 'wallet'
                          ? Icons.account_balance_wallet_rounded
                          : Icons.lock_rounded,
                      size: 18,
                    ),
                    SizedBox(width: 8.w),
                  ],
                  Text(
                    _isLoading
                        ? 'Processing Payment...'
                        : isWalletInsufficient
                            ? 'Add Money First'
                            : _selectedPaymentMethod == 'wallet'
                                ? 'Pay ₹${_rideDetails!['estimatedFare'] ?? 'N/A'} with Wallet'
                                : 'Pay ₹${_rideDetails!['estimatedFare'] ?? 'N/A'} Online',
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
          SizedBox(height: 8.w),
          Text(
            'By proceeding, you agree to our terms and conditions',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
