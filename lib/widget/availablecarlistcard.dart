import 'package:flutter/material.dart';
import 'package:rideal/model/availablecarlistmodel.dart';
import 'package:rideal/screens/transport/cardetails.dart';
class AvailableCarCard extends StatefulWidget {
  final Availablecarlistmodel car;

  const AvailableCarCard({super.key, required this.car});

  @override
  State<AvailableCarCard> createState() => _AvailableCarCardState();
}

class _AvailableCarCardState extends State<AvailableCarCard> {
  String selectedOption = 'ride'; // 'ride' or 'later'

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFFFFFAF0),
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.amber.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.car.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text("Automatic | 3 seats | Octane", style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text("800m (5mins away)", style: TextStyle(color: Colors.black)),
                        ],
                      ),
                    ],
                  ),
                ),
                Image.asset(widget.car.image, width: 130),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>Cardetails(car: widget.car)),);
                    setState(() {
                      selectedOption = 'later';
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: selectedOption == 'later' ? Color(0xFFFFFAF0) : Colors.orange,
                    side: BorderSide(color: Colors.orange),
                    fixedSize: Size(180, 55),
                    backgroundColor: selectedOption == 'later' ? Colors.amber[300] : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text("Book Later", style: TextStyle(fontSize: 18)),
                ),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      selectedOption = 'ride';
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: selectedOption == 'ride' ? Color(0xFFFFFAF0) : Colors.orange,
                    side: BorderSide(color: Colors.orange),
                    fixedSize: Size(180, 55),
                    backgroundColor: selectedOption == 'ride' ? Colors.amber[300] : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text("Ride Now", style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
