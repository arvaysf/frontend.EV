// lib/services/api_service.dart
import 'dart:convert';
import 'package:authentication/models/energy/charging_stations.dart';
import 'package:authentication/utils/home_api_constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(Uri.parse(testEndpoint));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint('Connection test error: $e');
      return false;
    }
  }

  
  static Future<Map<String, List<String>>> getAvailableOptions() async {
    try {
      
      try {
        final optionsResponse = await http.get(
          Uri.parse('$backendBaseUrl/$apiPath/options'),
        );
        
        if (optionsResponse.statusCode == 200) {
          final data = jsonDecode(optionsResponse.body);
          if (data['status'] == 'success') {
            debugPrint('Loaded options from dedicated endpoint');
            return {
              'powerOptions': (data['powerOptions'] as List).cast<String>(),
              'connectionTypes': (data['connectionTypes'] as List).cast<String>(),
            };
          }
        }
      } catch (e) {
        debugPrint('No dedicated options endpoint, trying alternatives');
      }

      final response = await http.get(
        Uri.parse('$backendBaseUrl/$apiPath/all'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['stations'] != null) {
          debugPrint('Extracting options from all stations');
          
          Set<String> powerOptions = {};
          Set<String> connectionTypes = {};

          for (var station in data['stations']) {
            if (station['sarjGucu'] != null &&
                station['sarjGucu'].toString().isNotEmpty) {
              powerOptions.add(station['sarjGucu'].toString());
            }
            if (station['baglantiTipi'] != null &&
                station['baglantiTipi'].toString().isNotEmpty) {
              connectionTypes.add(station['baglantiTipi'].toString());
            }
          }

          debugPrint('Found ${powerOptions.length} power options and ${connectionTypes.length} connection types');
          return {
            'powerOptions': powerOptions.toList()..sort(),
            'connectionTypes': connectionTypes.toList()..sort(),
          };
        }
      }

      debugPrint('Trying to get options from match endpoint with no filters');
      final matchResponse = await http.get(
        Uri.parse('$matchEndpoint?minPrice=0&maxPrice=100000'),
      );
      
      if (matchResponse.statusCode == 200) {
        final data = jsonDecode(matchResponse.body);
        debugPrint('Match endpoint response: ${matchResponse.body.substring(0, min(200, matchResponse.body.length))}...');
        
        if (data['status'] == 'success' && data['matchingStations'] != null) {
          debugPrint('Found ${data['matchingStations'].length} matching stations');
          Set<String> powerOptions = {};
          Set<String> connectionTypes = {};

          for (var station in data['matchingStations']) {
            if (station['sarjGucu'] != null &&
                station['sarjGucu'].toString().isNotEmpty) {
              powerOptions.add(station['sarjGucu'].toString());
            }
            if (station['baglantiTipi'] != null &&
                station['baglantiTipi'].toString().isNotEmpty) {
              connectionTypes.add(station['baglantiTipi'].toString());
            }
          }

          debugPrint('Extracted options: Power: $powerOptions, Connections: $connectionTypes');
          return {
            'powerOptions': powerOptions.toList()..sort(),
            'connectionTypes': connectionTypes.toList()..sort(),
          };
        }
      }

      debugPrint('Using fallback options');
      // Fallback options if we can't get real ones from el backend
      return {
        'powerOptions': ['11 kW', '22 kW', '50 kW', '150 kW'],
        'connectionTypes': [
          'Type 1',
          'Type 2',
          'CCS',
          'CHAdeMO',
          'Sabit Kablolu',
        ],
      };
    } catch (e) {
      debugPrint('Error getting options: $e');
      //  fallback options
      return {
        'powerOptions': ['11 kW', '22 kW', '50 kW', '150 kW'],
        'connectionTypes': [
          'Type 1',
          'Type 2',
          'CCS',
          
          'Sabit Kablolu',
        ],
      };
    }
  }

  
static Future<List<ChargingStation>> getMatchingStations({
  String? sarjGucu,
  String? baglantiTipi,
  int minPrice = 0,
  int maxPrice = 100000,
  String? marka,
}) async {
  try {
    debugPrint('Fetching stations with filters: Power=$sarjGucu, Connection=$baglantiTipi, Price=$minPrice-$maxPrice');
    
    final queryParams = {
      if (sarjGucu != null && sarjGucu.isNotEmpty) 'sarj_gucu': sarjGucu,
      if (baglantiTipi != null && baglantiTipi.isNotEmpty)
        'baglanti_tipi': baglantiTipi, // This parameter name must match what the backend expects
      'minPrice': minPrice.toString(),
      'maxPrice': maxPrice.toString(),
      if (marka != null && marka.isNotEmpty) 'marka': marka,
    };

    final uri = Uri.parse(matchEndpoint).replace(queryParameters: queryParams);

    debugPrint('Request URL: ${uri.toString()}');
    
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('Response status: ${data['status']}, found: ${data['matchingStations']?.length ?? 0} stations');
      
      if (data['status'] == 'success' && data['matchingStations'] != null) {
        return (data['matchingStations'] as List).map((item) {
          return ChargingStation.fromJson(item);
        }).toList();
      } else {
        throw Exception(data['message'] ?? 'No matching stations found');
      }
    } else {
      debugPrint('HTTP error: ${response.statusCode} - ${response.body}');
      throw Exception(
        'Failed to load stations. Status: ${response.statusCode}',
      );
    }
  } catch (e) {
    debugPrint('Error fetching stations: $e');
    throw Exception('Failed to load stations: $e');
  }
}

  static Future<List<String>> getAllVehicles() async {
    try {
      final response = await http.get(Uri.parse(vehiclesEndpoint));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['vehicles'] != null) {
          return (data['vehicles'] as List).cast<String>();
        } else {
          throw Exception(data['message'] ?? 'Failed to load vehicles');
        }
      } else {
        throw Exception(
          'Failed to load vehicles. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching vehicles: $e');
      return [];
    }
  }
  
  static int min(int a, int b) {
    return a < b ? a : b;
  }
}