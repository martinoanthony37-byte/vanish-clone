import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const VanishCloneApp());

class VanishCloneApp extends StatelessWidget {
  const VanishCloneApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapSelectionScreen(),
    );
  }
}

class MapSelectionScreen extends StatefulWidget {
  const MapSelectionScreen({Key? key}) : super(key: key);

  @override
  _MapSelectionScreenState createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  // Default map position set to Cupertino, CA
  LatLng _selectedLocation = const LatLng(37.3349, -122.0090); 
  bool _isSpoofing = false;

  // Your exact Windows PC local network IP address
  final String _serverIp = '192.168.137.1'; 

  /// Sends coordinates over Wi-Fi to your Windows Python desktop background engine
  Future<void> _updateLocationOnServer() async {
    final url = Uri.parse('http://$_serverIp:5000/spoof');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': _selectedLocation.latitude,
          'longitude': _selectedLocation.longitude,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isSpoofing = true;
        });
      } else {
        _showErrorSnackBar('Server Error: ${response.body}');
      }
    } catch (e) {
      _showErrorSnackBar('Could not connect to Windows Server. Is it running?');
    }
  }

  /// Sends a cancellation signal to return the device to hardware satellite GPS
  Future<void> _stopLocationOnServer() async {
    final url = Uri.parse('http://$_serverIp:5000/stop');
    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        setState(() {
          _isSpoofing = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Network connection lost.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vanish Clone App'),
        backgroundColor: Colors.blueAccent,
        actions: [
          Row(
            children: [
              Icon(
                Icons.circle, 
                color: _isSpoofing ? Colors.green : Colors.red,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                _isSpoofing ? 'Active' : 'Ready',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 15),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Displays the world map correctly inside the canvas area
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _selectedLocation,
                initialZoom: 13.0,
                onTap: (tapPosition, point) {
                  setState(() {
                    _selectedLocation = point;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://openstreetmap.org{z}/{x}/{y}.png', // Secure mapping for iOS
                  userAgentPackageName: 'com.vanishclone.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on, 
                        color: Colors.red, 
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Interface controls showing raw parameters and injection buttons
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Lat: ${_selectedLocation.latitude.toStringAsFixed(6)} \nLon: ${_selectedLocation.longitude.toStringAsFixed(6)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'monospace', 
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: _isSpoofing ? Colors.red : Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    if (_isSpoofing) {
                      _stopLocationOnServer();
                    } else {
                      _updateLocationOnServer();
                    }
                  },
                  child: Text(
                    _isSpoofing ? 'Stop Simulation' : 'Teleport Location',
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
