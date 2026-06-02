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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
            const SizedBox(width: 10),
            const Text(
              'Low Balance',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your wallet balance is insufficient for this payment.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Current Balance:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black54)),
                      Text('₹${_walletBalance.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red.shade600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Required Fare:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black54)),
                      Text('₹${_rideDetails!['estimatedFare'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandGreen)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              elevation: 0,
            ),
            child: const Text('Add Money', style: TextStyle(fontWeight: FontWeight.bold)),
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
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
                    "Complete Payment",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 40),
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
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
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
          const SizedBox(height: 24),
          Text(
            'Retrieving secure payment details...',
            style: TextStyle(
              fontSize: 14,
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
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
          const SizedBox(height: 24),
          const Text(
            'Failed to retrieve ride details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadRideDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: brandGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              elevation: 0,
            ),
            child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
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
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    // Secure Payment Banner
                    _buildBannerCard(),
                    const SizedBox(height: 16),
                    // Ride Summary Receipt Card
                    _buildRideDetailsCard(),
                    const SizedBox(height: 16),
                    // Payment Selector Options Card
                    _buildPaymentMethodCard(),
                    const SizedBox(height: 16),
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [brandGreen, Colors.green.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
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
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            left: 70,
            bottom: -35,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          // Banner row content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Secure Checkout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Complete your ride payment safely',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: brandGreen.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_rounded, color: brandGreen, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ride Receipt Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            icon: Icons.tag_rounded,
            label: 'Ride ID',
            value: '#${widget.rideId}',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Estimated Fare',
            value: '₹${_rideDetails!['estimatedFare'] ?? 'N/A'}',
            isAmount: true,
          ),
          if (_rideDetails!['promoCodeUsed'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: brandGreen.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: brandGreen.withOpacity(0.12)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_offer_rounded, color: brandGreen, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Promo: ${_rideDetails!['promoCodeUsed']['code']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: brandGreen,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.money_off_rounded,
                    label: 'Original Fare',
                    value: '₹${_rideDetails!['promoCodeUsed']['originalAmount'] ?? _rideDetails!['estimatedFare']}',
                    valueStyle: TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    icon: Icons.discount_rounded,
                    label: 'Discount',
                    value: '- ₹${_rideDetails!['promoCodeUsed']['discountAmount'] ?? 0}',
                    valueStyle: const TextStyle(color: brandGreen, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  _buildDetailRow(
                    icon: Icons.payments_rounded,
                    label: 'Final Amount',
                    value: '₹${_rideDetails!['estimatedFare']}',
                    isAmount: true,
                    valueStyle: const TextStyle(color: brandGreen, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: brandGreen.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.payment_rounded, color: brandGreen, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Payment Method',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87, letterSpacing: -0.3),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Wallet Payment Option card
          GestureDetector(
            onTap: () => setState(() => _selectedPaymentMethod = 'wallet'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedPaymentMethod == 'wallet' ? brandGreen : Colors.grey.shade100,
                  width: _selectedPaymentMethod == 'wallet' ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(16),
                color: _selectedPaymentMethod == 'wallet'
                    ? brandGreen.withOpacity(0.04)
                    : const Color(0xFFF8F9FA),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
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
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pay with Wallet",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _selectedPaymentMethod == 'wallet' ? Colors.black87 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "Balance: ₹${_walletBalance.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 12,
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Low",
                        style: TextStyle(fontSize: 10, color: Colors.red.shade600, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(width: 8),
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

          const SizedBox(height: 10),

          // Razorpay/Online Payment Option card
          GestureDetector(
            onTap: () => setState(() => _selectedPaymentMethod = 'online'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedPaymentMethod == 'online' ? brandGreen : Colors.grey.shade100,
                  width: _selectedPaymentMethod == 'online' ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(16),
                color: _selectedPaymentMethod == 'online'
                    ? brandGreen.withOpacity(0.04)
                    : const Color(0xFFF8F9FA),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
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
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      "Pay Online (UPI, Card, NetBanking)",
                      style: TextStyle(
                        fontSize: 14,
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
            const SizedBox(height: 14),
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: brandGreen, width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline_rounded, color: brandGreen, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "Add Money to Wallet",
                      style: TextStyle(
                        color: brandGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
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
            borderRadius: BorderRadius.circular(8),
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Icon(Icons.verified_user_outlined, color: brandGreen, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '256-bit SSL encryption ensures your payment is secure',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
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
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading || isWalletInsufficient ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoading) ...[
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ] else ...[
                    Icon(
                      _selectedPaymentMethod == 'wallet'
                          ? Icons.account_balance_wallet_rounded
                          : Icons.lock_rounded,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    _isLoading
                        ? 'Processing Payment...'
                        : isWalletInsufficient
                            ? 'Add Money First'
                            : _selectedPaymentMethod == 'wallet'
                                ? 'Pay ₹${_rideDetails!['estimatedFare'] ?? 'N/A'} with Wallet'
                                : 'Pay ₹${_rideDetails!['estimatedFare'] ?? 'N/A'} Online',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'By proceeding, you agree to our terms and conditions',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
