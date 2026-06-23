import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:rideal/model/selecttransportcard.dart';
class buildingselecttransportcard extends StatelessWidget {
  final transportcarddatamodel card;

  const buildingselecttransportcard({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90.w,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r), // ✅ Clip the image
            child: Image.asset(
              card.imagepath,
              height: 140.w,
              width: 140.w,
              fit: BoxFit.contain, // ✅ Ensures it doesn't overflow
            ),
          ),
          // SizedBox(height: 5.w),
          Text(
            card.description,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
