import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayPaymentHandler {
  late Razorpay _razorpay;
  final Function(String paymentId, String orderId, String signature) onSuccess;
  final Function(PaymentFailureResponse) onError;
  final Function() onWallet;

  RazorpayPaymentHandler({
    required this.onSuccess,
    required this.onError,
    required this.onWallet,
  }) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    onSuccess(
      response.paymentId ?? '',
      response.orderId ?? '',
      response.signature ?? '',
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    onError(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    onWallet();
  }

  void openRazorpay({
    required String orderId,
    required int amount,
    required String name,
    required String description,
    required String contact,
  }) {
    var options = {
      'key': 'rzp_live_RoLpvsh1Qs9Cfs',
      'amount': (amount).toInt(), // Amount in paise
      'name': 'RiDeal',
      'order_id': orderId,
      'description': description,
      'timeout': 600, // 10 minutes instead of 5
      'retry': {'enabled': true, 'max_count': 3},
      'prefill': {
        'contact': contact,
        'name': name,
        'email': 'support@rideal.com',
      },
      'config': {
        'display': {
          'blocks': {
            'banks': {
              'name': 'Pay using UPI',
              'instruments': [
                {'method': 'upi'},
                {'method': 'wallet'},
              ],
            },
          },
          'sequence': ['block.banks'],
          'preferences': {'show_default_blocks': true},
        },
      },
      'theme': {'color': '#4CAF50', 'backdrop_color': 'rgba(0, 0, 0, 0.6)'},
      'modal': {'backdropclose': false, 'escape': false, 'handleback': false},
    };

    try {
      print('🚀 Opening Razorpay with options: $options');
      _razorpay.open(options);
    } catch (e) {
      print('❌ Error opening Razorpay: $e');
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
