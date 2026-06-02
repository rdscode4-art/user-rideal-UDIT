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
        title: const Text("Change Language"),
        leading: const BackButton(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: languages.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final lang = languages[index];
                  return ListTile(
                    // leading: Text(
                    //   lang['flag']!,
                    //   style: const TextStyle(fontSize: 24),
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: SaveLanguage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade800,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Save",style: TextStyle(color: Colors.black,fontSize: 18),),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
