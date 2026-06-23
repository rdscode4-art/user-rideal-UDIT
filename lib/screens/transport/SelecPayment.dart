import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:rideal/screens/FutureRides/thankyoufuture.dart';
import 'package:rideal/screens/transport/thankyou.dart';
class SelectPayment extends StatefulWidget {
  
  final bool isConfirmed;
  const SelectPayment({super.key,required this.paymentOptionWidget,required this.isConfirmed});
final Widget paymentOptionWidget;
  @override
  State<SelectPayment> createState() => _SelectPaymentState();
}

class _SelectPaymentState extends State<SelectPayment> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Payment Method',style: TextStyle(fontWeight: FontWeight.w500,fontSize: 25.sp),),
            SizedBox(height: 5.w),
            Text('Select payment method you want to use',style: TextStyle(fontSize: 15.sp,color: Colors.grey),)
          ],
        ),
      ),
      body: SingleChildScrollView(
        child:  Padding(padding: EdgeInsets.all(16.0.w),
        child: Column(
          children: [
            Container(
              child: widget.paymentOptionWidget),
              SizedBox(height: 50.w),
              SizedBox(
                width: double.infinity,
                height: 60.w,
                child: ElevatedButton(onPressed: (){
                  if(widget.isConfirmed){
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>ThankYou()));
                  }else{
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>ThankYouFuture()));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)
                  )
                ),
                 child: Text("Confirm",style: TextStyle(color: Colors.white,fontSize: 15.sp))),
              )
          ],
        ),
        
      ),
      )
    );
  }
}