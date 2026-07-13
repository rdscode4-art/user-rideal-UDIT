class ReferralResponse {
  final bool success;
  final double totalEarnings;
  final int totalFriends;
  final List<FriendModel> friends;
  final RewardSchemeModel? rewardScheme;

  ReferralResponse({
    required this.success,
    required this.totalEarnings,
    required this.totalFriends,
    required this.friends,
    this.rewardScheme,
  });

  factory ReferralResponse.fromJson(Map<String, dynamic> json) {
    return ReferralResponse(
      success: json['success'] ?? false,
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      totalFriends: json['totalFriends'] ?? 0,
      friends: (json['friends'] as List?)
              ?.map((e) => FriendModel.fromJson(e))
              .toList() ??
          [],
      rewardScheme: json['rewardScheme'] != null
          ? RewardSchemeModel.fromJson(json['rewardScheme'])
          : null,
    );
  }
}

class FriendModel {
  final String name;
  final String phone;
  final double referrerBonus;
  final DateTime createdAt;

  FriendModel({
    required this.name,
    required this.phone,
    required this.referrerBonus,
    required this.createdAt,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      referrerBonus: (json['referrerBonus'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class RewardSchemeModel {
  final double referrerBonus;
  final double refereeBonus;

  RewardSchemeModel({
    required this.referrerBonus,
    required this.refereeBonus,
  });

  factory RewardSchemeModel.fromJson(Map<String, dynamic> json) {
    return RewardSchemeModel(
      referrerBonus: (json['referrerBonus'] ?? 0).toDouble(),
      refereeBonus: (json['refereeBonus'] ?? 0).toDouble(),
    );
  }
}
