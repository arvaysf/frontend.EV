// lib/screens/renewable_energy.dart
import 'package:authentication/models/energy/renewable_package.dart';
import 'package:authentication/screens/home/battery_info.dart';
import 'package:flutter/material.dart';

class RenewableEnergyScreen extends StatefulWidget {  
  const RenewableEnergyScreen({super.key});

  @override
  State<RenewableEnergyScreen> createState() => _RenewableEnergyScreenState();
}

class _RenewableEnergyScreenState extends State<RenewableEnergyScreen> {
  List<RenewablePackage> _packages = [];
  List<RenewablePackage> _filteredPackages = [];
  bool _isLoading = false;

  String? _selectedPower;
  RangeValues _priceRange = const RangeValues(0, 500000);

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  void _loadPackages() {
    setState(() {
      _isLoading = true;
    });

    _packages = RenewablePackageData.getAllPackages();

    setState(() {
      _filteredPackages = List.from(_packages);
      _isLoading = false;
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredPackages = _packages.where((package) {
        // filters by power here 
        if (_selectedPower != null && package.power != _selectedPower) {
          return false;
        }
        
        // and here by elprice range 
        final price = package.totalCost;
        if (price < _priceRange.start || price > _priceRange.end) {
          return false;
        }
        
        return true;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedPower = null;
      _priceRange = const RangeValues(0, 500000);
      _filteredPackages = List.from(_packages);
    });
  }

  void _showPackageDetails(RenewablePackage package) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PackageDetailScreen(package: package),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Renewable Solar Charging'),
        backgroundColor: const Color(0xFF4CB8C4),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CB8C4)),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Select package',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              hint: const Text('Filter by power'),
                              value: _selectedPower,
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              onChanged: (value) {
                                setState(() {
                                  _selectedPower = value;
                                  _applyFilters();
                                });
                              },
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Select power option'),
                                ),
                                ..._packages
                                    .map((p) => p.power)
                                    .toSet()
                                    .map((power) => DropdownMenuItem<String>(
                                          value: power,
                                          child: Text(power),
                                        )),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => _buildFilterSheet(),
                          );
                        },
                        tooltip: 'More filters',
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Expanded(
                  child: _filteredPackages.isEmpty
                      ? const Center(
                          child: Text('No packages match your criteria'),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _filteredPackages.length,
                          itemBuilder: (context, index) {
                            return _buildSimplePackageCard(_filteredPackages[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildFilterSheet() {
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Options',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              const Text('Price Range:', style: TextStyle(fontWeight: FontWeight.bold)),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 500000,
                divisions: 50,
                activeColor: const Color(0xFF4CB8C4),
                labels: RangeLabels(
                  '${_priceRange.start.round()} TL',
                  '${_priceRange.end.round()} TL',
                ),
                onChanged: (values) {
                  setState(() {
                    _priceRange = values;
                  });
                },
              ),
              Center(
                child: Text(
                  '${_priceRange.start.round()} TL - ${_priceRange.end.round()} TL',
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CB8C4),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Apply'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      _resetFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimplePackageCard(RenewablePackage package) {
    return Card(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _showPackageDetails(package),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                color: Colors.white,
                width: double.infinity,
                child: Center(
                  child: Image.asset(
                    'assets/solar_car.png',
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${package.power} Solar EV\nCharging Package',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  
                  Text(
                    package.energyPerDay,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  Text(
                    package.panelsDisplay,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showPackageDetails(package),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CB8C4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: const Size(double.infinity, 30),
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                      child: const Text('view package'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PackageDetailScreen extends StatelessWidget {
  final RenewablePackage package;
  
  const PackageDetailScreen({super.key, required this.package});
  
  String _formatPrice(int price) {
    final priceString = price.toString();
    final buffer = StringBuffer();
    
    for (int i = 0; i < priceString.length; i++) {
      if (i > 0 && (priceString.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(priceString[i]);
    }
    
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('${package.power} Package'),
        backgroundColor: const Color(0xFF4CB8C4),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Package header
          Text(
            '${package.power} Package',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          
          // Specifications
          _buildSpecItem('Panel Power', package.panelPower),
          _buildSpecItem('Number of Panels', package.numberOfPanels.toString()),
          _buildSpecItem('Inverter Power', package.inverterPower),
          _buildSpecItem('Inverter Model', package.inverterModel),
          _buildSpecItem('Inverter Brand', package.inverterBrand),
          _buildSpecItem('Charger Type', package.chargerType),
          _buildSpecItem('Charger Model', package.chargerModel),
          _buildSpecItem('Charger Price', '${_formatPrice(package.chargerPrice)} TL'),
          _buildSpecItem('Battery Capacity', package.batteryCapacity),
          _buildSpecItem('Battery Model', package.batteryModel),
          _buildSpecItem('Battery Brand', package.batteryBrand),
          if (package.batteryFeatures != null)
            _buildSpecItem('Battery Features', package.batteryFeatures!),
          _buildSpecItem('Total Cost with Battery', '${_formatPrice(package.totalCost)} TL', highlight: true),
          _buildSpecItem('ROI (%)', package.roi, highlight: true),
          
          const SizedBox(height: 24),
          
          // Purchase button
          ElevatedButton(
            onPressed: () {
              // Navigate to the battery info screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BatteryInfoScreen(package: package),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CB8C4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Battery Info',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
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
}