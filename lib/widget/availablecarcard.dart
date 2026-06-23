import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:rideal/model/availablecarlistmodel.dart';
import 'package:rideal/screens/transport/availablecarlist.dart';

class CarCard extends StatelessWidget {
  final Availablecarlistmodel car;
  const CarCard({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFFFFFAF0),
      margin: EdgeInsets.only(bottom: 16.w),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.amber.shade300,width: 1.5.w),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(car.name, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600)),
                      SizedBox(height: 4.w),
                      Text("Automatic | 3 seats | Octane", style: TextStyle(color: Colors.black)),
                      SizedBox(height: 4.w),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey),
                          SizedBox(width: 4.w),
                          Text("800m (5mins away)", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
                Image.asset(car.image, width: 130.w),
              ],
            ),
            SizedBox(height: 20.w),
            OutlinedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=>AvailableCarListScreen(car: Availablecarlistmodel(name: "Toyota", image: "assets/images/car.png"),)),);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: BorderSide(color: Colors.orange),
                fixedSize: Size(400, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))
              ),
              child: Text("View car list",style: TextStyle(fontSize: 18.sp),),
            ),
          ],
        ),
      ),
    );
  }
}