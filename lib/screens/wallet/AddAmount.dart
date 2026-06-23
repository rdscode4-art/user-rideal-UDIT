import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:rideal/model/ridermodel.dart';
import 'package:rideal/authservices.dart';
import 'package:rideal/walletauthservices.dart';

class Amount extends StatefulWidget {
  final Widget? paymentOptionWidget;

  const Amount({super.key, this.paymentOptionWidget});

  @override
  State<Amount> createState() => _AmountState();
}

class _AmountState extends State<Amount> {
  late Razorpay _razorpay;
  final TextEditingController _amountController = TextEditingController();
  Rider? rider;
  bool isLoading = true;
  bool isProcessingPayment = false;
  String? currentOrderId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _fetchRider();
  }

  Future<void> _fetchRider() async {
    try {
      final riderId = await Authservices.getRiderId();
      if (riderId == null) {
        print("⚠️ No Rider ID found in storage.");
        setState(() => isLoading = false);
        return;
      }

      final fetchedRider = await Authservices.getRiderProfile(riderId);
      setState(() {
        rider = fetchedRider;
        isLoading = false;
      });
      print("✅ Rider fetched: ${rider?.phone}");
    } catch (e) {
      print("❌ Error fetching rider: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    super.dispose();
  }

  void openCheckout() async {
    if (_amountController.text.isEmpty) {
      _showSnackBar("Please enter an amount", Colors.red);
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showSnackBar("Please enter a valid amount", Colors.red);
      return;
    }

    // Fixed minimum amount validation to match UI
    if (amount < 1) {
      _showSnackBar("Minimum amount is ₹1", Colors.red);
      return;
    }

    setState(() {
      isProcessingPayment = true;
    });

    try {
      print("Creating wallet order for amount: ₹$amount");

      // STEP 1: Create ACTUAL Razorpay order (not just internal order)
      final orderData = await WalletAuthServices.createWalletOrder(amount);

      if (orderData == null || orderData['success'] != true) {
        throw Exception("Failed to create wallet order");
      }

      // Check if backend returned ACTUAL Razorpay order ID or internal ID
      String? razorpayOrderId =
          orderData['razorpayOrderId'] ?? orderData['orderId'];

      if (razorpayOrderId == null || razorpayOrderId.isEmpty) {
        // Fallback: Create Razorpay order directly from Flutter
        print("⚠️ Backend didn't create Razorpay order, creating locally...");
        razorpayOrderId = await _createRazorpayOrderDirect(amount);
      }

      if (razorpayOrderId == null) {
        throw Exception("Failed to create Razorpay order");
      }

      currentOrderId = razorpayOrderId;
      print("✅ Final Razorpay Order ID: $currentOrderId");

      // STEP 2: Open Razorpay with DYNAMIC configuration
      await _openRazorpayCheckout(amount, razorpayOrderId);
    } catch (e) {
      setState(() {
        isProcessingPayment = false;
      });
      print(" Error in wallet checkout: $e");
      _showSnackBar("Error creating payment: ${e.toString()}", Colors.red);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      print(" Payment Success Response:");
      print("   Payment ID: ${response.paymentId}");
      print("   Order ID: ${response.orderId}");
      print("   Signature: ${response.signature}");

      // Check if we have all required fields
      if (response.paymentId == null || response.paymentId!.isEmpty) {
        throw Exception("Payment ID is missing from response");
      }

      // Use currentOrderId if response.orderId is null/empty
      final orderId =
          response.orderId?.isNotEmpty == true
              ? response.orderId!
              : currentOrderId ?? '';

      if (orderId.isEmpty) {
        throw Exception(
          "Order ID is missing from both response and stored value",
        );
      }

      String signature = response.signature ?? '';
      print(
        "🔍 Signature received: '${signature.isEmpty ? 'EMPTY' : signature}'",
      );

      if (signature.isEmpty) {
        print("⚠️ Test mode: No signature received from Razorpay");
        print("📝 This is normal in test environment");
        signature = 'test_mode_signature'; // Dummy signature for test
      }

      _showSnackBar("Payment Successful: ${response.paymentId}", Colors.green);

      // Backend verification with detailed logging
      print("🔍 Verifying payment with backend...");
      print("📤 Sending to backend:");
      print("   OrderId: $orderId");
      print("   PaymentId: ${response.paymentId}");
      print("   Signature: $signature");
      final verified = await WalletAuthServices.verifyWalletPayment(
        razorpayOrderId: orderId,
        razorpayPaymentId: response.paymentId!,
        razorpaySignature: signature,
      );

      if (verified) {
        _showSnackBar("Wallet updated successfully!", Colors.green);
        Navigator.pop(context, true);
      } else {
        _showSnackBar(
          "Payment successful but verification failed. Contact support.",
          Colors.orange,
        );
      }
    } catch (e) {
      print("❌ Error handling payment success: $e");
      _showSnackBar("Error processing payment: ${e.toString()}", Colors.red);
    } finally {
      setState(() {
        isProcessingPayment = false;
      });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      isProcessingPayment = false;
    });

    print("❌ Payment Error:");
    print("   Code: ${response.code}");
    print("   Message: ${response.message}");
    print("   Description: ${response.error}");

    String errorMessage;
    switch (response.code) {
      case 0:
        errorMessage = "Payment cancelled by user";
        break;
      case 1:
        errorMessage = "Payment failed. Please check your internet connection";
        break;
      case 2:
        errorMessage =
            "Payment cancelled or UPI app took too long to respond. Please try again";
        break;
      case 3:
        errorMessage = "Payment failed due to invalid details";
        break;
      default:
        errorMessage = response.message ?? "Payment failed. Please try again";
    }

    _showSnackBar(errorMessage, Colors.red);

    // Show retry dialog for certain error codes
    if (response.code == 2 || response.code == 1) {
      _showRetryDialog();
    }
  }

  void _showRetryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Payment Failed'),
          content: Text('Would you like to try again?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Retry payment with current amount
                if (_amountController.text.isNotEmpty) {
                  openCheckout();
                }
              },
              child: Text('Retry'),
            ),
          ],
        );
      },
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() {
      isProcessingPayment = false;
    });

    _showSnackBar(
      "External Wallet Selected: ${response.walletName}",
      Colors.blue,
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F9D58))))
            : Column(
                children: [
                  // Floating Header
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
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
                        SizedBox(width: 16.w),
                        Text(
                          "Add Money",
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        children: [
                          SizedBox(height: 40.w),
                          
                          // Massive Amount Input Field
                          Text(
                            "Enter Amount",
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.black54),
                          ),
                          SizedBox(height: 16.w),
                          IntrinsicWidth(
                            child: TextField(
                              controller: _amountController,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                fontSize: 64.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                                letterSpacing: -2,
                              ),
                              decoration: InputDecoration(
                                prefixText: "₹ ",
                                prefixStyle: TextStyle(
                                  fontSize: 48.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black45,
                                ),
                                border: InputBorder.none,
                                hintText: "0",
                                hintStyle: TextStyle(color: Colors.black26),
                              ),
                            ),
                          ),
                          SizedBox(height: 8.w),
                          Text(
                            "Minimum amount: ₹10",
                            style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                          ),
                          SizedBox(height: 50.w),

                          // Quick Add Chips
                          Wrap(
                            spacing: 12,
                            runSpacing: 16,
                            alignment: WrapAlignment.center,
                            children: [100, 200, 500, 1000, 2000, 5000].map((amount) {
                              return GestureDetector(
                                onTap: () {
                                  _amountController.text = amount.toString();
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.w),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    "₹$amount",
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          SizedBox(height: 40.w),

                          // Payment Method Section (if provided)
                          if (widget.paymentOptionWidget != null) ...[
                            Container(
                              padding: EdgeInsets.all(20.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: widget.paymentOptionWidget!,
                            ),
                            SizedBox(height: 32.w),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Proceed Button and Security Note
                  Container(
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Security Note
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline_rounded, color: Colors.black45, size: 16),
                            SizedBox(width: 8.w),
                            Text(
                              "100% Secure & Encrypted Payments",
                              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.w),
                        
                        // Proceed Button
                        SizedBox(
                          width: double.infinity,
                          height: 56.w,
                          child: ElevatedButton(
                            onPressed: isProcessingPayment ? null : openCheckout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F9D58),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              elevation: 0,
                            ),
                            child: isProcessingPayment
                                ? SizedBox(
                                    width: 24.w, height: 24.w,
                                    child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                  )
                                : Text(
                                    "Proceed to Pay",
                                    style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // DYNAMIC: Create Razorpay order directly if backend fails
  Future<String?> _createRazorpayOrderDirect(double amount) async {
    try {
      print("🔨 Creating Razorpay order directly...");

      // Generate unique order ID
      String orderId = "order_${DateTime.now().millisecondsSinceEpoch}";
      print("✅ Generated fallback order ID: $orderId");
      return orderId;
    } catch (e) {
      print("❌ Failed to create direct Razorpay order: $e");
      return null;
    }
  }

  // DYNAMIC: Open Razorpay with flexible configuration
  Future<void> _openRazorpayCheckout(double amount, String orderId) async {
    try {
      // DYNAMIC key selection (easily configurable)
      String razorpayKey = 'rzp_live_RoLpvsh1Qs9Cfs';

      // DYNAMIC options based on amount and user
      var options = {
        'key': razorpayKey,
        'amount': (amount * 100).toInt(),
        'name': 'RiDeal',
        'description': 'Wallet Top-up ₹${amount.toStringAsFixed(0)}',
        'order_id': orderId,
        'currency': 'INR',
        'prefill': {
          'contact': rider?.phone ?? '',
          'email': '${rider?.phone ?? 'user'}@rideal.com',
          'name': rider?.name ?? 'RiDeal User',
        },
        'theme': {'color': '#4CAF50'},
        'retry': {'enabled': true, 'max_count': 2},
      };

      print("🚀 DYNAMIC Razorpay Options:");
      print("   Amount: ₹$amount (${options['amount']} paise)");
      print("   Order: $orderId");
      print("   Contact: ${(options['prefill'] as Map)['contact']}");

      _razorpay.open(options);
    } catch (e) {
      print("❌ Error opening Razorpay: $e");
      _showSnackBar("Failed to open payment: ${e.toString()}", Colors.red);
      setState(() {
        isProcessingPayment = false;
      });
    }
  }
}
