import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rideal/screens/dashboard/BottomNavigation.dart';
import 'package:flutter/material.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back and Title
              Row(
                children: [
                  Icon(Icons.arrow_back_ios, size: 18),
                  SizedBox(width: 4.w),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text('Back', style: TextStyle(fontSize: 16.sp)),
                  ),
                ],
              ),
              SizedBox(height: 24.w),

              // Title
              Center(
                child: Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 24.w),

              // Profile image
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    Positioned(
                      right: 4.w,
                      bottom: 4.w,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.w),
                        ),
                        padding: EdgeInsets.all(6.w),
                        child: Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: 32.w),

              // Full Name
              TextField(
                decoration: InputDecoration(
                  hintText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.w),

              // Phone with flag
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '+880 Your mobile number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.w),

              // Email
              // TextField(
              //   decoration: InputDecoration(
              //     hintText: 'Email',
              //     border: OutlineInputBorder(),
              //   ),
              // ),
              // SizedBox(height: 16.w),

              // Street
              TextField(
                decoration: InputDecoration(
                  hintText: 'Street',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.w),

              // City dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  hintText: 'City',
                  border: OutlineInputBorder(),
                ),
                items: ['City 1', 'City 2', 'City 3']
                    .map((city) => DropdownMenuItem(
                  value: city,
                  child: Text(city),
                ))
                    .toList(),
                onChanged: (value) {},
              ),
              SizedBox(height: 16.w),

              // District dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  hintText: 'District',
                  border: OutlineInputBorder(),
                ),
                items: ['District 1', 'District 2', 'District 3']
                    .map((district) => DropdownMenuItem(
                  value: district,
                  child: Text(district),
                ))
                    .toList(),
                onChanged: (value) {},
              ),
              SizedBox(height: 32.w),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.w),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const BottomNavigationLogic()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC107),
                        padding: EdgeInsets.symmetric(vertical: 16.w),
                      ),
                      child: Text(
                        'Save',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.w),
            ],
          ),
        ),
      ),
    );
  }
}
