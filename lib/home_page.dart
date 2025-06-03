import 'package:authentication/screens/map/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:authentication/screens/my_car.dart';
import 'package:authentication/screens/profile.dart';
import 'package:authentication/screens/home/energy_choice.dart'; // Add this import

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _selectedIndex = 0; 

  void _navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index; 
    });
  }

  final List<Widget> _pages = [
    MapScreen(),
    EnergyChoiceScreen(),
    MyCar(),
    Profile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_selectedIndex], 
      bottomNavigationBar: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: GNav(
            backgroundColor: Colors.white,
            color: const Color.fromARGB(255, 59, 63, 62),
            activeColor: Color.fromARGB(255, 47, 48, 48),
            tabBackgroundColor: Color(0xFF4CB8C4).withOpacity(0.8),
            gap: 5,

            selectedIndex: _selectedIndex,
            onTabChange: (index) {
              _navigateBottomBar(index);
            },

            padding: EdgeInsets.all(20),
            tabs: const [
              GButton(icon: Icons.map, text: "Map",),
              GButton(icon: Icons.home, text: "home",), 
              GButton(icon: Icons.directions_car,text: "car"),
              GButton(icon: Icons.person, text: "me" ),
            ],
          ),
        ),
      ),
    );
  }
}