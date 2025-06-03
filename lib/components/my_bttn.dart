import 'package:flutter/material.dart';

class MyBttn extends StatelessWidget {
  final GlobalKey<FormState>? formKey; // Made optional
  final Map<String, TextEditingController>? controllers; // Made optional
  final String buttonText;
  final void Function() onPressed;
  final double width;
  final double height;

  const MyBttn({
    super.key,
    this.formKey, // Optional form key
    this.controllers, // Optional controllers
    required this.buttonText,
    required this.onPressed,
    this.width = 340,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.fromRGBO(76, 184, 196, 1), Color(0xFF3CD3AD)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ElevatedButton(
        onPressed: () {
          // If formKey is provided, validate the form
          if (formKey != null) {
            if (formKey!.currentState?.validate() ?? false) {
              onPressed(); // Execute the callback if validation passes
            } else {
              print('Input is invalid');
            }
          } else {
            // No form validation needed, just execute the callback
            onPressed();
          }
        },
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.transparent),
          elevation: MaterialStateProperty.all(0),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
        child: Text(
          buttonText,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}