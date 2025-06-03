import 'dart:convert';
import 'package:authentication/models/vehicle.dart';
import 'package:authentication/utils/registration_api.dart' as auth_api;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MyCar extends StatefulWidget {
  const MyCar({super.key, String? vehicleId});

  @override
  State<MyCar> createState() => _MyCarState();
}

class _MyCarState extends State<MyCar> {
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  List<String> userVehicleNames = [];
  String? selectedVehicleName;
  Vehicle? selectedVehicle;

  final primaryColor = const Color(0xFF4CB8C4);
  final secondaryColor = const Color(0xFF3B3F3E);
  final backgroundColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadUserVehicles();
  }

  Future<void> _loadUserVehicles() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final vehicles = prefs.getStringList('user_vehicles') ?? [];

      print('Loaded vehicles from SharedPreferences: $vehicles');

      setState(() {
        userVehicleNames = vehicles;

        if (vehicles.isNotEmpty) {
          selectedVehicleName = vehicles.first;
          _fetchVehicleDetails(selectedVehicleName!);
        } else {
          isLoading = false;
          hasError = true;
          errorMessage =
              'No vehicles found. Please add a vehicle to your profile.';
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'Unable to load your vehicles. Please try again later.';
      });
      print('Error loading vehicles: $e');
    }
  }

  Future<void> _fetchVehicleDetails(String vehicleName) async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response = await http.get(
        Uri.parse(auth_api.vehiclesEndpoint),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> vehiclesJson = json.decode(response.body);
        final vehicles =
            vehiclesJson.map((json) => Vehicle.fromJson(json)).toList();

        final matchingVehicle = vehicles.firstWhere(
          (vehicle) => vehicle.name == vehicleName,
          orElse: () => Vehicle(id: -1, name: 'Vehicle not found'),
        );

        setState(() {
          selectedVehicle = matchingVehicle;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage =
              'Unable to load vehicle details. Please try again later.';
        });
        print('Failed to load vehicle details: ${response.body}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage =
            'Unable to connect to vehicle service. Please try again later.';
      });
      print('Error fetching vehicle details: $e');
    }
  }

  Widget _buildSpecCard(String title, String? value, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: primaryColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: secondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value ?? 'N/A',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, Map<String, dynamic> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: secondaryColor,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4, 
          color: Colors.white, 
          shadowColor: Colors.grey.withOpacity(0.5), 
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children:
                  details.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            entry.value ?? 'N/A',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.white,
          shadowColor: Colors.transparent,
        ),
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Select Vehicle',
            labelStyle: TextStyle(color: primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          value: selectedVehicleName,
          icon: Icon(Icons.arrow_drop_down, color: primaryColor),
          elevation: 16,
          style: TextStyle(color: secondaryColor, fontWeight: FontWeight.w500),
          dropdownColor: Colors.white, 
          onChanged: (String? newValue) {
            if (newValue != null && newValue != selectedVehicleName) {
              setState(() {
                selectedVehicleName = newValue;
              });
              _fetchVehicleDetails(newValue);
            }
          },
          items:
              userVehicleNames.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dialogBackgroundColor: Colors.white,
        popupMenuTheme: PopupMenuThemeData(color: Colors.white),
        canvasColor: Colors.white,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text('My Vehicle', style: TextStyle(color: secondaryColor)),
          backgroundColor: backgroundColor,
          elevation: 0,
        ),
        body:
            isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                )
                : hasError
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        errorMessage,
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadUserVehicles,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                        ),
                        child: Text('Reload'),
                      ),
                    ],
                  ),
                )
                : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (userVehicleNames.length > 1) ...[
                        _buildVehicleSelector(),
                        SizedBox(height: 16),
                      ],

                      Container(
                        height: 200,
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage('assets/car.png'),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),

                            Positioned(
                              bottom: 0,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  selectedVehicle?.name ?? 'Unknown Vehicle',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          children: [
                            _buildSpecCard(
                              'Battery',
                              selectedVehicle?.battery,
                              Icons.battery_charging_full,
                            ),
                            _buildSpecCard(
                              'Range',
                              selectedVehicle?.range,
                              Icons.speed,
                            ),
                            _buildSpecCard(
                              'DC Charging',
                              selectedVehicle?.dcChargeSpeed,
                              Icons.bolt,
                            ),
                            _buildSpecCard(
                              'AC Charging',
                              selectedVehicle?.acChargeSpeed ??
                                  selectedVehicle?.acChargingSpeed,
                              Icons.electric_car,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      _buildDetailSection('Charging Details', {
                        'DC Charging Speed':
                            selectedVehicle?.dcChargeSpeed ?? 'N/A',
                        'AC Charging Speed':
                            selectedVehicle?.acChargeSpeed ??
                            selectedVehicle?.acChargingSpeed ??
                            'N/A',
                        'DC Charging Time':
                            selectedVehicle?.dcChargingTime ?? 'N/A',
                        'AC Charging Time':
                            selectedVehicle?.acChargingTime ?? 'N/A',
                      }),

                      SizedBox(height: 32),
                    ],
                  ),
                ),
      ),
    );
  }
}
