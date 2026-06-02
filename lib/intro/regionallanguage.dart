import 'package:flutter/material.dart';
import 'package:rideal/intro/onboardScreen.dart';
class Language extends StatefulWidget {
  const Language({super.key});

  @override
  State<Language> createState() => _LanguageState();
}

class _LanguageState extends State<Language> {
  String _selectedLanguage = "English";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Choose Your Language"),
      ),
      body:  Column(
        children: [
          SizedBox(
            height: 700,
            child: ListView(
                children: [
            languageBuilder("English", _selectedLanguage, (value) {
              setState(() {
                _selectedLanguage = value!;
              });
            }),
            languageBuilder("Hindi", _selectedLanguage, (value) {
              setState(() {
                _selectedLanguage = value!;
              });
            }),
            languageBuilder("Spanish", _selectedLanguage, (value) {
              setState(() {
                _selectedLanguage = value!;
              });
            }),
            languageBuilder("English", _selectedLanguage, (value) {
              setState(() {
                _selectedLanguage = value!;
              });
            }),
            languageBuilder("Hindi", _selectedLanguage, (value) {
              setState(() {
                _selectedLanguage = value!;
              });
            }),
            languageBuilder("Spanish", _selectedLanguage, (value) {
              setState(() {
                _selectedLanguage = value!;
              });
            }),
            languageBuilder("English", _selectedLanguage, (value) {
              setState(() {
                _selectedLanguage = value!;
              });
            }),
            languageBuilder("Hindi", _selectedLanguage, (value) {
              setState(() {
                _selectedLanguage = value!;
              });
            }),
            languageBuilder("Spanish", _selectedLanguage, (value) {
              setState(() {
                _selectedLanguage = value!;
              });
            }),
            languageBuilder("English", _selectedLanguage, (value) {
              setState(() {
                _selectedLanguage = value!;
              });
            }),
            languageBuilder("Hindi", _selectedLanguage, (value) {
              setState(() {
                _selectedLanguage = value!;
              });
            }),
            languageBuilder("Spanish", _selectedLanguage, (value) {
              setState(() {
                _selectedLanguage = value!;
              });
            }),
            languageBuilder("English", _selectedLanguage, (value) {
              setState(() {
                _selectedLanguage = value!;
              });
            }),
            languageBuilder("Hindi", _selectedLanguage, (value) {
              setState(() {
                _selectedLanguage = value!;
              });
            }),
            languageBuilder("Spanish", _selectedLanguage, (value) {
              setState(() {
                _selectedLanguage = value!;
              });
            }),
            languageBuilder("English", _selectedLanguage, (value) {
              setState(() {
                _selectedLanguage = value!;
              });
            }),
            languageBuilder("Hindi", _selectedLanguage, (value) {
              setState(() {
                _selectedLanguage = value!;
              });
            }),
            languageBuilder("Spanish", _selectedLanguage, (value) {
              setState(() {
                _selectedLanguage = value!;
              });
            }),
                ],
              ), 
          ),
          SizedBox(height: 20),
          ElevatedButton(onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (context)=>WelcomeScreen()));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            fixedSize: Size(200, 50),
            ), child: Text("Choose",style: TextStyle(color: Colors.white),),
            ),
        ],
      ),
    );
  }
  Widget languageBuilder(String language, String selectedLanguage, ValueChanged<String?> onChanged) {
  return RadioListTile<String>(
    value: language,
    groupValue: selectedLanguage,
    onChanged: onChanged,
    title: Text(language),
  );
}
}
