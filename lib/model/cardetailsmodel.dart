import 'package:flutter/material.dart';

class CarDetails {
  final String name;
  final String imagePath;
  final double rating;
  final int reviews;
  final List<SpecificationsCardDetails> specifications;
  final List<FeaturesCarDetails> features;

  CarDetails({
    required this.name,
    required this.imagePath,
    required this.rating,
    required this.reviews,
    required this.specifications,
    required this.features,
  });
}

class SpecificationsCardDetails {
  final String heading;
  final String subHeading;
  final Icon icon;

  SpecificationsCardDetails({
    required this.heading,
    required this.subHeading,
    required this.icon,
  });
}

class FeaturesCarDetails {
  String Feature;
  String Description;
  FeaturesCarDetails({required this.Feature, required this.Description});
}
