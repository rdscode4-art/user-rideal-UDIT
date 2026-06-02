import 'package:flutter/material.dart';
import 'package:rideal/screens/transport/RequestRent.dart';
class RequestRent_II extends StatefulWidget {
  const RequestRent_II({super.key,required this.locationInfoWidget,required this.carInfoCardWidget,required this.paymentOptionWidget,required  this.confirmButtonWidget});
  final Widget locationInfoWidget;
  final Widget carInfoCardWidget;
  final Widget paymentOptionWidget;
  final Widget confirmButtonWidget;

  @override
  State<RequestRent_II> createState() => _RequestRent_IIState();
}

class _RequestRent_IIState extends State<RequestRent_II> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request for Rent',style: TextStyle(fontWeight: FontWeight.w500,fontSize: 25),),
      ),
      body: SingleChildScrollView(
        child:  Padding(padding: EdgeInsets.all(16.0),
        child:Column(
          children: [
            SizedBox(height: 20,),
            locationInfo(),
            SizedBox(height: 18),
            carInfoCard(),
            SizedBox(height: 20,),
            chargeInfo(),
            SizedBox(height: 40),
            paymentMethodSelector(context),
            SizedBox(height: 30),
            confirmButton(context), 

          ],
        )
        ),
      )
    );
  }

}
Widget chargeInfo(){
return Container(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text("Charge", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade700),textAlign: TextAlign.left,),
        SizedBox(height: 12),
        _chargeRow("Mustang/per hours", "\$200"),
        _chargeRow("Vat (5%)", "\$20"),
        _chargeRow("Promo Code", "-\$5"),
    ],
  ),
);
}
Widget _chargeRow(String label, String amount, {bool isTotal = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          fontSize: isTotal ? 17 : 16,
          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          color: isTotal ? Colors.black : Colors.grey.shade700,
        )),
        Text(amount, style: TextStyle(
          fontSize: isTotal ? 17 : 16,
          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          color: isTotal ? Colors.black : Colors.grey.shade700,
        )),
      ],
    ),
  );
}