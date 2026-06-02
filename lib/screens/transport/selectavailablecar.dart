import 'package:flutter/material.dart';
import 'package:rideal/widget/availablecarcard.dart';
import 'package:rideal/model/availablecarlistmodel.dart'; // this should contain the renamed AvailableCarModel

class SelectAvailableCarscreen extends StatefulWidget {
  const SelectAvailableCarscreen({super.key});

  @override
  State<SelectAvailableCarscreen> createState() => _SelectAvailableCarscreenState();
}

class _SelectAvailableCarscreenState extends State<SelectAvailableCarscreen> {
  final List<Availablecarlistmodel> availableCars = [
    Availablecarlistmodel(name: "BMW Cabrio", image: "assets/images/car.png"),
    Availablecarlistmodel(name: "Mustang Shelby GT", image: "assets/images/car.png"),
   Availablecarlistmodel(name: "BMW i8", image: "assets/images/car.png"),
    Availablecarlistmodel(name: "Jaguar Silber", image: "assets/images/car.png"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Back"),centerTitle: false,),
      body: SafeArea(
        child: Center(      
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 35),
                Container(
                  child:Text("Available cars for ride",textAlign:TextAlign.left,style: TextStyle(fontWeight: FontWeight.bold,fontSize: 25),),
                ),
                SizedBox(height: 15,),
                Container(
                  child: Text("18 cars found",style: TextStyle(color: Colors.grey,fontSize: 18),textAlign:TextAlign.left),
                ),
                SizedBox(height: 12),
                Expanded(child: ListView.builder(     
                  itemCount: availableCars.length,
                  itemBuilder: (BuildContext context, int index) {
                    return CarCard(car: availableCars[index]);
                  },
                ),)
              ],
            ),
          ),
        ),
      )
    );
  }
}