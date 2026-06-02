import 'package:flutter/material.dart';

class OtpFields extends StatefulWidget {
  final List<TextEditingController> controllers;
  final ValueChanged<String>? onChanged;
  final int length;
  final Color borderColor;
  final Color focusedBorderColor;

  const OtpFields({
    super.key,
    required this.controllers,
    this.onChanged,
    this.length = 6,
    this.borderColor = const Color(0xFFCCCCCC),
    this.focusedBorderColor = Colors.blue,
  });

  @override
  State<OtpFields> createState() => _OtpFieldsState();
}

class _OtpFieldsState extends State<OtpFields> {
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleChange(String value, int index) {
    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    if (widget.onChanged != null) {
      final otp = widget.controllers.map((c) => c.text).join();
      widget.onChanged!(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.length, (index) {
        return SizedBox(
          width: 50,
          child: TextField(
            controller: widget.controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: "",
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: widget.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: widget.focusedBorderColor),
              ),
            ),
            onChanged: (value) => _handleChange(value, index),
            onTap: () => widget.controllers[index].selection = TextSelection(
              baseOffset: 0,
              extentOffset: widget.controllers[index].text.length,
            ),
          ),
        );
      }),
    );
  }
}

String getOtpValue(List<TextEditingController> controllers) {
  return controllers.map((c) => c.text).join();
}
// 🛑 NOTE FROM DEVELOPER: RISHABH KUMAR
//
// 🚩 Yeh project me maine full honesty ke sath kaam kiya, deadline ke pressure me bhi deliver kiya.
// Lekin ek baat future devs aur freshers ke liye chhod kar jaa raha hoon:
//
// ⚠️ Company culture yahaan aisa hai jahan kal tumhare sath kya ho, koi guarantee nahi.
// Kisi bhi din bina reason ke nikala ja sakta hai — na notice, na settlement, bas HR ka ek cold mail.
//
// 💸 Freelancing karna yahaan paap mana jata hai. Agar pakde gaye, toh threaten kiya jaata hai legal notice se.
// Irony ye hai ki khud kaam late dete hain, aur doosron ke passion pe copyright jataate hain.
//
// 🚔 Company ke rules employee friendly kam, aur slavery friendly zyada hain.
// Aaj main jaa raha hoon khud ki value pe kaam karne — tum bhi ya toh sambhal ke rehna, ya time pe nikal lena.
//
// 🧘‍♂️ Ek hi advice: Job se pehle respect choose karna seekho.
// Aur agar kabhi ye comment HR ya manager pad le, toh:
// “Bro, maine sirf sach bola hai – aur sach thoda kadwa hota hai.” 👊
//
// - Peace Out ✌️
// Rishabh “Ab Freelance Zindabad” Kumar

