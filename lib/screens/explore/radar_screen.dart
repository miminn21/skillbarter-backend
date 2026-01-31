import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  List<dynamic> _nearbyUsers = [];
  Timer? _locationTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
    // Poll every 30s
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _initLocation();
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      // 1. Check Permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          return;
        }
      }

      // 2. Get Current Position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      // 3. Update Backend
      await _updateBackendLocation(position.latitude, position.longitude);

      // 4. Fetch Nearby Users
      await _fetchNearbyUsers(position.latitude, position.longitude);

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Error getting location: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateBackendLocation(double lat, double long) async {
    try {
      final api = ApiService();
      await api.post(
        '/location/update',
        data: {'latitude': lat, 'longitude': long},
      );
    } catch (e) {
      debugPrint("Update location failed: $e");
    }
  }

  Future<void> _fetchNearbyUsers(double lat, double long) async {
    try {
      final api = ApiService();
      final response = await api.get(
        '/location/nearby',
        params: {
          'latitude': lat,
          'longitude': long,
          'radius': 10000, // 10,000 km (Nation-wide)
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _nearbyUsers = response.data['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Fetch nearby failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentLocation == null) {
      return const Scaffold(
        body: Center(
          child: _isLoading
              ? CircularProgressIndicator()
              : Text("Izin Lokasi diperlukan untuk Radar"),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation!,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.skillbarter',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  // Me
                  Marker(
                    point: _currentLocation!,
                    width: 60,
                    height: 60,
                    child: const Column(
                      children: [
                        Icon(Icons.location_on, color: Colors.blue, size: 40),
                        Text(
                          "Saya",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  // Others
                  ..._nearbyUsers.map((user) {
                    final lat = double.parse(user['latitude'].toString());
                    final long = double.parse(user['longitude'].toString());
                    return Marker(
                      point: LatLng(lat, long),
                      width: 80,
                      height: 80,
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("User: ${user['nama_lengkap']}"),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              color: Colors.white.withOpacity(0.8),
                              child: Text(
                                user['nama_panggilan'] ?? 'User',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ],
          ),
          // Refresh Button
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _initLocation,
              child: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
    );
  }
}
