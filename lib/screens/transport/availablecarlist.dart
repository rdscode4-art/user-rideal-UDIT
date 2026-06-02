import 'package:flutter/material.dart';
import '/model/availablecarlistmodel.dart';
import 'package:rideal/widget/availablecarlistcard.dart';
class AvailableCarListScreen extends StatefulWidget {
  const AvailableCarListScreen({super.key,required this.car});
final Availablecarlistmodel car;
  @override
  State<AvailableCarListScreen> createState() => _AvailableCarListScreenState();
}

class _AvailableCarListScreenState extends State<AvailableCarListScreen> {
  int? selectedIndex;
   List <Availablecarlistmodel>  ?availableCars;
  @override
void initState() {
  super.initState();
  availableCars = List.generate(5, (index) => widget.car);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Back"),centerTitle: false,),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
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
                  itemCount: availableCars?.length ?? 0,
itemBuilder: (BuildContext context, int index) {
  if (availableCars == null) return SizedBox(); // or loading indicator
  return AvailableCarCard(car: availableCars![index]);
},
                ),)
              ],
            ),
            )
          ),
      ),
    );
  }
}