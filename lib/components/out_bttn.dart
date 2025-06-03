import 'package:flutter/material.dart';

class LogoutBttn extends StatelessWidget {
  final VoidCallback onPressed;

  const LogoutBttn({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          Alignment.bottomCenter, // Align the button to the bottom center
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2), // Space from the bottom
        child: Column(
          mainAxisSize: MainAxisSize.min, // Ensure column takes minimal space
          children: [
            Divider(
              // Line above the button
              thickness: 1.5,
              color: Colors.grey.shade300, // Line color
              indent: 10, // Space before the line starts
              endIndent: 1, // Space after the line ends
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 5,
              ), // Space between the line and button
              child: TextButton(
                onPressed: onPressed,
                style: TextButton.styleFrom(
                  foregroundColor: const Color.fromARGB(
                    255,
                    10,
                    70,
                    91,
                  ), // Red text color
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 50,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  side: BorderSide.none, // No border
                  backgroundColor: Colors.transparent, // No background
                ).copyWith(
                  // Ensure no visual change when pressed
                  overlayColor: MaterialStateProperty.all(Colors.transparent),
                  shadowColor: MaterialStateProperty.all(Colors.transparent),
                ),
                child: const Text("Log out"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
