// lib/sign_up.dart
import 'package:authentication/components/my_bttn.dart';
import 'package:flutter/material.dart';
import 'package:authentication/components/my_txtfield.dart';
import 'package:authentication/login.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:authentication/utils/registration_api.dart' as auth_api;
import 'package:authentication/models/vehicle.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isLoadingVehicles = true;
  List<Vehicle> vehicles = [];
  List<Vehicle> filteredVehicles = [];
  Set<int> selectedVehicleIds = {};
  final TextEditingController _searchController =
      TextEditingController(); // For search

  final Map<String, TextEditingController> controllers = {
    'name': TextEditingController(),
    'username': TextEditingController(),
    'email': TextEditingController(),
    'password': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    fetchVehicles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterVehicles() {
    final String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredVehicles = vehicles;
      } else {
        filteredVehicles =
            vehicles
                .where((vehicle) => vehicle.name.toLowerCase().contains(query))
                .toList();
      }
    });
  }

  void _showMultiSelectDialog(BuildContext context) {
    _searchController.clear();
    List<Vehicle> dialogFilteredVehicles = List.from(vehicles);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text('Select Vehicles'),
              contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 0),
              content: Container(
                width: double.maxFinite,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search vehicles',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      style: TextStyle(fontSize: 14),
                      onChanged: (value) {
                        final String query = value.toLowerCase();
                        setStateDialog(() {
                          if (query.isEmpty) {
                            dialogFilteredVehicles = vehicles;
                          } else {
                            dialogFilteredVehicles =
                                vehicles
                                    .where(
                                      (vehicle) => vehicle.name
                                          .toLowerCase()
                                          .contains(query),
                                    )
                                    .toList();
                          }
                        });
                      },
                    ),
                    SizedBox(height: 8),

                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: dialogFilteredVehicles.length,
                        itemBuilder: (context, index) {
                          final vehicle = dialogFilteredVehicles[index];
                          final isSelected = selectedVehicleIds.contains(
                            vehicle.id,
                          );

                          return CheckboxListTile(
                            title: Text(
                              vehicle.name,
                              style: TextStyle(fontSize: 14),
                            ),
                            subtitle: Text(
                              'ID: ${vehicle.id}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            value: isSelected,
                            activeColor: Color(0xFF4CB8C4),
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                            onChanged: (bool? value) {
                              setStateDialog(() {
                                if (value == true) {
                                  selectedVehicleIds.add(vehicle.id);
                                } else {
                                  selectedVehicleIds.remove(vehicle.id);
                                }
                              });

                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: Color(0xFF4CB8C4),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _searchController.clear();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> fetchVehicles() async {
    setState(() {
      isLoadingVehicles = true;
    });

    try {
      print('Fetching vehicles from: ${auth_api.vehiclesEndpoint}');
      final response = await http
          .get(
            Uri.parse(auth_api.vehiclesEndpoint),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 15));

      setState(() {
        isLoadingVehicles = false;
      });

      print('Vehicle response status: ${response.statusCode}');
      print('Vehicle response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> vehiclesJson = json.decode(response.body);
        setState(() {
          vehicles =
              vehiclesJson.map((json) => Vehicle.fromJson(json)).toList();
          filteredVehicles = vehicles;
        });

        for (var vehicle in vehicles) {
          print('Available vehicle: ID ${vehicle.id} - ${vehicle.name}');
        }
      } else {
        print('Failed to load vehicles: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load vehicles from server (${response.statusCode})',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoadingVehicles = false;
      });

      String errorMessage = 'Connection error';

      if (e is TimeoutException) {
        errorMessage =
            'Connection timed out. Please check your network or server status.';
      }

      print('Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_sharp),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
            );
          },
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 252, 255, 254),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                Image.asset('assets/logo2.png', height: 70, width: 70),
                const SizedBox(height: 25),
                Text(
                  'Create an Account',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      MyTextfield(
                        controller: controllers['name']!,
                        hinText: 'name',
                        obscureText: false,
                        field: 'name',
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
                        controller: controllers['email']!,
                        hinText: 'email',
                        obscureText: false,
                        field: 'Email',
                      ),
                      const SizedBox(height: 10),
                      MyTextfield(
                        controller: controllers['password']!,
                        hinText: 'password',
                        obscureText: true,
                        field: 'Password',
                      ),
                      const SizedBox(height: 20),

                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 25),
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Your Vehicles',
                              style: TextStyle(
                                color: Color.fromARGB(255, 61, 60, 60),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            isLoadingVehicles
                                ? Center(child: CircularProgressIndicator())
                                : vehicles.isEmpty
                                ? Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'No vehicles available',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.refresh),
                                        onPressed: fetchVehicles,
                                        tooltip: 'Retry loading vehicles',
                                      ),
                                    ],
                                  ),
                                )
                                : GestureDetector(
                                  onTap: () {
                                    _showMultiSelectDialog(context);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 15,
                                    ),
                                    width: double.infinity,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            selectedVehicleIds.isEmpty
                                                ? 'Select vehicles'
                                                : '${selectedVehicleIds.length} vehicle${selectedVehicleIds.length > 1 ? 's' : ''} selected',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  selectedVehicleIds.isEmpty
                                                      ? Colors.grey.shade600
                                                      : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          color: Colors.grey.shade700,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),

                      if (selectedVehicleIds.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 10,
                          ),
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected Vehicles:',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 61, 60, 60),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Wrap(
                                spacing: 5,
                                children:
                                    selectedVehicleIds.map((id) {
                                      final vehicle = vehicles.firstWhere(
                                        (v) => v.id == id,
                                        orElse:
                                            () => Vehicle(
                                              id: id,
                                              name: 'Unknown',
                                            ),
                                      );
                                      return Chip(
                                        label: Text(
                                          '${vehicle.name} (ID: ${vehicle.id})',
                                        ),
                                        backgroundColor: Color(
                                          0xFF4CB8C4,
                                        ).withOpacity(0.2),
                                        deleteIconColor: Color(0xFF4CB8C4),
                                        onDeleted: () {
                                          setState(() {
                                            selectedVehicleIds.remove(id);
                                          });
                                        },
                                      );
                                    }).toList(),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 25),

                      isLoading
                          ? CircularProgressIndicator()
                          : MyBttn(
                            formKey: _formKey,
                            controllers: controllers,
                            buttonText: 'Sign up',
                            onPressed: signUp,
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void signUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (vehicles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No vehicles available. Please check your connection to the server.',
            ),
          ),
        );
        return;
      }

      if (selectedVehicleIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select at least one vehicle')),
        );
        return;
      }

      setState(() {
        isLoading = true;
      });

      try {
        final selectedVehicleNames =
            selectedVehicleIds.map((id) {
              final vehicle = vehicles.firstWhere(
                (v) => v.id == id,
                orElse: () => Vehicle(id: id, name: 'Unknown Vehicle'),
              );
              return vehicle.name;
            }).toList();

        final vehicleIdsAsStrings =
            selectedVehicleIds.map((id) => id.toString()).toList();

        print('Selected vehicle IDs: ${selectedVehicleIds.join(", ")}');
        print('Selected vehicle names: ${selectedVehicleNames.join(", ")}');

        final response = await http
            .post(
              Uri.parse(auth_api.registerEndpoint),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'name': controllers['name']!.text,
                'username': controllers['username']!.text,
                'email': controllers['email']!.text,
                'password': controllers['password']!.text,
                'vehicleId': vehicleIdsAsStrings.first,
                'vehicleIds': vehicleIdsAsStrings,
              }),
            )
            .timeout(Duration(seconds: 15));

        setState(() {
          isLoading = false;
        });

        print('Registration response status: ${response.statusCode}');
        print('Registration response body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('Successfully Signed Up!');

          // storing el vehicle info in sharedpref to use immediately after login
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList('user_vehicles', selectedVehicleNames);

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Sign up successful!')));

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Login()),
          );
        } else {
          String errorMessage = 'Sign up failed';
          try {
            final errorResponse = json.decode(response.body);
            if (errorResponse.containsKey('message')) {
              errorMessage = errorResponse['message'];
            }
          } catch (_) {}

          print('Sign up failed: $errorMessage');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });

        String errorMessage = 'Connection error: ${e.toString()}';

        print('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: Duration(seconds: 10),
          ),
        );
      }
    }
  }
}
