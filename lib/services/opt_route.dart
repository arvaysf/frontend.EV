import 'dart:convert';
import 'package:http/http.dart' as http;

class RouteOptimization {
  final String origin;
  final String destination;
  final double initialCharge;

  static const String backendBaseUrl = 'http://172.20.10.5:8080';

  RouteOptimization({
    required this.origin,
    required this.destination,
    this.initialCharge = 100.0, 
  });


  Future<List<dynamic>> fetchOptimizedRoutes() async {
    final originEncoded = Uri.encodeComponent(origin);
    final destinationEncoded = Uri.encodeComponent(destination);

    final url = Uri.parse(
      '$backendBaseUrl/maps/optimized-routes?origin=$originEncoded&destination=$destinationEncoded&initialCharge=$initialCharge',
    );

    final response = await http.get(
      url,
      headers: {'Accept': 'application/json; charset=utf-8'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to fetch optimized routes: ${response.body}');
    }
  }

 Future<List<dynamic>> fetchStationsOnRoute(String encodedPolyline) async {
  final url = Uri.parse(
    '$backendBaseUrl/maps/stations-on-route?polyline=${Uri.encodeComponent(encodedPolyline)}',
  );

  final response = await http.get(
    url,
    headers: {'Accept': 'application/json; charset=utf-8'},
  );

  if (response.statusCode == 200) {
    // to get access to the 'stations' inside el response
    return jsonDecode(utf8.decode(response.bodyBytes))['stations'];
  } else {
    throw Exception('Failed to fetch stations on route: ${response.body}');
  }
}

}
