class RideType {
  final String type;
  final int farePerKm;
  final String? imageUrl; // Add imageUrl field

  RideType({
    required this.type,
    required this.farePerKm,
    this.imageUrl,
  });

  factory RideType.fromJson(String key, dynamic value, Map<String, dynamic>? vehicleImages) {
    // Convert key to display name (e.g., "suv_ac" -> "Suv Ac")
    String displayType = key
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');

    // Get image URL from vehicleImages if available
    String? imageUrl;
    if (vehicleImages != null) {
      // Try exact match first
      imageUrl = vehicleImages[displayType];
      // If not found, try lowercase key
      imageUrl ??= vehicleImages[key];
      // If still not found, try case-insensitive search
      if (imageUrl == null) {
        vehicleImages.forEach((k, v) {
          if (k.toLowerCase() == displayType.toLowerCase()) {
            imageUrl = v;
          }
        });
      }
    }

    return RideType(
      type: displayType,
      farePerKm: value is int ? value : int.tryParse(value.toString()) ?? 0,
      imageUrl: imageUrl,
    );
  }
}
