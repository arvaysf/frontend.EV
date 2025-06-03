// lib/widgets/charging_station_details_dialog.dart - Updated with images
import 'package:authentication/components/stations_images_helper.dart';
import 'package:authentication/models/energy/charging_stations.dart';
import 'package:flutter/material.dart';

class StationsDetails extends StatelessWidget {
  final ChargingStation station;
  final Function(String url) onLaunchUrl;

  const StationsDetails({
    super.key,
    required this.station,
    required this.onLaunchUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  Widget contentBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.0,
            offset: Offset(0.0, 10.0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // To make the dialog compact
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with station name and close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  station.stationName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CB8C4),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                color: Colors.grey,
              ),
            ],
          ),
          const Divider(),
          
          // Station image - bigger in the dialog
          Center(
            child: StationImageHelper.buildStationImage(
              station,
              width: 120,
              height: 120,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          
          // Scrollable content area
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main details in a table-like format
                  _buildDetailRow('ID', station.id != null ? '${station.id}' : 'N/A'),
                  _buildDetailRow('Charging Power', station.sarjGucu),
                  _buildDetailRow('Connection Type', station.fixedConnectionType),
                  _buildDetailRow('Price', station.fiyat),
                  
                  // Smart features section - highlight this since it was missing
                  const SizedBox(height: 16),
                  const Text(
                    'Smart Features:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CB8C4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(12),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      station.fixedSmartFeatures.isEmpty 
                        ? 'No smart features available' 
                        : station.fixedSmartFeatures,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  
                  // Product link section
                  if (station.urunLinki.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Product Link:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CB8C4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => onLaunchUrl(station.urunLinki),
                      child: Text(
                        station.urunLinki,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // Only Close button at the bottom
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                foregroundColor: const Color(0xFF4CB8C4), // Colored close button
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to build detail rows
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}