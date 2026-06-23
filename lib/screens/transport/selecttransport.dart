import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:rideal/screens/transport/selectavailablecar.dart';
import '/model/selecttransportcard.dart';
import 'package:rideal/widget/selecttransportcard.dart';

class SelectTransport extends StatefulWidget {
  const SelectTransport({super.key});

  @override
  State<SelectTransport> createState() => _SelectTransportState();
}

class _SelectTransportState extends State<SelectTransport> {
  String appbartitle = "Select Your Transport";
  String bodyTitle = "Select Your Transport";
  int? selectedIndex;
  List <transportcarddatamodel> listcard=[
    transportcarddatamodel(imagepath: "assets/images/car.png", description: "Car"),
    transportcarddatamodel(imagepath: "assets/images/bike.png", description: "Bike"),
    transportcarddatamodel(imagepath: "assets/images/cycle.png", description: "Cycle"),
    transportcarddatamodel(imagepath: "assets/images/taxi.png", description: "Taxi")
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appbartitle, style: TextStyle(fontSize: 22.sp,fontWeight: FontWeight.w400,)),
      ),
      body: Center(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.only(bottom: 30.w),
                margin: EdgeInsets.only(top: 20.w),
                child: Text(bodyTitle,
                style: TextStyle(fontWeight: FontWeight.bold,fontSize: 26.sp),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Container(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: listcard.length,
                      itemBuilder: (BuildContext context, int index) {
                        final card = listcard[index];
                        final isSelected = index == selectedIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>SelectAvailableCarscreen()),);
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color:  isSelected ? Colors.amber[200] : Color(0xFFFFFAF0),// light yellow background
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: isSelected ? Colors.orange : Colors.amber,
                            width: isSelected ? 1.5 : 1.5,
                          ),
                        ),
                        
                        child:  buildingselecttransportcard(card: card),
                      ),
                    );
                      },
                    ),
                  ),
                ),
              )
              ]
              )
              ),
      ),
    );
  }
}
