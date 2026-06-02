import 'package:flutter/material.dart';

class HelpAndSupportScreen extends StatelessWidget {
  const HelpAndSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Help and Support",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          "Lorem ipsum dolor sit amet consectetur. Sit pulvinar "
          "morbi mauris eu nibh semper nisl pretium hac netus. "
          "Sed non faucibus nec tellus eu arcu. Nulla sit congue "
          "facilisis vestibulum egestas nisi feugiat pharetra. "
          "Odio sit tortor mattis orci eros ipsum platea interdum. "
          "Lorem felis est aliquet arcu nullam pellentesque. "
          "Et habitasse ac orci eu nunc euismod rhoncus facilisis "
          "sollicitudin.",
          style: TextStyle(
            fontSize: 15,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
