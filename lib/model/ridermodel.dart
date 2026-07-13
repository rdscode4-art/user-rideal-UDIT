class Rider {
  final String id;
  final String name;
  final String phone;
  final String gender;
  final String address;
  final double rating;
  final bool isVerified;
  final String? profileImage;
  final String? referralCode;

  Rider({
    required this.id,
    required this.name,
    required this.phone,
    required this.gender,
    required this.address,
    required this.rating,
    required this.isVerified,
    this.profileImage,
    this.referralCode,
  });

  factory Rider.fromJson(Map<String, dynamic> json) {
    return Rider(
      id: json['_id'],
      name: json['name'] ?? 'Unknown',
      phone: json['phone'] ?? '',
      gender: json['gender'] ?? '',
      address: json['address'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      isVerified: json['isVerified'] ?? false,
      profileImage: json['profileImage'] ?? json['profilePhoto'],
      referralCode: json['referralCode'],
    );
  }

  Rider copyWith({
    String? name,
    String? phone,
    String? gender,
    String? address,
    double? rating,
    bool? isVerified,
    String? profileImage,
    String? referralCode,
  }) {
    return Rider(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      rating: rating ?? this.rating,
      isVerified: isVerified ?? this.isVerified,
      profileImage: profileImage ?? this.profileImage,
      referralCode: referralCode ?? this.referralCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "name": name,
      "phone": phone,
      "gender": gender,
      "address": address,
      "rating": rating,
      "isVerified": isVerified,
      "profileImage": profileImage,
      "referralCode": referralCode,
    };
  }
}
