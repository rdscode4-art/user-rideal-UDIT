import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:rideal/screens/transport/RequestRent.dart';
import 'package:rideal/screens/transport/requestrent_II.dart';
import '/model/availablecarlistmodel.dart';
import 'package:rideal/model/cardetailsmodel.dart';

class Cardetails extends StatefulWidget {
  Cardetails({super.key,required this.car});
  final Availablecarlistmodel car;
   
  @override
  State<Cardetails> createState() => _CardetailsState();
}

class _CardetailsState extends State<Cardetails> {
  int currentIndex = 0;
String selectedOption = 'ride';
  final List<CarDetails> cars = [
    CarDetails(name: 'Mustang Shelby GT', imagePath: 'assets/images/mustang1.png', rating: 4.9, reviews: 531,specifications: [
      SpecificationsCardDetails(heading: "Max Power", subHeading: "10 km per litre",icon: Icon(Icons.battery_2_bar_rounded,size:28 ,)),
      SpecificationsCardDetails(heading: "Fuel", subHeading: "230 kph",icon: Icon(Icons.local_gas_station,size:28)),
      SpecificationsCardDetails(heading: "230kph", subHeading: "2.5 sec",icon: Icon(Icons.speed,size:28)),
      SpecificationsCardDetails(heading: "0-60 mph", subHeading: "2.5 sec",icon: Icon(Icons.flash_on,size:28)),
    ],features:[
      FeaturesCarDetails(Feature: "Model", Description: "GT500"),
      FeaturesCarDetails(Feature: "Capacity", Description: "760hp"),
      FeaturesCarDetails(Feature: "Color", Description: "Red"),
      FeaturesCarDetails(Feature: "Fuel Type", Description: "Octane"),
      FeaturesCarDetails(Feature: "Gear Type", Description: "Automatic")

    ] ),
    CarDetails(name: 'Chevrolet Camaro', imagePath: 'assets/images/mustang2.png', rating: 4.8, reviews: 412,specifications: [
      SpecificationsCardDetails(heading: "Max Power", subHeading: "10 km per litre",icon: Icon(Icons.battery_2_bar_rounded,size:28)),
      SpecificationsCardDetails(heading: "Fuel", subHeading: "230 kph",icon: Icon(Icons.local_gas_station,size:28)),
      SpecificationsCardDetails(heading: "230kph", subHeading: "2.5 sec",icon: Icon(Icons.speed,size:28)),
      SpecificationsCardDetails(heading: "0-60 mph", subHeading: "2.5 sec",icon: Icon(Icons.flash_on,size:28)),
    ],features:[
      FeaturesCarDetails(Feature: "Model", Description: "GT500"),
      FeaturesCarDetails(Feature: "Capacity", Description: "760hp"),
      FeaturesCarDetails(Feature: "Color", Description: "Red"),
      FeaturesCarDetails(Feature: "Fuel Type", Description: "Octane"),
      FeaturesCarDetails(Feature: "Gear Type", Description: "Automatic")
    ]),
    CarDetails(name: 'Dodge Challenger', imagePath: 'assets/images/mustang1.png', rating: 4.7, reviews: 390,specifications: [
      SpecificationsCardDetails(heading: "Max Power", subHeading: "10 km per litre",icon: Icon(Icons.battery_2_bar_rounded,size:24)),
      SpecificationsCardDetails(heading: "Fuel", subHeading: "230 kph",icon: Icon(Icons.local_gas_station,size:24)),
      SpecificationsCardDetails(heading: "230kph", subHeading: "2.5 sec",icon: Icon(Icons.speed,size:24)),
      SpecificationsCardDetails(heading: "0-60 mph", subHeading: "2.5 sec",icon: Icon(Icons.flash_on,size:24)),
    ],features:[
      FeaturesCarDetails(Feature: "Model", Description: "GT500"),
      FeaturesCarDetails(Feature: "Capacity", Description: "760hp"),
      FeaturesCarDetails(Feature: "Color", Description: "Red"),
      FeaturesCarDetails(Feature: "Fuel Type", Description: "Octane"),
      FeaturesCarDetails(Feature: "Gear Type", Description: "Automatic")
    ]),
    CarDetails(name: 'Dodge Challenger', imagePath: 'assets/images/mustang2.png', rating: 4.7, reviews: 390,specifications: [
      SpecificationsCardDetails(heading: "Max Power", subHeading: "10 km per litre",icon: Icon(Icons.battery_2_bar_rounded,size:28)),
      SpecificationsCardDetails(heading: "Fuel", subHeading: "230 kph",icon: Icon(Icons.local_gas_station,size:28)),
      SpecificationsCardDetails(heading: "230kph", subHeading: "2.5 sec",icon: Icon(Icons.speed,size:28)),
      SpecificationsCardDetails(heading: "0-60 mph", subHeading: "2.5 sec",icon: Icon(Icons.flash_on,size:28)),
    ],features:[
      FeaturesCarDetails(Feature: "Model", Description: "GT500"),
      FeaturesCarDetails(Feature: "Capacity", Description: "760hp"),
      FeaturesCarDetails(Feature: "Color", Description: "Red"),
      FeaturesCarDetails(Feature: "Fuel Type", Description: "Octane"),
      FeaturesCarDetails(Feature: "Gear Type", Description: "Automatic")
    ]),
  ];
  void goNext() {
    setState(() {
      if (currentIndex < cars.length - 1) {
        currentIndex++;
      }
    });
  }

  void goBack() {
    setState(() {
      if (currentIndex > 0) {
        currentIndex--;
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final car = cars[currentIndex];
    return Scaffold(
      appBar: AppBar(title: Text("Back"),centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 10.w),
            
            // Car Name
            Text(
        car.name,
        style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
            ),
        
            SizedBox(height: 8.w),
        
            // Rating Row
            Row(
        children: [
          Icon(Icons.star, color: Colors.amber),
          Text(
            "${car.rating} (${car.reviews} reviews)",
            style: TextStyle(color: Colors.grey, fontSize: 15.sp),
          ),
        ],
            ),
        
            SizedBox(height: 10.w),
        
            // Car Image with navigation
            SizedBox(
        height: 260.w,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 16.w,
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios, size: 30),
                onPressed: goBack,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Image.asset(
                car.imagePath,
                fit: BoxFit.contain,
                height: 250.w,
              ),
            ),
            Positioned(
              right: 16.w,
              child: IconButton(
                icon: Icon(Icons.arrow_forward_ios, size: 30),
                onPressed: goNext,
              ),
            ),
          ],
        ),
            ),
        
            SizedBox(height: 10.w),
        
            // Specifications Header
            Text(
        "Specifications",
        style: TextStyle(fontSize: 25.sp, fontWeight: FontWeight.w500, color: Colors.black54),
            ),
        
            SizedBox(height: 5.w),
        
            // Specifications List
            SizedBox(
        height: 130.w,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: car.specifications.length,
          itemBuilder: (BuildContext context, int index) {
            final spec = car.specifications[index];
            return CarSpecificationCard(spec);
          },
        ),
            ),
        
            SizedBox(height: 10.w),
        
            // Features Header
            Text(
        "Features",
        style: TextStyle(fontSize: 25.sp, fontWeight: FontWeight.w500, color: Colors.black54),
            ),
            SizedBox(height: 10.w),
        Column(
  children: car.features.map((feature) => CarFeaturesCard(feature)).toList(),
),
SizedBox(height: 16.w),
Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: 55.w,
                  width: 180.w,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>RequestSentScreen()),);
                      
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: selectedOption == 'later' ? Color(0xFFFFFAF0) : Colors.orange,
                      side: BorderSide(color: Colors.orange),
                      // fixedSize: Size(180, 55),
                      backgroundColor: selectedOption == 'later' ? Colors.amber[300] : null,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                    child: Text("Book Later", style: TextStyle(fontSize: 18.sp)),
                  ),
                ),
                SizedBox(
                  height: 55.w,
                  width: 180.w,
                  child: OutlinedButton(
                    onPressed: () { 
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>RequestRent_II(
                        locationInfoWidget: locationInfo(),
                         carInfoCardWidget: carInfoCard(),
                            paymentOptionWidget: paymentMethodSelector(context),
                            confirmButtonWidget: confirmButton(context),
                            )
                            )
                            );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: selectedOption == 'ride' ? Color(0xFFFFFAF0) : Colors.orange,
                      side: BorderSide(color: Colors.orange),
                      backgroundColor: selectedOption == 'ride' ? Colors.amber[300] : null,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                    child: Text("Ride Now", style: TextStyle(fontSize: 18.sp)),
                  ),
                ),
              ],
            ),
          ],
          
        ),
      
          ),
        ),
      ),
    );
  }
  Widget CarSpecificationCard(SpecificationsCardDetails spec){
    return Padding(
      padding: EdgeInsets.all(10.0.w),
      child: Container(
        width: 120.w,
        decoration: BoxDecoration(
          color: Color(0xFFFFFAF0),
          border: Border.all(color: Colors.amber,),borderRadius: BorderRadius.circular(10.r)
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

          Container(child: spec.icon,),
          SizedBox(height: 5.w,),
          Container(child: Text(spec.heading,style: TextStyle(color: Colors.grey.shade700,fontSize: 16.sp))),
          Container(child: Text(spec.subHeading,style: TextStyle(color: Colors.grey,fontSize: 15.sp),),)
            
          ],
        ),
      ),
    );
  }
  Widget CarFeaturesCard(FeaturesCarDetails features){
    return Padding(
      padding: EdgeInsets.only(bottom: 10.w),
      child: Container(
        width: double.infinity,
        height: 48.w,
        decoration: BoxDecoration(
        color:  Color(0xFFFFFAF0),
        border: Border.all(color: Colors.amber,),borderRadius: BorderRadius.circular(10.r)
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.only(left: 10.w),
                child: Text(features.Feature,style: TextStyle(fontSize: 16.sp,color: Colors.grey.shade700),),
              ),
              Container(
                padding: EdgeInsets.only(right: 10.w),
                child: Text(features.Description,style: TextStyle(fontSize: 16.sp,color: Colors.grey.shade600),),
              ),
            ],
          ),
      ),
    );
  }
}
