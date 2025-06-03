// lib/components/stations_images_helper.dart
// Enhanced with better debugging and more flexible matching

import 'package:flutter/material.dart';
import 'package:authentication/models/energy/charging_stations.dart';

class StationImageHelper {
  static String getImagePathForStation(ChargingStation station) {
    final String fullName =
        '${station.marka} ${station.model}'.toLowerCase().trim();
    final String brand = station.marka.toLowerCase().trim();

    debugPrint('DEBUG - Looking for image for: "$fullName" (brand: "$brand")');

    
    final Map<String, String> brandImages = {
      'vestel': 'assets/chargers/Vestel EVC04 22kW Kablolu.png',
      'schneider': 'assets/chargers/schneider-evlink-home-11kw.png',
      'schneider electric': 'assets/chargers/schneider-evlink-home-11kw.png',
      'voltrun': 'assets/chargers/voltrun-22kW-cift-soket-sarj-cihazi-1536x1536.png',
      'powersarj': 'assets/chargers/Powerşarj 7.4kW.png',
      'onlife charge': 'assets/chargers/pics_devicesAC_Big.png',
      'wissenergy': 'assets/chargers/WISSENERGY* Basic:APP.png',
      
    };

    
    if (brandImages.containsKey(brand)) {
      debugPrint('DEBUG - Found exact brand match: "$brand"');
      return brandImages[brand]!;
    }

    for (final key in brandImages.keys) {
      if (fullName.contains(key)) {
        debugPrint('DEBUG - Found partial match: "$key" in "$fullName"');
        return brandImages[key]!;
      }
    }

    for (final key in brandImages.keys) {
      if (brand.contains(key) || key.contains(brand)) {
        debugPrint('DEBUG - Found fuzzy match: "$key" with "$brand"');
        return brandImages[key]!;
      }
    }

    debugPrint('⚠️ WARNING - No image match found for: "$fullName"');
    debugPrint('Available brands: ${brandImages.keys.join(", ")}');

    // Fallback to default image
    return 'assets/images/default.png';
  }

  static Widget buildStationImage(
    ChargingStation station, {
    double width = 60,
    double height = 60,
    BoxBorder? border,
    BorderRadius? borderRadius,
  }) {
    final imagePath = getImagePathForStation(station);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        border: border ?? Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          // The actual image with error handling
          Positioned.fill(
            child: ClipRRect(
              borderRadius: borderRadius ?? BorderRadius.circular(8),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                width: width,
                height: height,
                // Show detailed error and fall back to icon
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('❌ ERROR - Failed to load image: $imagePath');
                  debugPrint('Error details: $error');
                  // Fallback to icon
                  return Center(
                    child: Icon(
                      Icons.electric_car,
                      size: width * 0.6,
                      color: Colors.blue,
                    ),
                  );
                },
              ),
            ),
          ),

          if (false) 
            // ignore: dead_code
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withOpacity(0.7),
                padding: const EdgeInsets.all(2),
                child: Text(
                  station.marka,
                  style: const TextStyle(color: Colors.white, fontSize: 8),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
