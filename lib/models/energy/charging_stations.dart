// lib/models/energy/charging_stations.dart

// Updated ChargingStation model with improved Turkish character support
import 'dart:convert';
import 'package:flutter/material.dart';

class ChargingStation {
  final int? id;
  final String marka;
  final String model;
  final String sarjGucu;
  final String baglantiTipi;
  final String akilliOzellikler;
  final String fiyat;
  final String urunLinki;
  final String? imagePath; 

  ChargingStation({
    this.id,
    required this.marka,
    required this.model,
    required this.sarjGucu,
    required this.baglantiTipi,
    required this.akilliOzellikler,
    required this.fiyat,
    required this.urunLinki,
    this.imagePath, 
  });

  // Enhanced method to fix Turkish character encoding issues
  static String _fixTurkishEncoding(String text) {
    try {
      // Check if text appears to have encoding issues
      // Added Å (for Ş), İ, Ğ, and other common Turkish character encoding issues
      if (text.contains('Ä±') || text.contains('Ã¼') || text.contains('Ã§') || 
          text.contains('Ã¶') || text.contains('Ä°') || text.contains('ÄŸ') ||
          text.contains('Â') || text.contains('Å') || text.contains('Ä') ||
          text.contains('Ã')) {
        // Convert to latin1 bytes then decode as UTF-8
        return utf8.decode(latin1.encode(text));
      }
      return text;
    } catch (e) {
      debugPrint('Error fixing Turkish encoding: $e');
      return text; // Return original text if decoding fails
    }
  }

  // Get properly encoded station name (for use in UI)
  String get stationName {
    return '${_fixTurkishEncoding(marka)} ${_fixTurkishEncoding(model)}'.trim();
  }

  // Get properly encoded connection type (for use in UI)
  String get fixedConnectionType {
    return _fixTurkishEncoding(baglantiTipi);
  }

  // Get properly encoded smart features (for use in UI)
  String get fixedSmartFeatures {
    return _fixTurkishEncoding(akilliOzellikler);
  }

  factory ChargingStation.fromJson(Map<String, dynamic> json) {
    return ChargingStation(
      id: json['id'],
      marka: json['marka'] ?? '',
      model: json['model'] ?? '',
      sarjGucu: json['sarjGucu'] ?? '',
      baglantiTipi: json['baglantiTipi'] ?? '',
      akilliOzellikler: json['akilliOzellikler'] ?? '',
      fiyat: json['fiyat'] ?? '',
      urunLinki: json['urunLinki'] ?? '',
      imagePath: json['imagePath'], 
    );
  }
}