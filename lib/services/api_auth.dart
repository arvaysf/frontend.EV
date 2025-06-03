// lib/services/api_service.dart

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:authentication/models/user.dart';
import 'package:authentication/models/vehicle.dart';
import 'package:authentication/utils/registration_api.dart' as auth_api;

class ApiService {
  static Future<Map<String, dynamic>> register(User user) async {
    try {
      print('Sending registration request to: ${auth_api.registerEndpoint}');
      print('With data: ${user.toJson()}');
      
      final response = await http.post(
        Uri.parse(auth_api.registerEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(user.toJson()),
      ).timeout(Duration(seconds: 15));

      print('Registration response status: ${response.statusCode}');
      print('Registration response body: ${response.body}');

      return json.decode(response.body);
    } catch (e) {
      print('Registration error: $e');
      return {
        'success': false,
        'message': e is TimeoutException 
            ? 'Connection timed out. Please check your network or server status.' 
            : 'Connection error: $e'
      };
    }
  }

  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(auth_api.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      ).timeout(Duration(seconds: 15));

      return json.decode(response.body);
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'message': e is TimeoutException 
            ? 'Connection timed out. Please check your network or server status.' 
            : 'Connection error: $e'
      };
    }
  }

  static Future<List<Vehicle>> getVehicles() async {
    try {
      print('Fetching vehicles from: ${auth_api.vehiclesEndpoint}');
      final response = await http.get(
        Uri.parse(auth_api.vehiclesEndpoint),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 15));

      print('Vehicle response status: ${response.statusCode}');
      print('Vehicle response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> vehiclesJson = json.decode(response.body);
        return vehiclesJson.map((json) => Vehicle.fromJson(json)).toList();
      } else {
        print('Failed to load vehicles: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching vehicles: $e');
      return [];
    }
  }
}