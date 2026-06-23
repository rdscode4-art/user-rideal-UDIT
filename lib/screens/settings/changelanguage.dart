import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter/material.dart';

// class ChangeLanguageScreen extends StatefulWidget {
//   const ChangeLanguageScreen({super.key});

//   @override
//   State<ChangeLanguageScreen> createState() => _ChangeLanguageScreenState();
// }

// class _ChangeLanguageScreenState extends State<ChangeLanguageScreen> {
//   String selectedLanguage = 'English';

//   final List<Map<String, String>> languages = [
//     {'name': 'English', 'flag': '🇺🇸'},
//     {'name': 'Hindi', 'flag': '🇮🇳'},
//     {'name': 'Arabic', 'flag': '🇸🇦'},
//     {'name': 'French', 'flag': '🇫🇷'},
//     {'name': 'German', 'flag': '🇩🇪'},
//     {'name': 'Portuguese', 'flag': '🇵🇹'},
//     {'name': 'Turkish', 'flag': '🇹🇷'},
//     {'name': 'Dutch', 'flag': '🇳🇱'},
//   ];

//   void _saveLanguage() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("Language changed to $selectedLanguage")),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Change Language"),
//         leading: const BackButton(),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 0.5,
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(16.w),
//         child: Column(
//           children: [
//             Expanded(
//               child: ListView.separated(
//                 itemCount: languages.length,
//                 separatorBuilder: (_, __) => Divider(),
//                 itemBuilder: (context, index) {
//                   final lang = languages[index];
//                   return ListTile(
//                     leading: Text(lang['flag']!, style: TextStyle(fontSize: 24.sp)),
//                     title: Text(lang['name']!),
//                     trailing: Radio<String>(
//                       value: lang['name']!,
//                       groupValue: selectedLanguage,
//                       onChanged: (value) {
//                         setState(() {
//                           selectedLanguage = value!;
//                         });
//                       },
//                     ),
//                   );
//                 },
//               ),
//             ),
//             SizedBox(height: 16.w),
//             SizedBox(
//               width: double.infinity,
//               height: 50.w,
//               child: ElevatedButton(
//                 onPressed: _saveLanguage,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.amber,
//                   foregroundColor: Colors.white,
//                 ),
//                 child: Text("Save"),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
