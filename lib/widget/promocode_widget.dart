import 'package:flutter/material.dart';
import 'package:rideal/model/promocodemodel.dart';
import 'package:rideal/promocodeservice.dart';

class PromoCodeWidget extends StatefulWidget {
  final String rideType;
  final double estimatedAmount;
  final Function(PromoCodeDiscount?) onPromoApplied;

  const PromoCodeWidget({
    super.key,
    required this.rideType,
    required this.estimatedAmount,
    required this.onPromoApplied,
  });

  @override
  State<PromoCodeWidget> createState() => _PromoCodeWidgetState();
}

class _PromoCodeWidgetState extends State<PromoCodeWidget> {
  final TextEditingController _promoCodeController = TextEditingController();
  PromoCodeDiscount? _appliedPromo;
  bool _isValidating = false;
  String? _errorMessage;
  List<PromoCode> _availablePromoCodes = [];
  bool _isLoadingPromoCodes = false;

  // Green theme colors
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color accentGreen = Color(0xFF66BB6A);

  @override
    @override
  void initState() {
    super.initState();
    print('🎟️ PromoCodeWidget initialized:');
    print('  - Ride Type: ${widget.rideType}');
    print('  - Estimated Amount: ${widget.estimatedAmount}');
    _loadAvailablePromoCodes();
  }

  @override
  void didUpdateWidget(PromoCodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rideType != widget.rideType ||
        oldWidget.estimatedAmount != widget.estimatedAmount) {
      _loadAvailablePromoCodes();
      if (_appliedPromo != null && _promoCodeController.text.isNotEmpty) {
        _validateAndApplyPromo(_promoCodeController.text);
      }
    }
  }

  Future<void> _loadAvailablePromoCodes() async {
    setState(() {
      _isLoadingPromoCodes = true;
    });

    try {
      final promoCodes = await PromoCodeService.getAvailablePromoCodes(
        rideType: widget.rideType,
        estimatedAmount: widget.estimatedAmount,
      );

      setState(() {
        _availablePromoCodes = promoCodes;
        _isLoadingPromoCodes = false;
      });

      // Debug log
      print(
        '🎟️ Loaded ${promoCodes.length} promo codes for ${widget.rideType}',
      );
      if (promoCodes.isEmpty) {
        print('⚠️ No promo codes available. Check:');
        print('   1. Backend API: /api/promo-codes/available');
        print('   2. Ride Type: ${widget.rideType}');
        print('   3. Amount: ${widget.estimatedAmount}');
        print('   You can still try codes manually: WELCOME50, FLAT30, etc.');
      } else {
        print('✅ Available promo codes:');
        for (var code in promoCodes) {
          print('   - ${code.code}: ${code.description}');
        }
      }
    } catch (e) {
      print('❌ Error loading promo codes: $e');
      setState(() {
        _isLoadingPromoCodes = false;
      });
    }
  }

  Future<void> _validateAndApplyPromo(String code) async {
    if (code.trim().isEmpty) {
      setState(() {
        _errorMessage = "Please enter a promo code";
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    final response = await PromoCodeService.validatePromoCode(
      code: code.trim().toUpperCase(),
      originalAmount: widget.estimatedAmount,
      rideType: widget.rideType,
    );

    setState(() {
      _isValidating = false;
    });

    if (response != null && response.valid && response.discount != null) {
      setState(() {
        _appliedPromo = response.discount;
        _errorMessage = null;
      });
      widget.onPromoApplied(_appliedPromo);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Promo code applied! You saved ₹${response.discount!.discountAmount.toStringAsFixed(0)}',
          ),
          backgroundColor: primaryGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      setState(() {
        _appliedPromo = null;
        _errorMessage = response?.message ?? "Invalid promo code";
      });
      widget.onPromoApplied(null);
    }
  }

  void _removePromo() {
    setState(() {
      _appliedPromo = null;
      _promoCodeController.clear();
      _errorMessage = null;
    });
    widget.onPromoApplied(null);
  }

  void _applyPromoCode(PromoCode promoCode) {
    _promoCodeController.text = promoCode.code;
    _validateAndApplyPromo(promoCode.code);
  }

  void _showAvailablePromoCodes() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: primaryGreen.withOpacity(0.1),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '🎟️ Available Offers',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primaryGreen,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child:
                            _isLoadingPromoCodes
                                ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                : _availablePromoCodes.isEmpty
                                ? const Center(
                                  child: Text(
                                    'No promo codes available',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                )
                                : ListView.builder(
                                  controller: scrollController,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _availablePromoCodes.length,
                                  itemBuilder: (context, index) {
                                    final promo = _availablePromoCodes[index];
                                    return _buildPromoCodeCard(promo);
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildPromoCodeCard(PromoCode promo) {
    final isApplicable = PromoCodeService.isPromoCodeApplicable(
      promoCode: promo,
      rideType: widget.rideType,
      amount: widget.estimatedAmount,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient:
              isApplicable
                  ? LinearGradient(
                    colors: [primaryGreen.withOpacity(0.1), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : null,
          color: isApplicable ? null : Colors.grey.shade100,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isApplicable ? primaryGreen : Colors.grey,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      promo.code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      PromoCodeService.getDiscountText(promo),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                promo.description,
                style: TextStyle(
                  fontSize: 14,
                  color: isApplicable ? Colors.black87 : Colors.grey,
                ),
              ),
              if (promo.minAmount != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Min. amount: ₹${promo.minAmount!.toInt()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isApplicable ? Colors.black54 : Colors.grey,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      isApplicable
                          ? () {
                            Navigator.pop(context);
                            _applyPromoCode(promo);
                          }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    disabledBackgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    isApplicable ? 'APPLY' : 'NOT APPLICABLE',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_appliedPromo != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: primaryGreen, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: primaryGreen, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Code: ${_appliedPromo!.code} Applied!',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'You saved ₹${_appliedPromo!.discountAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: _removePromo,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, color: Colors.red, size: 20),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer, color: primaryGreen, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Have a promo code?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Enter code',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    errorText: _errorMessage,
                  ),
                  onSubmitted: _validateAndApplyPromo,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed:
                    _isValidating
                        ? null
                        : () =>
                            _validateAndApplyPromo(_promoCodeController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                child:
                    _isValidating
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text(
                          'Apply',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
              ),
            ],
          ),
          if (_availablePromoCodes.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: _showAvailablePromoCodes,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryGreen, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.card_giftcard, color: primaryGreen, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '🎁 ${_availablePromoCodes.length} Offers Available - View All',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: primaryGreen,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ] else if (!_isLoadingPromoCodes) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey.shade600,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No offers available for this ride',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _promoCodeController.dispose();
    super.dispose();
  }
}
