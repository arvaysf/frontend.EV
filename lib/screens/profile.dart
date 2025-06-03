// lib/screens/profile.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:authentication/login.dart';
import 'package:authentication/models/vehicle.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:authentication/utils/registration_api.dart' as auth_api;

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  // User information
  String name = '';
  String username = '';
  String email = '';
  List<String> vehicleNames = []; // Changed from single string to list
  bool isLoading = true;
  
  // For vehicle management
  List<Vehicle> allVehicles = [];
  Set<int> selectedVehicleIds = {};
  Map<String, int> vehicleNameToId = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load saved user data when the screen initializes
    loadUserData();
    // Fetch available vehicles for editing
    fetchVehicles();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh user data when the page is navigated to
    loadUserData();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fetch all available vehicles
  Future<void> fetchVehicles() async {
    try {
      final response = await http.get(
        Uri.parse(auth_api.vehiclesEndpoint),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> vehiclesJson = json.decode(response.body);
        setState(() {
          allVehicles = vehiclesJson.map((json) => Vehicle.fromJson(json)).toList();
          
          // Create a mapping from vehicle name to ID
          vehicleNameToId = {};
          for (var vehicle in allVehicles) {
            vehicleNameToId[vehicle.name] = vehicle.id;
          }
          
          // Map currently selected vehicle names to IDs
          selectedVehicleIds = vehicleNames
              .where((name) => vehicleNameToId.containsKey(name))
              .map((name) => vehicleNameToId[name]!)
              .toSet();
        });
      } else {
        print('Failed to load vehicles: ${response.body}');
      }
    } catch (e) {
      print('Error fetching vehicles: $e');
    }
  }

  // Load user data from SharedPreferences
  Future<void> loadUserData() async {
    setState(() {
      isLoading = true;
    });
    
    final prefs = await SharedPreferences.getInstance();
    
    // Debug output to check what's stored in SharedPreferences
    print('Loading user data from SharedPreferences:');
    print('Name: ${prefs.getString('user_name')}');
    print('Username: ${prefs.getString('user_username')}');
    print('Email: ${prefs.getString('user_email')}');
    print('Vehicles: ${prefs.getStringList('user_vehicles')}');
    
    setState(() {
      name = prefs.getString('user_name') ?? '';
      username = prefs.getString('user_username') ?? '';
      email = prefs.getString('user_email') ?? '';
      vehicleNames = prefs.getStringList('user_vehicles') ?? [];
      
      // For backward compatibility with old version
      if (vehicleNames.isEmpty) {
        final oldVehicle = prefs.getString('user_vehicle');
        if (oldVehicle != null && oldVehicle.isNotEmpty) {
          vehicleNames = [oldVehicle];
        }
      }
      
      isLoading = false;
    });
  }
  
  // Show vehicle selection dialog
  void _showVehicleSelectionDialog(BuildContext context) {
    // Reset search before showing dialog
    _searchController.clear();
    List<Vehicle> dialogFilteredVehicles = List.from(allVehicles);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text('Select Your Vehicles'),
              contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 0),
              content: Container(
                width: double.maxFinite,
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search field
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
                            dialogFilteredVehicles = allVehicles;
                          } else {
                            dialogFilteredVehicles = allVehicles
                                .where((vehicle) => vehicle.name.toLowerCase().contains(query))
                                .toList();
                          }
                        });
                      },
                    ),
                    SizedBox(height: 8),
                    
                    // Vehicle list with checkboxes
                    Expanded(
                      child: dialogFilteredVehicles.isEmpty 
                      ? Center(child: Text('No vehicles found'))
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: dialogFilteredVehicles.length,
                        itemBuilder: (context, index) {
                          final vehicle = dialogFilteredVehicles[index];
                          final isSelected = selectedVehicleIds.contains(vehicle.id);
                          
                          return CheckboxListTile(
                            title: Text(
                              vehicle.name,
                              style: TextStyle(fontSize: 14),
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
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: Color(0xFF4CB8C4),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () async {
                    // Update the vehicle names list based on selected IDs
                    final updatedVehicleNames = selectedVehicleIds.map((id) {
                      final vehicle = allVehicles.firstWhere(
                        (v) => v.id == id,
                        orElse: () => Vehicle(id: id, name: 'Unknown Vehicle'),
                      );
                      return vehicle.name;
                    }).toList();
                    
                    // Save to SharedPreferences
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setStringList('user_vehicles', updatedVehicleNames);
                    
                    // Update state
                    setState(() {
                      vehicleNames = updatedVehicleNames;
                    });
                    
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile picture or avatar
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Color(0xFF4CB8C4).withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        size: 80,
                        color: Color(0xFF4CB8C4),
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    // Name display
                    Text(
                      name.isNotEmpty ? name : 'No Name',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 5),
                    
                    // Username display
                    Text(
                      username.isNotEmpty ? '@$username' : 'No Username',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 30),
                    
                    // Info card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4CB8C4),
                            ),
                          ),
                          SizedBox(height: 15),
                          
                          // Email
                          Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: Row(
                              children: [
                                Icon(Icons.email, color: Colors.grey[600], size: 20),
                                SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Email',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      email.isNotEmpty ? email : 'No Email',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Vehicle with edit option
                          Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.directions_car, color: Colors.grey[600], size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            vehicleNames.length > 1 ? 'Vehicles' : 'Vehicle',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              if (allVehicles.isEmpty) {
                                                fetchVehicles().then((_) {
                                                  _showVehicleSelectionDialog(context);
                                                });
                                              } else {
                                                _showVehicleSelectionDialog(context);
                                              }
                                            },
                                            child: Text(
                                              'Edit',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF4CB8C4),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 2),
                                      vehicleNames.isEmpty
                                        ? Text(
                                            'No Vehicles Selected',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          )
                                        : Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: vehicleNames.map((vehicle) => 
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 5),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration: BoxDecoration(
                                                        color: Color(0xFF4CB8C4),
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        vehicle,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            ).toList(),
                                          ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Logout button
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () async {
                        // Clear user data
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        
                        // Navigate to login page
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => Login(),
                          ),
                          (route) => false, // Clear navigation stack
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4CB8C4),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}