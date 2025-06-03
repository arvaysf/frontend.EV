import 'package:flutter/material.dart';

class MyTextfield extends StatelessWidget {
  final TextEditingController controller;
  final String hinText;
  final bool obscureText;
  final String field;
  final String? Function(String?)? validator;

  const MyTextfield({
    super.key,
    required this.controller,
    required this.hinText,
    required this.obscureText,
    required this.field,
    this.validator,
  });

  String? _validateInput(String? value) {
    if (value == null || value.isEmpty) {
      return '$field cannot be empty';
    }

    // Email validation
    if (field == 'Email') {
      // More comprehensive email regex
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      if (!emailRegex.hasMatch(value)) {
        return 'Please enter a valid email address';
      }
    }

    // Username validation
    if (field == 'Username') {
      if (value.length < 6) {
        return 'Username must be at least 6 characters';
      }
      if (value.length > 20) {
        return 'Username must be less than 20 characters';
      }
      if (value.contains(' ')) {
        return 'Username cannot contain spaces';
      }
      if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(value)) {
        return 'Username can only contain letters, numbers, dots and underscores';
      }
    }

    // Password validation
    if (field == 'Password') {
      if (value.length < 6) {
        return 'Password must be at least 6 characters';
      }
    
      // Check for at least one number
      if (!RegExp(r'[0-9]').hasMatch(value)) {
        return 'Password must contain at least one number';
      }
    }

    return validator != null ? validator!(value) : null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: _validateInput,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 20,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
            borderRadius: BorderRadius.circular(30),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade500),
            borderRadius: BorderRadius.circular(30),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red.shade300),
            borderRadius: BorderRadius.circular(30),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red.shade500, width: 1.5),
            borderRadius: BorderRadius.circular(30),
          ),
          fillColor: const Color.fromARGB(255, 240, 240, 240),
          filled: true,
          hintText: hinText,
          hintStyle: const TextStyle(color: Color.fromARGB(255, 176, 176, 176)),
          errorStyle: TextStyle(color: Colors.red.shade700),
        ),
      ),
    );
  }
}