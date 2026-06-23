import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:rideal/intro/onboardScreen.dart';

class RegionalLanguageScreen extends StatefulWidget {
  const RegionalLanguageScreen({super.key});

  @override
  State<RegionalLanguageScreen> createState() => _RegionalLanguageScreenState();
}

class _RegionalLanguageScreenState extends State<RegionalLanguageScreen> {
  String selectedLanguage = 'English';

  final List<Map<String, String>> languages = [
    {'name': 'English'},
    {'name': 'Hindi'},
    {'name': 'Punjabi'},
    {'name': 'Tamil'},
    {'name': 'German'},
    {'name': 'Portuguese'},
    {'name': 'Turkish',},
    {'name': 'Dutch',},
  ];

  void SaveLanguage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Language changed to $selectedLanguage")),
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Change Language"),
        leading: const BackButton(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: languages.length,
                separatorBuilder: (_, __) => Divider(),
                itemBuilder: (context, index) {
                  final lang = languages[index];
                  return ListTile(
                    // leading: Text(
                    //   lang['flag']!,
                    //   style: TextStyle(fontSize: 24.sp),
                    // ),
                    title: Text(lang['name']!),
                    trailing: Radio<String>(
                      value: lang['name']!,
                      groupValue: selectedLanguage,
                      onChanged: (value) {
                        setState(() {
                          selectedLanguage = value!;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16.w),
            SizedBox(
              width: double.infinity,
              height: 50.w,
              child: ElevatedButton(
                onPressed: SaveLanguage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade800,
                  foregroundColor: Colors.white,
                ),
                child: Text("Save",style: TextStyle(color: Colors.black,fontSize: 18.sp),),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
