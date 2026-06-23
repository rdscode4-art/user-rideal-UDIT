import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideal/screens/wallet/AddAmount.dart';
import 'package:rideal/walletauthservices.dart';

class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  double walletBalance = 0.0;
  String errorMessage = '';
  bool isLoading = true;
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final walletData = await WalletAuthServices.getWalletBalance();

      if (walletData != null && walletData['success'] == true) {
        setState(() {
          walletBalance = walletData['wallet']?.toDouble() ?? 0.0;

          // IMPORTANT: Parse transactions from API response
          if (walletData['transactions'] != null) {
            transactions = List<Map<String, dynamic>>.from(
              walletData['transactions'],
            );
            // Sort transactions by date (newest first)
            transactions.sort((a, b) {
              final aDate =
                  DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
              final bDate =
                  DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
              return bDate.compareTo(aDate);
            });
          } else {
            transactions = [];
          }

          isLoading = false;
        });
        print('✅ Wallet balance loaded: $walletBalance');
        print('✅ Transactions loaded: ${transactions.length}');
      } else {
        setState(() {
          errorMessage = 'Failed to load wallet data';
          isLoading = false;
        });
        print('❌ Failed to load wallet data: $walletData');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
      print('❌ Error loading wallet: $e');
    }
  }

  Future<void> _refreshWallet() async {
    print('🔄 Manual wallet refresh triggered');
    await _loadWalletData();
  }

  // Navigate to Add Money screen and refresh on return
  Future<void> _navigateToAddMoney() async {
    print('📱 Navigating to Add Money screen');

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Amount()),
    );

    // If money was successfully added, refresh the wallet
    if (result == true) {
      print('💰 Money added successfully, refreshing wallet balance');
      // Add a small delay to ensure the backend has processed the transaction
      await Future.delayed(Duration(seconds: 1));
      await _loadWalletData();

      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wallet balance updated successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      final DateTime yesterday = today.subtract(Duration(days: 1));
      final DateTime transactionDate = DateTime(
        date.year,
        date.month,
        date.day,
      );

      if (transactionDate == today) {
        return "Today at ${DateFormat('hh:mm a').format(date)}";
      } else if (transactionDate == yesterday) {
        return "Yesterday at ${DateFormat('hh:mm a').format(date)}";
      } else {
        return DateFormat('MMM dd, yyyy at hh:mm a').format(date);
      }
    } catch (e) {
      return dateString;
    }
  }

  String _getTransactionTitle(Map<String, dynamic> transaction) {
    final type = transaction['type'] ?? '';
    final method = transaction['method'] ?? '';

    if (type == 'credit') {
      if (method == 'razorpay') {
        return 'Money Added';
      } else if (method == 'wallet') {
        return 'Wallet Credit';
      } else {
        return 'Credit';
      }
    } else if (type == 'debit') {
      if (method == 'wallet') {
        return 'Ride Payment';
      } else {
        return 'Debit';
      }
    }
    return 'Transaction';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Floating Header
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  Text(
                    "Wallet",
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  GestureDetector(
                    onTap: _refreshWallet,
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
                      child: Icon(Icons.refresh, color: Colors.black87, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Top Section with Premium Balance Card and Actions
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                children: [
                  // Digital Credit Card (Balance Card)
                  if (isLoading)
                    _buildLoadingBalanceCard()
                  else
                    _buildBalanceCard(
                      "₹${walletBalance.toStringAsFixed(2)}",
                      "Available Balance",
                    ),

                  SizedBox(height: 12.w),

                  // Action Buttons (Add Money)
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _navigateToAddMoney,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F9D58).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.add, color: Color(0xFF0F9D58), size: 18),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  "Add Money",
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Show error message if any
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 16.w),
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                errorMessage,
                                style: TextStyle(color: Colors.red.shade700, fontSize: 13.sp, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 16.w),

            // Transactions Section Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recent Transactions",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  if (transactions.isNotEmpty)
                    Text(
                      "${transactions.length} total",
                      style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
            SizedBox(height: 16.w),

            // Transactions List
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F9D58)),
                      ),
                    )
                  : transactions.isEmpty
                      ? _buildEmptyTransactions()
                      : ListView.separated(
                          padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 20.w),
                          itemCount: transactions.length,
                          separatorBuilder: (context, index) => SizedBox(height: 6.w),
                          itemBuilder: (BuildContext context, int index) {
                            final transaction = transactions[index];
                            return _buildTransactionCard(transaction);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // Empty transactions state
  Widget _buildEmptyTransactions() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                Icons.receipt_long,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: 16.w),
            Text(
              "No Transactions Yet",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8.w),
            Text(
              "Your transaction history will appear here\nonce you start using your wallet.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade500,
                height: 1.4.w,
              ),
            ),
            SizedBox(height: 24.w),
            ElevatedButton(
              onPressed: _navigateToAddMoney,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text("Add Money to Get Started"),
            ),
          ],
        ),
      ),
    );
  }

  // Loading state for balance card
  Widget _buildLoadingBalanceCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.w, height: 40.w,
            decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
          ),
          SizedBox(height: 20.w),
          Container(width: 80.w, height: 14.w, color: Colors.grey.shade300),
          SizedBox(height: 8.w),
          Container(width: 140.w, height: 32.w, color: Colors.grey.shade300),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(String amount, String description) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade700.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative element
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100.w, height: 100.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            right: 40.w,
            bottom: -40,
            child: Container(
              width: 120.w, height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                  ),
                  Text("RiDeal Pay", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13.sp, letterSpacing: 1)),
                ],
              ),
              SizedBox(height: 12.w),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 4.w),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 36.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final type = transaction['type'] ?? '';
    final amount = transaction['amount']?.toString() ?? '0';
    final method = transaction['method'] ?? '';
    final createdAt = transaction['createdAt'] ?? '';

    final isCredit = type == 'credit';
    final Color amountColor = isCredit ? const Color(0xFF0F9D58) : Colors.red.shade600;
    final String title = _getTransactionTitle(transaction);
    final String formattedDate = _formatDate(createdAt);
    final String amountText = "${isCredit ? '+' : '-'}₹$amount";

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
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
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: isCredit ? const Color(0xFF0F9D58).withOpacity(0.1) : Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: amountColor,
              size: 16,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                ),
                if (method.isNotEmpty) ...[
                  SizedBox(height: 6.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.w),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      method.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            amountText,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
