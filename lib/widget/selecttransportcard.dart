import 'package:flutter/material.dart';
import 'package:rideal/model/selecttransportcard.dart';
class buildingselecttransportcard extends StatelessWidget {
  final transportcarddatamodel card;

  const buildingselecttransportcard({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10), // ✅ Clip the image
            child: Image.asset(
              card.imagepath,
              height: 140,
              width: 140,
              fit: BoxFit.contain, // ✅ Ensures it doesn't overflow
            ),
          ),
          // const SizedBox(height: 5),
          Text(
            card.description,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
