import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapHelper {
  static Widget stationListWidget({
    required List<Widget> stationCards,
    required int stationCount,
  }) {
    if (stationCards.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onVerticalDragUpdate: (details) {},
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$stationCount Şarj İstasyonu",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 8),
                physics: const BouncingScrollPhysics(),
                children: stationCards,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget loadingOverlay({required bool isLoading, String? message}) {
    if (!isLoading) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(message ?? "Lütfen bekleyin..."),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget createStationCard({
    required Map<String, dynamic> station,
    required Function(double lat, double lng) onTap,
  }) {
    final lat = station['geometry']['location']['lat'];
    final lng = station['geometry']['location']['lng'];
    final name = station['name'] ?? 'Unnamed';
    final connector = station['connectorType'] ?? 'Unknown';
    final power = station['outputPowerKW']?.toString() ?? 'Belirsiz';
    final vicinity = station['vicinity'] ?? '-';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      child: ListTile(
        title: Text("⚡ $name"),
        subtitle: Text("📍 $vicinity\n🔌 $connector - $power kW"),
        onTap: () => onTap(lat, lng),
      ),
    );
  }

  static void zoomToFitAll({
    required GoogleMapController mapController,
    required Set<Marker> markers,
    required Set<Polyline> polylines,
  }) {
    if (markers.isEmpty && polylines.isEmpty) return;

    double minLat = 90.0;
    double maxLat = -90.0;
    double minLng = 180.0;
    double maxLng = -180.0;

    for (var marker in markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;

      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    for (var polyline in polylines) {
      for (var point in polyline.points) {
        final lat = point.latitude;
        final lng = point.longitude;

        if (lat < minLat) minLat = lat;
        if (lat > maxLat) maxLat = lat;
        if (lng < minLng) minLng = lng;
        if (lng > maxLng) maxLng = lng;
      }
    }

    final padding = 0.1;
    final latPadding = (maxLat - minLat) * padding;
    final lngPadding = (maxLng - minLng) * padding;

    mapController.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - latPadding, minLng - lngPadding),
          northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
        ),
        50,
      ),
    );
  }
}