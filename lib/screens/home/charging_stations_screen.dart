// lib/screens/charging_station_screen.dart - Updated with images
import 'package:authentication/components/stations_images_helper.dart';
import 'package:authentication/models/energy/charging_stations.dart';
import 'package:authentication/models/energy/stations_details.dart';
import 'package:authentication/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ChargingStationScreen extends StatefulWidget {
  const ChargingStationScreen({super.key});

  @override
  State<ChargingStationScreen> createState() => _ChargingStationScreenState();
}

class _ChargingStationScreenState extends State<ChargingStationScreen> {
  List<ChargingStation> _stations = [];
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isConnected = false;

  String? _selectedPower;
  String? _selectedConnection;
  RangeValues _priceRange = const RangeValues(0, 100000);

 
  List<String> _powerOptions = []; // filters el options from backend
  List<String> _connectionTypeOptions = [];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final isConnected = await ApiService.testConnection();

      if (isConnected) {
        final options = await ApiService.getAvailableOptions();
        
        debugPrint("DEBUG - Raw connection types from API: ${options['connectionTypes']}");
        
        setState(() {
          _isConnected = true;
          _powerOptions = options['powerOptions'] ?? [];
          _connectionTypeOptions = options['connectionTypes'] ?? [];
          
          debugPrint("DEBUG - After state update, _connectionTypeOptions (${_connectionTypeOptions.length}): $_connectionTypeOptions");
          _isLoading = false;
        });
        
        _fetchStations();
      } else {
        setState(() {
          _isConnected = false;
          _isLoading = false;
          _errorMessage = 'Could not connect to the backend';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isConnected = false;
        _errorMessage = 'Connection error: $e';
      });
    }
  }

  Future<void> _fetchStations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final stations = await ApiService.getMatchingStations(
        sarjGucu: _selectedPower,
        baglantiTipi: _selectedConnection,
        minPrice: _priceRange.start.round(),
        maxPrice: _priceRange.end.round(),
        marka: null, 
      );

      setState(() {
        _stations = stations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load stations: $e';
      });
    }
  }

  void _applyFilters() {
    _fetchStations();
  }

  void _resetFilters() {
    debugPrint('Resetting filters');
    setState(() {
      _selectedPower = null;
      _selectedConnection = null;
      _priceRange = const RangeValues(0, 100000);
    });
    Future.delayed(Duration(milliseconds: 100), () {
      _fetchStations();
    });
  }
  
  void _showStationDetails(ChargingStation station) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StationsDetails(
          station: station,
          onLaunchUrl: _launchURL,
        );
      },
    );
  }
  
  Future<void> _launchURL(String url) async {
    try {
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Home Chargers'),
        backgroundColor: const Color(0xFF4CB8C4),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeApp,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // connection status indicator
          Container(
            padding: const EdgeInsets.all(8),
            color: _isConnected ? Colors.green : Colors.red,
            child: Center(
              child: Text(
                _isConnected
                    ? 'Connected to backend'
                    : 'Not connected to backend',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),

          if (_errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.orange,
              width: double.infinity,
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.white),
              ),
            ),

          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Charging Power:', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Container(
                        height: 50, 
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: ButtonTheme(
                            alignedDropdown: true, 
                            child: DropdownButton<String>(
                              isExpanded: true,
                              itemHeight: 60, 
                              dropdownColor: Colors.white,
                              hint: const Padding(
                                padding: EdgeInsets.only(left: 16.0),
                                child: Text('Select power'),
                              ),
                              value: _selectedPower,
                              onChanged: (value) {
                                
                                debugPrint('Selected power: $value');
                                setState(() {
                                  _selectedPower = value;
                                });
                              },
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null, 
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 16.0),
                                    child: Text('Select power'),
                                  ),
                                ),
                                ..._powerOptions.map((power) {
                                  debugPrint('Adding power option to dropdown: $power');
                                  return DropdownMenuItem<String>(
                                    value: power,
                                    child: Container(
                                      constraints: BoxConstraints(minHeight: 40),
                                      padding: const EdgeInsets.only(left: 16.0),
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        power,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text('Connection Type:', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Container(
                        height: 50, 
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: ButtonTheme(
                            alignedDropdown: true, 
                            child: DropdownButton<String>(
                              isExpanded: true,
                              itemHeight: 60, 
                              dropdownColor: Colors.white,
                              hint: const Padding(
                                padding: EdgeInsets.only(left: 16.0),
                                child: Text('Select connection'),
                              ),
                              value: _selectedConnection,
                              onChanged: (value) {
                                debugPrint('Selected connection type: $value');
                                setState(() {
                                  _selectedConnection = value;
                                });
                              },
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null, 
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 16.0),
                                    child: Text('Select connection'),
                                  ),
                                ),
                                ..._connectionTypeOptions.map((connection) {
                                  debugPrint('Adding connection type: "$connection"');
                                  return DropdownMenuItem<String>(
                                    value: connection,
                                    child: Container(
                                      constraints: BoxConstraints(minHeight: 40), 
                                      padding: const EdgeInsets.only(left: 16.0),
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        connection,
                                        maxLines: 2, 
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text('Price Range:', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      RangeSlider(
                        values: _priceRange,
                        min: 0,
                        max: 100000,
                        divisions: 100,
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

                      // Filter buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: _applyFilters,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CB8C4),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Apply Filters'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _resetFilters();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CB8C4),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Reset Filters'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider
                const Divider(height: 1),

                // Results section
                _isLoading
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CB8C4)),
                        ),
                      ))
                    : _stations.isEmpty
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('No charging stations found'),
                      ))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _stations.length,
                        itemBuilder: (context, index) {
                          final station = _stations[index];
                          return Card(
                            color: Colors.white,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: InkWell(
                              onTap: () => _showStationDetails(station),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Station image - Using our helper to get the right image
                                    StationImageHelper.buildStationImage(
                                      station,
                                      width: 60,
                                      height: 60,
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    const SizedBox(width: 10),
                                    
                                    // Details section
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  station.stationName,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              // Info icon to indicate more details available 
                                              const Icon(
                                                Icons.info_outline,
                                                color: Color(0xFF4CB8C4),
                                                size: 22,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          
                                          // Preview of basic details
                                          Text(
                                            'Power: ${station.sarjGucu}',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                          Text(
                                            'Connection: ${station.fixedConnectionType}',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                          Text(
                                            'Price: ${station.fiyat}',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                          
                                          // Hint that there's more information
                                          if (station.akilliOzellikler.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.smart_toy_outlined,
                                                    size: 16,
                                                    color: Color(0xFF4CB8C4),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Text(
                                                    'Has smart features',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontStyle: FontStyle.italic,
                                                      color: Color(0xFF4CB8C4),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}