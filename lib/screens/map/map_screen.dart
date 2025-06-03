import 'package:authentication/screens/map/driving_mode_screen.dart';
import 'package:authentication/services/opt_route.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:authentication/components/map_helper.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Global variables
Set<Marker> stationMarkers = {};
Map<String, List<Marker>> markersByRouteColor = {};
Map<String, List<Widget>> stationCardsByRouteColor = {};
Set<Marker> visibleMarkers = {};
List<Widget> visibleCards = [];
String? activeRouteColor;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController originController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final TextEditingController initialChargeController = TextEditingController();
  @override
  bool get wantKeepAlive => true;

  final String backendBaseUrl = 'http://172.20.10.5:8080';

  Set<Polyline> polylines = {};
  late GoogleMapController mapController;

  final List<Color> routeColors = [
    const Color(0xFF4285F4), // Blue
    const Color(0xFFEA4335), // Red
    const Color(0xFF34A853), // Green
  ];

  String statusMessage = "Lütfen rota bilgilerini giriniz.";
  bool isLoading = false;

  void fetchAndDrawRoutes() async {
    String origin = originController.text.trim();
    String destination = destinationController.text.trim();
    final double initialCharge =
        double.tryParse(initialChargeController.text) ?? 100.0;

    if (origin.isEmpty || destination.isEmpty) {
      setState(() {
        statusMessage = "⚠️ Origin ve Destination alanlarını doldurun.";
      });
      return;
    }
    // Kullanıcıdan batarya durumu al

    if (initialCharge == 0) {
      setState(() {
        statusMessage = "❌ Şarj durumu girilmedi, rota getirilemedi.";
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      RouteOptimization service = RouteOptimization(
        origin: origin,
        destination: destination,
        initialCharge: initialCharge,
      );
      List<dynamic> routes = await service.fetchOptimizedRoutes();

      int colorIndex = 0;
      Set<Polyline> newPolylines = {};

      polylines.clear();
      markersByRouteColor.clear();
      stationCardsByRouteColor.clear();
      visibleMarkers.clear();
      visibleCards.clear();
      activeRouteColor = null;

      for (var route in routes) {
        String encodedPolyline = route['overview_polyline']['points'];
        String color = routeColors[colorIndex % routeColors.length].toString();

        PolylinePoints polylinePoints = PolylinePoints();
        List<PointLatLng> decodedPoints = polylinePoints.decodePolyline(
          encodedPolyline,
        );
        List<LatLng> latLngPoints =
            decodedPoints.map((p) => LatLng(p.latitude, p.longitude)).toList();

        // Initialize arrays for this route color
        markersByRouteColor[color] = [];
        stationCardsByRouteColor[color] = [];

        // Create polyline with onTap handler
        newPolylines.add(
          Polyline(
            polylineId: PolylineId("route_$colorIndex"),
            points: latLngPoints,
            color: routeColors[colorIndex % routeColors.length],
            width: 5,
            consumeTapEvents: true,
            onTap: () async {
              // Make this polyline wider
              _selectRoute(color, encodedPolyline);
            },
          ),
        );

        colorIndex++;
      }

      setState(() {
        polylines = newPolylines;
        statusMessage =
            "✅ ${routes.length} rota çizildi. Şarj istasyonlarını görmek için bir rotaya tıklayın.";
        isLoading = false; // End loading
      });

      // Zoom to fit all routes
      if (polylines.isNotEmpty) {
        MapHelper.zoomToFitAll(
          mapController: mapController,
          markers: Set<Marker>(),
          polylines: polylines,
        );
      }
    } catch (e) {
      setState(() {
        statusMessage = "❌ Rota alınamadı: $e";
        isLoading = false; // End loading on error
      });
    }
  }

  // Handle selecting a route
  void _selectRoute(String colorKey, String encodedPolyline) async {
    setState(() {
      statusMessage = "Şarj istasyonları getiriliyor...";
      isLoading = true; // Start loading
    });

    try {
      // Only fetch stations if we haven't already
      if (markersByRouteColor[colorKey]!.isEmpty) {
        // 🔌 Fetch stations for this route
        final stations = await RouteOptimization(
          origin: '',
          destination: '',
        ).fetchStationsOnRoute(encodedPolyline);

        List<Marker> routeMarkers = [];
        List<Widget> routeCards = [];

        for (var st in stations) {
          final lat = st['geometry']['location']['lat'];
          final lng = st['geometry']['location']['lng'];
          final name = st['name'] ?? 'Unnamed';
          final connector = st['connectorType'] ?? 'Unknown';
          final power = st['outputPowerKW']?.toString() ?? 'Belirsiz';
          final vicinity = st['vicinity'] ?? '-';

          final costumIcon = await getChargingStationIcon(name);
          // Marker
          routeMarkers.add(
            Marker(
              markerId: MarkerId("station_${lat}_$lng"),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(title: name),
              icon: costumIcon,
            ),
          );

          // Card
          routeCards.add(
            Card(
              margin: const EdgeInsets.symmetric(
                vertical: 6.0,
                horizontal: 12.0,
              ),
              child: ListTile(
                title: Text(
                  "⚡ $name",
                  style: TextStyle(color: Color(0xFF4285F4)),
                ),
                subtitle: Text("📍 $vicinity\n🔌 $connector - $power kW"),
                onTap: () {
                  mapController.animateCamera(
                    CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15),
                  );
                },
              ),
            ),
          );
        }

        markersByRouteColor[colorKey] = routeMarkers;
        stationCardsByRouteColor[colorKey] = routeCards;
      }

      // Update polylines to highlight selected route
      Set<Polyline> highlightedPolylines = {};
      for (var pl in polylines) {
        Color plColor = pl.color;
        String plColorKey = plColor.toString();

        if (plColorKey == colorKey) {
          // Make this polyline wider
          highlightedPolylines.add(
            Polyline(
              polylineId: pl.polylineId,
              points: pl.points,
              color: pl.color,
              width: 8, // Wider for selected route
              consumeTapEvents: true,
              onTap: pl.onTap,
            ),
          );
        } else {
          // Keep other polylines the same
          highlightedPolylines.add(pl);
        }
      }

      // Show this route's stations
      setState(() {
        activeRouteColor = colorKey;
        visibleMarkers = Set.of(markersByRouteColor[colorKey]!);
        visibleCards = stationCardsByRouteColor[colorKey]!;
        polylines = highlightedPolylines;
        statusMessage =
            "✅ ${visibleMarkers.length} şarj istasyonu gösteriliyor.";
        isLoading = false; // End loading
      });

      // Zoom to fit route and stations
      MapHelper.zoomToFitAll(
        mapController: mapController,
        markers: visibleMarkers,
        polylines: polylines,
      );
    } catch (e) {
      setState(() {
        statusMessage = "❌ Şarj istasyonları alınamadı: $e";
        isLoading = false; // End loading on error
      });
    }
  }

  // Reset to showing all routes
  void _resetToAllRoutes() {
    setState(() {
      // Clear stations
      visibleMarkers.clear();
      visibleCards.clear();
      activeRouteColor = null;

      // Reset polyline widths
      Set<Polyline> resetPolylines = {};
      for (var pl in polylines) {
        resetPolylines.add(
          Polyline(
            polylineId: pl.polylineId,
            points: pl.points,
            color: pl.color,
            width: 5, // Reset to standard width
            consumeTapEvents: true,
            onTap: pl.onTap,
          ),
        );
      }

      polylines = resetPolylines;
      statusMessage = "Şarj istasyonlarını görmek için bir rotaya tıklayın.";
    });

    // Zoom to fit all routes
    if (polylines.isNotEmpty) {
      MapHelper.zoomToFitAll(
        mapController: mapController,
        markers: Set<Marker>(),
        polylines: polylines,
      );
    }
  }

  Future<BitmapDescriptor> getChargingStationIcon(String name) async {
    // Use standard markers instead of custom icons as a quick fix
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  }

  Future<void> sendNavigationToBackend({
    required String backendBaseUrl,
    required List<dynamic> selectedRoute,
    required List<dynamic> selectedStations,
  }) async {
    final payload = {"route": selectedRoute, "stations": selectedStations};

    final res = await http.post(
      Uri.parse('$backendBaseUrl/maps/selected-navigation'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    print("📤 Seçim gönderildi → Status: ${res.statusCode}");
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      // Changed to centerFloat for the Drive button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: AppBar(
        backgroundColor: Color(0xFF4CB8C4),
        elevation: 0,
        // Place search fields directly in the AppBar
        title: Row(
          children: [
            // Origin input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30.0),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),

                child: TextField(
                  controller: originController,
                  decoration: const InputDecoration(
                    hintText: "Origin",
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Destination input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30.0),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: TextField(
                  controller: destinationController,
                  decoration: const InputDecoration(
                    hintText: "Destination",
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Initial SOC input - Sabit genişlik (örneğin 80 px)
            Container(
              width: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30.0),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              child: TextField(
                controller: initialChargeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "SOC %",
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            const SizedBox(width: 8),
            // Search button
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: IconButton(
                icon:
                    isLoading
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF4CB8C4), // Changed to blue
                          ),
                        )
                        : const Icon(
                          Icons.search,
                          color: Color(0xFF4CB8C4), // Changed to blue
                        ),
                onPressed: isLoading ? null : fetchAndDrawRoutes,
              ),
            ),
          ],
        ),
        titleSpacing: 16.0,
        actions: [
          
          if (polylines.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.zoom_out_map),
              onPressed:
                  () => MapHelper.zoomToFitAll(
                    mapController: mapController,
                    markers: visibleMarkers,
                    polylines: polylines,
                  ),
              tooltip: "Tüm rotayı göster",
            ),
          if (activeRouteColor != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _resetToAllRoutes,
              tooltip: "Tüm rotaları göster",
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (statusMessage.isNotEmpty &&
                  statusMessage != "Lütfen rota bilgilerini giriniz.")
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 16.0,
                  ),
                  color: Colors.grey.shade100,
                  child: Text(
                    statusMessage,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          statusMessage.contains("❌")
                              ? Colors.red
                              : statusMessage.contains("⚠️")
                              ? Colors.orange
                              : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(41.0151, 28.9795),
                        zoom: 12,
                      ),
                      polylines: polylines,
                      markers: visibleMarkers,
                      onMapCreated: (controller) => mapController = controller,
                      zoomControlsEnabled: false, // Hide default zoom controls
                      mapToolbarEnabled: false, // Hide Google directions button
                      myLocationButtonEnabled: false, // Hide my location button
                    ),

                    // Positioned zoom controls - moved to right side
                    Positioned(
                      right: 16,
                      bottom: visibleCards.isNotEmpty ? 170 : 100,
                      child: Column(
                        children: [
                          FloatingActionButton.small(
                            onPressed: () {
                              mapController.animateCamera(
                                CameraUpdate.zoomIn(),
                              );
                            },
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            child: const Icon(Icons.add),
                            heroTag: "zoom_in",
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton.small(
                            onPressed: () {
                              mapController.animateCamera(
                                CameraUpdate.zoomOut(),
                              );
                            },
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            child: const Icon(Icons.remove),
                            heroTag: "zoom_out",
                          ),
                        ],
                      ),
                    ),

                    // Station list widget
                    if (visibleCards.isNotEmpty)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "⚡ ${visibleMarkers.length} Şarj İstasyonu",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4CB8C4),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListView(
                                  padding: const EdgeInsets.only(bottom: 80),
                                  children: visibleCards,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      // Use a floating action button that matches the screenshot
      floatingActionButton:
          activeRouteColor != null
              ? Container(
                width: 300,
                height: 56,
                margin: const EdgeInsets.only(bottom: 150),
                child: FloatingActionButton.extended(
                  onPressed: () async {
                    // Show battery input dialog first
                    double initialCharge =
                        double.tryParse(initialChargeController.text) ?? 100.0;

                    // If user cancelled, don't proceed
                    if (initialCharge == 0) return;

                    final encodedPolyline =
                        polylines
                            .firstWhere(
                              (pl) => pl.color.toString() == activeRouteColor,
                            )
                            .points;
                    final stationList =
                        visibleMarkers
                            .map(
                              (m) => {
                                "lat": m.position.latitude,
                                "lng": m.position.longitude,
                                "name": m.infoWindow.title ?? "Unknown",
                              },
                            )
                            .toList();
                    final routePoints =
                        encodedPolyline
                            .map((p) => {"lat": p.latitude, "lng": p.longitude})
                            .toList();
                    final payload = {
                      "route": routePoints,
                      "stations": stationList,
                      "vehicleSoc": initialCharge,
                    };
                    final url = Uri.parse(
                      '$backendBaseUrl/maps/selected-navigation',
                    );
                    final headers = {'Content-Type': 'application/json'};
                    final res = await http.post(
                      url,
                      headers: headers,
                      body: jsonEncode(payload),
                    );
                    print(
                      "📤 Navigation payload gönderildi: ${res.statusCode}",
                    );
                    if (res.statusCode == 200) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => DrivingModeScreen(
                                backendBaseUrl: backendBaseUrl,
                              ),
                        ),
                      );
                    } else {
                      print("❌ Navigation set hatası: ${res.statusCode}");
                      setState(() {
                        statusMessage = "❌ Sürüş modu başlatılamadı.";
                      });
                    }
                  },
                  label: const Text(
                    "Sürüşe Başla",
                    style: TextStyle(color: Colors.white),
                  ),
                  icon: const Icon(Icons.directions_car, color: Colors.white),
                  backgroundColor: Color.fromARGB(255, 19, 98, 107),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              )
              : null,
    );
  }
}
