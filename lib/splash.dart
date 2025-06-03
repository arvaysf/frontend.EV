import 'package:flutter/material.dart';
import 'login.dart'; 

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 2), () {
      // ignore: use_build_context_synchronously
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => Login(),
        ), 
      );
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4CB8C4), //el top
              Color(0xFF3CD3AD), // el bottom
            ],
          ),
        ),
        child: Center(
          child: Hero(
            tag: 'logo',
            child: Image.asset('assets/logo2.png', width: 120, height: 120),
          ),
        ),
      ),
    );
  }
}
