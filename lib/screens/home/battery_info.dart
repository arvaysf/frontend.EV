// lib/screens/battery_info.dart
import 'package:authentication/models/energy/renewable_package.dart';
import 'package:flutter/material.dart';

class BatteryInfoScreen extends StatelessWidget {
  final RenewablePackage package;
  
  const BatteryInfoScreen({super.key, required this.package});

  @override
  Widget build(BuildContext context) {
    // Get battery information based on capacity
    final String features = _getBatteryFeatures(package.batteryCapacity);
    final String price = _getBatteryPrice(package.batteryCapacity);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('${package.batteryCapacity} Battery Details'),
        backgroundColor: const Color(0xFF4CB8C4),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Battery image
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Icon(
                Icons.battery_full,
                size: 80,
                color: const Color(0xFF4CB8C4),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Battery header
          Text(
            '${package.batteryBrand} ${package.batteryModel}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            package.batteryCapacity,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF4CB8C4),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Battery specs
          _buildSpecSection('Technical Specifications', [
            {'label': 'Capacity', 'value': package.batteryCapacity},
            {'label': 'Brand', 'value': package.batteryBrand},
            {'label': 'Model', 'value': package.batteryModel},
            {'label': 'Features', 'value': features},
            {'label': 'Estimated Price', 'value': price, 'highlight': true},
          ]),
          
        ],
      ),
    );
  }
  
  Widget _buildSpecSection(String title, List<Map<String, dynamic>> specs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(),
        ...specs.map((spec) => _buildSpecItem(
              spec['label']!, 
              spec['value']!,
              highlight: spec['highlight'] == true,
            )),
      ],
    );
  }
  
  Widget _buildSpecItem(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                color: highlight ? const Color(0xFF4CB8C4) : Colors.black,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getBatteryFeatures(String capacity) {
    switch (capacity) {
      case '5 kWh':
        return 'LFP(LiFePO4), modular, wall-mounted';
      case '10 kWh':
        return 'LFP, stackable modules, long life';
      case '15 kWh':
        return 'Hybrid-ready, 3 modules of 5kWh, integrates EMS';
      case '30 kWh':
        return 'High power output, smart BMS, industrial use';
      default:
        return 'Standard battery features';
    }
  }
  
  String _getBatteryPrice(String capacity) {
    switch (capacity) {
      case '5 kWh':
        return '25,000 - 28,000 TL';
      case '10 kWh':
        return '50,000 - 55,000 TL';
      case '15 kWh':
        return '75,000 - 80,000 TL';
      case '30 kWh':
        return '145,000 - 155,000 TL';
      default:
        return 'Contact for pricing';
    }
  }
}