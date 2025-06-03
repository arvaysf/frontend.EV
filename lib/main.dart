import 'package:authentication/home_page.dart';
import 'package:authentication/screens/map/map_screen.dart';
import 'package:authentication/sign_up.dart';
import 'package:authentication/splash.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EV Route & Charging',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const Homepage(), 
    );
  }
}
