import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class DrivingModeScreen extends StatefulWidget {
  final String backendBaseUrl;

  const DrivingModeScreen({super.key, required this.backendBaseUrl});

  @override
  State<DrivingModeScreen> createState() => _DrivingModeScreenState();
}

List<dynamic> _steps = [];
final String _googleApiKey = "AIzaSyAv_HE9pisMU_I5WEWrOx4Pn56_sjrKw8E";

class _DrivingModeScreenState extends State<DrivingModeScreen> {
  late GoogleMapController _mapController;
  Map<String, dynamic>? _vehicle;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  List<dynamic> _chargingStops = [];
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    fetchNavigationData();
  }

  Future<void> fetchNavigationData() async {
    print(
      "📡 İstek gönderiliyor: /maps/selected-navigation ve /maps/charging-stops",
    );

    try {
      final navResponse = await http.get(
        Uri.parse('${widget.backendBaseUrl}/maps/selected-navigation'),
      );
      final stopsResponse = await http.get(
        Uri.parse('${widget.backendBaseUrl}/maps/charging-stops'),
      );
      print(
        "🔄 Nav Status: ${navResponse.statusCode}, Stops Status: ${stopsResponse.statusCode}",
      );
      final navData = jsonDecode(navResponse.body);
      final vehicle = navData['vehicle'];
      final stopsData = jsonDecode(stopsResponse.body);
      if (vehicle != null) {
        print("🚗 Araç Modeli: ${vehicle['model']}");
        print(
          "🔋 Batarya: ${vehicle['batteryCapacity']} kWh, SOC: ${vehicle['socPercentage']}%",
        );
      }
      print("📦 Rota verisi: ${navData['route']?.length}");
      print("🔋 Şarj durakları: ${stopsData.length}");

      if (navResponse.statusCode != 200 || stopsResponse.statusCode != 200) {
        setState(() {});
        return;
      }

      final List<dynamic> routePoints = navData['route'] ?? [];
      _chargingStops = stopsData;

      final polylinePoints =
          routePoints.map<LatLng>((p) => LatLng(p['lat'], p['lng'])).toList();
      final polyline = Polyline(
        polylineId: const PolylineId('selected_route'),
        color: const Color(0xFF34A853),
        width: 6,
        points: polylinePoints,
      );

      final stopMarkers =
          _chargingStops.map<Marker>((stop) {
            final station = stop['station'];
            return Marker(
              markerId: MarkerId(
                "charging_${station['lat']}_${station['lng']}",
              ),
              position: LatLng(station['lat'], station['lng']),
              infoWindow: InfoWindow(
                title: station['name'],
                snippet:
                    '📍 ${(stop['distanceFromStart'] / 1000).toStringAsFixed(2)} km, 🔋 ${stop['currentSoc'].toStringAsFixed(1)}% → ${stop['targetSoc'].toStringAsFixed(1)}%',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            );
          }).toSet();

      setState(() {
        _vehicle = vehicle;
        _polylines = {polyline};
        _markers = stopMarkers;
        _dataLoaded = true;
      });

      await Future.delayed(const Duration(milliseconds: 300));
      if (polylinePoints.isNotEmpty) {
        final bounds = _createBounds(polylinePoints);
        _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
      }

      await fetchDirectionsAndSteps();
    } catch (e) {
      setState(() {});
    }
  }

  Future<void> fetchDirectionsAndSteps() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final origin = "${position.latitude},${position.longitude}";

      final navRes = await http.get(
        Uri.parse('${widget.backendBaseUrl}/maps/selected-navigation'),
      );
      final navData = jsonDecode(navRes.body);
      final last = navData['route'].last;
      final destination = "${last['lat']},${last['lng']}";

      final url =
          "https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$_googleApiKey";
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (data['routes'].isEmpty) return;
      final steps = data['routes'][0]['legs'][0]['steps'] as List<dynamic>;

      setState(() {
        _steps = steps;
      });
    } catch (e) {
      print("❌ Hata: $e");
    }
  }

  LatLngBounds _createBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Widget buildChargingStopCard(dynamic stop) {
    Map<String, dynamic> station = stop['station'];
    Map<String, dynamic>? prev = stop['previousStation'];
    Map<String, dynamic>? next = stop['nextStation'];

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8), // Reduced margins
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(6), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔋 ${station['name'] ?? 'Unknown'}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), // Smaller text
            ),
            Text(
              '⚡ Energy to charge: ${stop['energyToCharge'].toStringAsFixed(2)} kWh',
              style: TextStyle(fontSize: 11), // Smaller text
            ),
            Text(
              '🚗 SOC: ${stop['currentSoc'].toStringAsFixed(1)}% → ${stop['targetSoc'].toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 11), // Smaller text
            ),
            Text(
              '📏 Distance from start: ${(stop['distanceFromStart'] / 1000).toStringAsFixed(2)} km',
              style: TextStyle(fontSize: 11), // Smaller text
            ),

            if (prev != null) ...[
              Divider(height: 8), // Smaller divider
              Text('⬅️ Previous Station: ${prev['name'] ?? 'Unknown'}', 
                style: TextStyle(fontSize: 11)), // Smaller text
              Text(
                '  📏 Distance from start : ${(stop['previousStationDistance'] ?? 0).toStringAsFixed(2)} km',
                style: TextStyle(fontSize: 10), // Smaller text
              ),
              Text(
                '  ⚡ Energy Needed: ${(stop['previousStationEnergyNeeded'] ?? 0).toStringAsFixed(2)} kWh',
                style: TextStyle(fontSize: 10), // Smaller text
              ),
              Text(
                '  🚗 SOC at Arrival: ${(stop['previousStationSocAtArrival'] ?? 0).toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 10), // Smaller text
              ),
            ],

            if (next != null) ...[
              Divider(height: 8), // Smaller divider
              Text('➡️ Next Station: ${next['name'] ?? 'Unknown'}',
                style: TextStyle(fontSize: 11)), // Smaller text
              Text(
                '  📏 Distance from suggested station: ${(stop['nextStationDistance'] ?? 0).toStringAsFixed(2)} km',
                style: TextStyle(fontSize: 10), // Smaller text
              ),
              Text(
                '  ⚡ Energy Needed: ${(stop['nextStationEnergyNeeded'] ?? 0).toStringAsFixed(2)} kWh',
                style: TextStyle(fontSize: 10), // Smaller text
              ),
              Text(
                '  🚗 SOC at Arrival: ${(stop['nextStationSocAtArrival'] ?? 0).toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 10), // Smaller text
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Navigation"),
        backgroundColor: Color(
          0xFF4CB8C4,
        ), 
        elevation: 4, 
      ),

      backgroundColor: Colors.white,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FloatingActionButton.small(
            onPressed:
                () => _mapController.animateCamera(CameraUpdate.zoomIn()),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            child: const Icon(Icons.add),
            heroTag: "zoom_in",
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            onPressed:
                () => _mapController.animateCamera(CameraUpdate.zoomOut()),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            child: const Icon(Icons.remove),
            heroTag: "zoom_out",
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1, 
            child: Column(
              children: [
                if (_vehicle != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 6.0), // Reduced padding
                    child: Card(
                      color: Colors.white,
                      elevation: 2,
                      margin: EdgeInsets.all(2), // Reduced margin
                      child: ListTile(
                        dense: true, // Makes the ListTile more compact
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 2), // Reduced padding
                        leading: const Icon(Icons.electric_car, size: 18), // Smaller icon
                        title: Text(
                          "Araç: ${_vehicle!['model']}", 
                          style: TextStyle(fontSize: 12), // Smaller text
                        ),
                        subtitle: Text(
                          "🔋 ${_vehicle!['socPercentage']}% SOC\n🔧 consumption: ${_vehicle!['consumptionPerKm']} kWh/km",
                          style: TextStyle(fontSize: 11), // Smaller text
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child:
                      _chargingStops.isEmpty
                          ? Center(
                              child: Text(
                                "✅ Can reach destination with current charge! ",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12), // Smaller text
                              ),
                            )
                          : ListView.builder(
                            padding: EdgeInsets.symmetric(vertical: 1), // Reduced padding
                            itemCount: _chargingStops.length,
                            itemBuilder: (context, index) {
                              return buildChargingStopCard(
                                _chargingStops[index],
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 5, 
            child:
                _dataLoaded
                    ? GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(41.0151, 28.9795),
                        zoom: 12,
                      ),
                      polylines: _polylines,
                      markers: _markers,
                      onMapCreated: (controller) => _mapController = controller,
                      zoomControlsEnabled: false,
                    )
                    : const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}