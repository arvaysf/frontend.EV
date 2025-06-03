import 'package:authentication/components/my_bttn.dart';
import 'package:authentication/sign_up.dart';
import 'package:flutter/material.dart';
import 'package:authentication/components/my_txtfield.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:authentication/home_page.dart'; 
import 'package:authentication/utils/registration_api.dart' as auth_api;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:authentication/models/user.dart'; 

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Login(),
      routes: {
        '/Homepage': (context) => const Homepage(), 
      },
    ),
  );
}

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {
    'username': TextEditingController(),
    'password': TextEditingController(), 
  };
  bool isLoading = false;

  void logUserIn() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        isLoading = true; 
      });

      final response = await http.post(
        Uri.parse(auth_api.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': controllers['username']!.text,
          'password': controllers['password']!.text,
        }),
      );

      setState(() {
        isLoading = false; 
      });

      if (response.statusCode == 200) {
        print('Successfully Logged in!');
        
        // parse user data from response
        final Map<String, dynamic> userData = json.decode(response.body);
        final User user = User.fromJson(userData);
        
        // save eluser data to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', user.name);
        await prefs.setString('user_username', user.username);
        await prefs.setString('user_email', user.email);
        
        print('Full login response: $userData');
        
        // Handles el vehicle info 
        List<String> vehicleNames = [];
        
        // cheks for diff formats of vehicle data in the response
        if (userData.containsKey('vehicles') && userData['vehicles'] is List) {
          final vehicles = userData['vehicles'] as List;
          for (var vehicle in vehicles) {
            if (vehicle is Map && vehicle.containsKey('name')) {
              vehicleNames.add(vehicle['name']);
            }
          }
          print('Vehicles saved from vehicles list: $vehicleNames');
        } else if (userData.containsKey('vehicleNames') && userData['vehicleNames'] is List) {
          vehicleNames = List<String>.from(userData['vehicleNames']);
          print('Vehicles saved from vehicleNames list: $vehicleNames');
        } else if (user.vehicleIds != null && user.vehicleIds!.isNotEmpty) {
          print('Found vehicleIds: ${user.vehicleIds} - Trying to fetch vehicle details');
          
          // fetchs each vehicle name from its ID
          for (String vehicleId in user.vehicleIds!) {
            try {
              final vehicleResponse = await http.get(
                Uri.parse('${auth_api.vehiclesEndpoint}/$vehicleId'),
                headers: {'Content-Type': 'application/json'},
              );
              
              if (vehicleResponse.statusCode == 200) {
                final vehicleData = json.decode(vehicleResponse.body);
                if (vehicleData != null && vehicleData.containsKey('name')) {
                  vehicleNames.add(vehicleData['name']);
                  print('Vehicle name fetched and saved: ${vehicleData['name']}');
                }
              }
            } catch (e) {
              print('Error fetching vehicle details: $e');
            }
          }
        } else if (userData.containsKey('vehicle') && userData['vehicle'] != null) {
          final vehicle = userData['vehicle'];
          if (vehicle is Map && vehicle.containsKey('name')) {
            vehicleNames.add(vehicle['name']);
          }
          print('Vehicle saved from single vehicle object: ${vehicle['name']}');
        } else if (userData.containsKey('vehicleName') && userData['vehicleName'] != null) {
          vehicleNames.add(userData['vehicleName'].toString());
          print('Vehicle saved from single vehicleName: ${userData['vehicleName']}');
        }
        
        // storing el  vehicle names
        await prefs.setStringList('user_vehicles', vehicleNames);
        
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logged in successfully')));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Homepage()),
        );
      } else {
        print('Invalid credentials');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Invalid credentials')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 255, 254),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Image.asset('assets/logo2.png', height: 100, width: 200),
                const SizedBox(height: 10),
                Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 100),
                Text(
                  'Log in to your account',
                  style: TextStyle(
                    color: Color.fromARGB(255, 61, 60, 60),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                MyTextfield(
                  controller: controllers['username']!,
                  hinText: 'username',
                  obscureText: false,
                  field: 'Username',
                ),
                const SizedBox(height: 10),
                MyTextfield(
                  controller: controllers['password']!,
                  hinText: 'password',
                  obscureText: true,
                  field: 'Password',
                ),
                const SizedBox(height: 10),
              
                
                const SizedBox(height: 20),
                isLoading
                    ? CircularProgressIndicator()
                    : MyBttn(
                      formKey: _formKey,
                      controllers: controllers,
                      buttonText: 'Log in',
                      onPressed: logUserIn,
                    ),
                const SizedBox(height: 200),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUp(),
                          ),
                        );
                      },
                      child: Text(
                        '  Create an Account',
                        style: TextStyle(
                          color: Color.fromRGBO(76, 184, 196, 1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}