// Promo Code Model
class PromoCode {
  final String id;
  final String code;
  final String description;
  final String discountType; // 'percentage' or 'flat'
  final double discountValue;
  final double? minAmount;
  final double? maxDiscount;
  final List<String> applicableRideTypes;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final bool isActive;

  PromoCode({
    required this.id,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.minAmount,
    this.maxDiscount,
    required this.applicableRideTypes,
    this.validFrom,
    this.validUntil,
    required this.isActive,
  });

  factory PromoCode.fromJson(Map<String, dynamic> json) {
    return PromoCode(
      id: json['id'] ?? json['_id'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? json['name'] ?? '',
      discountType: json['discountType'] ?? 'flat',
      discountValue: (json['discountValue'] ?? 0).toDouble(),
      minAmount: (json['minOrderValue'] ?? json['minAmount'])?.toDouble(),
      maxDiscount:
          (json['maxDiscountAmount'] ?? json['maxDiscount'])?.toDouble(),
      applicableRideTypes:
          (json['applicableRideTypes'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      validFrom:
          json['startDate'] != null
              ? DateTime.parse(json['startDate'])
              : (json['validFrom'] != null
                  ? DateTime.parse(json['validFrom'])
                  : null),
      validUntil:
          json['endDate'] != null
              ? DateTime.parse(json['endDate'])
              : (json['validUntil'] != null
                  ? DateTime.parse(json['validUntil'])
                  : null),
      isActive: json['isActive'] ?? json['active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'code': code,
      'description': description,
      'discountType': discountType,
      'discountValue': discountValue,
      'minAmount': minAmount,
      'maxDiscount': maxDiscount,
      'applicableRideTypes': applicableRideTypes,
      'validFrom': validFrom?.toIso8601String(),
      'validUntil': validUntil?.toIso8601String(),
      'isActive': isActive,
    };
  }
}

// Validate Promo Code Request
class ValidatePromoRequest {
  final String code;
  final double originalAmount;
  final String rideType;

  ValidatePromoRequest({
    required this.code,
    required this.originalAmount,
    required this.rideType,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'originalAmount': originalAmount,
      'rideType': rideType,
    };
  }
}

// Validate Promo Code Response
class ValidatePromoResponse {
  final bool valid;
  final String? message;
  final PromoCodeDiscount? discount;

  ValidatePromoResponse({required this.valid, this.message, this.discount});

  factory ValidatePromoResponse.fromJson(Map<String, dynamic> json) {
    // Handle { "success": true, "data": {...} } format
    bool isValid = json['valid'] ?? json['success'] ?? false;
    String? msg = json['message'] ?? json['error'];

    Map<String, dynamic>? discountData;
    if (json['discount'] != null) {
      discountData = json['discount'];
    } else if (json['data'] != null && json['data'] is Map) {
      discountData = json['data'];
    }

    return ValidatePromoResponse(
      valid: isValid,
      message: msg,
      discount:
          discountData != null
              ? PromoCodeDiscount.fromJson(discountData)
              : null,
    );
  }
}

// Promo Code Discount Details
class PromoCodeDiscount {
  final String code;
  final String promoId;
  final double discountAmount;
  final double originalAmount;
  final double finalAmount;

  PromoCodeDiscount({
    required this.code,
    required this.promoId,
    required this.discountAmount,
    required this.originalAmount,
    required this.finalAmount,
  });

  factory PromoCodeDiscount.fromJson(Map<String, dynamic> json) {
    // Handle backend response: data.promoCode = { id, code, ... }
    String code = '';
    String promoId = '';

    if (json['promoCode'] != null && json['promoCode'] is Map) {
      // Backend sends nested promoCode object
      final promoCodeObj = json['promoCode'] as Map<String, dynamic>;
      code = promoCodeObj['code'] ?? '';
      promoId = promoCodeObj['id'] ?? promoCodeObj['_id'] ?? '';
    } else {
      // Direct code field
      code = json['code'] ?? '';
      promoId = json['promoId'] ?? json['id'] ?? '';
    }

    return PromoCodeDiscount(
      code: code,
      promoId: promoId,
      discountAmount:
          (json['discountAmount'] ?? json['potentialDiscount'] ?? 0).toDouble(),
      originalAmount: (json['originalAmount'] ?? 0).toDouble(),
      finalAmount: (json['finalAmount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'promoId': promoId,
      'discountAmount': discountAmount,
      'originalAmount': originalAmount,
      'finalAmount': finalAmount,
    };
  }
}

// Applied Promo Code (for ride booking response)
class AppliedPromoCode {
  final String code;
  final String promoId;
  final double discountAmount;
  final double originalAmount;

  AppliedPromoCode({
    required this.code,
    required this.promoId,
    required this.discountAmount,
    required this.originalAmount,
  });

  factory AppliedPromoCode.fromJson(Map<String, dynamic> json) {
    return AppliedPromoCode(
      code: json['code'] ?? '',
      promoId: json['promoId'] ?? '',
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      originalAmount: (json['originalAmount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'promoId': promoId,
      'discountAmount': discountAmount,
      'originalAmount': originalAmount,
    };
  }
}
