import 'package:flutter/material.dart';
import 'package:rideal/screens/transport/confirmed.dart';

class ThankYou extends StatefulWidget {
  const ThankYou({super.key});
  @override
  State<ThankYou> createState() => _ThankYouState();
}

class _ThankYouState extends State<ThankYou> {
  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Confirmed(
        rideType: "",
      )));
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(""),
      ),
      body: Center(
        child: Column(
          children: [
            Container(
                padding:EdgeInsets.only(top:150),
              child: Image.asset("assets/images/thankyou.png"),
            ),
            SizedBox(height: 20),
            Container(
              child: Text(
                "Thank you",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22),
              ),
            ),
            SizedBox(height: 10),
            Container(
              child: Text(
                "Your booking has been placed sent to \n Md. Sharif Ahmed",
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
