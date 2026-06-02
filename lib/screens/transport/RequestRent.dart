import 'package:flutter/material.dart';
import 'package:rideal/screens/transport/thankyou.dart';
class RequestSentScreen extends StatefulWidget {
  const RequestSentScreen({super.key});

  @override
  State<RequestSentScreen> createState() => _RequestSentScreenState();
}

class _RequestSentScreenState extends State<RequestSentScreen> {
  String selectedPayment = 'Visa';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request for Rent',style: TextStyle(fontWeight: FontWeight.w500,fontSize: 25),),
      ),
      body: SingleChildScrollView(
      child:  Padding(padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          SizedBox(height: 20,),
            locationInfo(),
            SizedBox(height: 18),
            carInfoCard(),
            SizedBox(height: 16),
            datetimeFields(),
            promoCodeInput(),
            SizedBox(height: 40),
            paymentMethodSelector(context),
            SizedBox(height: 30),
            // Spacer(),
            confirmButton(context),  
        ],
      ),),
    )
    );
  }
   
}
Widget locationInfo() {
    return Row(
      children: [
        Container(child: Image.asset("assets/images/location.png",height: 120,width: 60,)),  
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Current Location", style: TextStyle(fontWeight:FontWeight.w600,color: Colors.grey.shade800,fontSize: 21)),
            Text("Homitech Space, Santa Ana, USA - 1.3km",style: TextStyle(color: Colors.grey),),
            SizedBox(height: 25),
            Text("Office", style: TextStyle(fontWeight: FontWeight.w600,color: Colors.grey.shade800,fontSize: 21)),
            Text("Homitech Space, Santa Ana, USA - 1.3km",style: TextStyle(color: Colors.grey),)
          ],
        ),
      ],
    );
  }
Widget carInfoCard() {
  return Container(
   height: 90,
    decoration: BoxDecoration(
      color: Color(0xFFFFFAF0),
      borderRadius: BorderRadius.all(Radius.circular(5)),
      border: Border.all(color: Colors.orange)
      
    ),
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mustang Shelby GT",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    SizedBox(width: 4),
                    Text("4.5 (321)", style: TextStyle(color: Colors.grey,fontSize: 18)),
                  ],
                )
              ],
            ),
          ),
          SizedBox(width: 10),
          Image.asset("assets/images/mustang1.png", height: 85, width: 90),
        ],
      ),
    ),
  );
}

  Widget datetimeFields() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            decoration: InputDecoration(
              hintText: 'Date',
              hintStyle: TextStyle(color: Colors.grey,fontSize: 20),
              // prefixIcon: Icon(Icons.calendar_today),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),borderSide: BorderSide(color: Colors.grey.shade200,width: 2)),
              
              
            ),
          ),
        ),
        SizedBox(width: 15),
        Expanded(
          child: TextFormField(
            decoration: InputDecoration(
              hintText: 'Time',
              hintStyle: TextStyle(color: Colors.grey,fontSize: 20),
              // prefixIcon: Icon(Icons.access_time),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),borderSide: BorderSide(color: Colors.grey.shade200,width: 2)),
            ),
          ),
        ),
      ],
    );
  }
  Widget promoCodeInput() {
    return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: TextFormField(
        decoration: InputDecoration(
          hintStyle: TextStyle(color: Colors.grey,fontSize: 20),
          hintText: 'Enter Promo Code',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),borderSide: BorderSide(color: Colors.grey.shade200,width: 2)),
        ),
      ),
    );
  }
Widget paymentMethodSelector(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Select payment method",style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),),
                        // TextButton(
                        //   onPressed: (){
                        // Navigator.push(context, MaterialPageRoute(builder:(context)=>SelectPayment(paymentOptionWidget: paymentMethodSelector(context))));
                        // }, child: Text("View All",style: TextStyle(color: Colors.amber,fontSize: 18,fontWeight: FontWeight.bold),))
            ],
          ),
          SizedBox(height: 25),
          // paymentOption("assets/images/visa.png","Credit Card", "**** 8970"),
          // SizedBox(height: 15),
          paymentOption("assets/images/mastercard.png","UPI", "Pay Online"),
          SizedBox(height: 15),
          paymentOption("assets/images/wallet.png","My Wallet", "\$530.00"),
          SizedBox(height: 15),
          paymentOption("assets/images/cash.png","Cash", "Pay at pickup"),
        ],
      ),
    );
  }

  Widget paymentOption(String imagepath,String title, String subtitle) {
    String selectedPayment = 'Visa';
    return Container(
      height: 80,
      decoration: BoxDecoration(
      color: selectedPayment == title ?Colors.green.shade50:Colors.grey.shade200,
      borderRadius: BorderRadius.all(Radius.circular(5)),
      border: Border.all(color: selectedPayment == title ? Colors.green.shade700 : Colors.grey.shade300),
      
    ),
    child: Padding(
      padding: const EdgeInsets.only(left: 12.0,top: 10),
      child: Row(
          children: [
            Image.asset(imagepath, height: 90, width: 70,fit: BoxFit.fill,),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ]
      ),
    )
    );
    // return RadioListTile<String>(
    //   title: Text(title),
    //   subtitle: Text(subtitle),
    //   value: title,
    //   groupValue: selectedPayment,
    //   onChanged: (value) {
    //     setState(() {
    //       selectedPayment = value!;
    //     });
    //   },
    // );
  }
Widget confirmButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[700],
        minimumSize: Size(double.infinity, 70),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
      ),
      onPressed: () {
      //   // Add booking logic here
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Booking Confirmed")),
        );
        Navigator.push(context, MaterialPageRoute(builder: (context)=>ThankYou()));
       },
      child: Text("Confirm Booking", style: TextStyle(fontSize: 18,color: Colors.white)),
    );
  }
