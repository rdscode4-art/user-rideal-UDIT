import 'package:flutter/material.dart';
import 'package:rideal/screens/dashboard/BottomNavigation.dart';

class ThankYouFuture extends StatefulWidget {
  const ThankYouFuture({super.key});

  @override
  State<ThankYouFuture> createState() => _ThankYouFutureState();
}

class _ThankYouFutureState extends State<ThankYouFuture> {
  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BottomNavigationLogic()),
      );
    });
    return Scaffold(
      appBar: AppBar(title: Text("")),
      body: Center(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(top: 150),
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
