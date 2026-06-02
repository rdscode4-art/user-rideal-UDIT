import 'package:flutter/material.dart';
import 'package:rideal/screens/transport/RequestRent.dart';
import 'package:rideal/screens/transport/requestrent_II.dart';
import '/model/availablecarlistmodel.dart';
import 'package:rideal/model/cardetailsmodel.dart';

class Cardetails extends StatefulWidget {
  const Cardetails({super.key,required this.car});
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
            padding: EdgeInsets.all(20),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            
            // Car Name
            Text(
        car.name,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
        
            const SizedBox(height: 8),
        
            // Rating Row
            Row(
        children: [
          const Icon(Icons.star, color: Colors.amber),
          Text(
            "${car.rating} (${car.reviews} reviews)",
            style: const TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ],
            ),
        
            const SizedBox(height: 10),
        
            // Car Image with navigation
            SizedBox(
        height: 260,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 30),
                onPressed: goBack,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Image.asset(
                car.imagePath,
                fit: BoxFit.contain,
                height: 250,
              ),
            ),
            Positioned(
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 30),
                onPressed: goNext,
              ),
            ),
          ],
        ),
            ),
        
            const SizedBox(height: 10),
        
            // Specifications Header
            const Text(
        "Specifications",
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500, color: Colors.black54),
            ),
        
            const SizedBox(height: 5),
        
            // Specifications List
            SizedBox(
        height: 130,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: car.specifications.length,
          itemBuilder: (BuildContext context, int index) {
            final spec = car.specifications[index];
            return CarSpecificationCard(spec);
          },
        ),
            ),
        
            const SizedBox(height: 10),
        
            // Features Header
            const Text(
        "Features",
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500, color: Colors.black54),
            ),
            const SizedBox(height: 10),
        Column(
  children: car.features.map((feature) => CarFeaturesCard(feature)).toList(),
),
SizedBox(height: 16),
Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: 55,
                  width: 180,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>RequestSentScreen()),);
                      
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: selectedOption == 'later' ? Color(0xFFFFFAF0) : Colors.orange,
                      side: BorderSide(color: Colors.orange),
                      // fixedSize: Size(180, 55),
                      backgroundColor: selectedOption == 'later' ? Colors.amber[300] : null,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text("Book Later", style: TextStyle(fontSize: 18)),
                  ),
                ),
                SizedBox(
                  height: 55,
                  width: 180,
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text("Ride Now", style: TextStyle(fontSize: 18)),
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
      padding: const EdgeInsets.all(10.0),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: Color(0xFFFFFAF0),
          border: Border.all(color: Colors.amber,),borderRadius: BorderRadius.circular(10)
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

          Container(child: spec.icon,),
          SizedBox(height: 5,),
          Container(child: Text(spec.heading,style: TextStyle(color: Colors.grey.shade700,fontSize: 16))),
          Container(child: Text(spec.subHeading,style: TextStyle(color: Colors.grey,fontSize: 15),),)
            
          ],
        ),
      ),
    );
  }
  Widget CarFeaturesCard(FeaturesCarDetails features){
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
        color:  Color(0xFFFFFAF0),
        border: Border.all(color: Colors.amber,),borderRadius: BorderRadius.circular(10)
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.only(left: 10),
                child: Text(features.Feature,style: TextStyle(fontSize: 16,color: Colors.grey.shade700),),
              ),
              Container(
                padding: EdgeInsets.only(right: 10),
                child: Text(features.Description,style: TextStyle(fontSize: 16,color: Colors.grey.shade600),),
              ),
            ],
          ),
      ),
    );
  }
}
