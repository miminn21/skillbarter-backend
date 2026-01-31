import 'dart:convert';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
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

  // Cache addresses to avoid spamming API
  final Map<String, String> _addressCache = {};

  Future<String> _getAddress(double lat, double long) async {
    final key = "$lat,$long";
    if (_addressCache.containsKey(key)) return _addressCache[key]!;

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$long&zoom=18&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'SkillBarter/1.0 (com.example.skillbarter)'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['display_name'] ?? 'Alamat tidak ditemukan';
        _addressCache[key] = address;
        return address;
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
    }
    return "Gagal memuat alamat";
  }

  void _showUserDetail(BuildContext context, dynamic user) {
    final lat = double.parse(user['latitude'].toString());
    final long = double.parse(user['longitude'].toString());
    final fotoProfil = user['foto_profil'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[200],
                backgroundImage:
                    (fotoProfil != null && fotoProfil.toString().isNotEmpty)
                    ? MemoryImage(base64Decode(fotoProfil.toString()))
                    : null,
                child: (fotoProfil == null || fotoProfil.toString().isEmpty)
                    ? const Icon(Icons.person, size: 40, color: Colors.grey)
                    : null,
              ),
              const SizedBox(height: 16),

              // Name
              Text(
                user['nama_lengkap'] ?? 'User SkillBarter',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "@${user['nama_panggilan']}",
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Address Loading
              FutureBuilder<String>(
                future: _getAddress(lat, long),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text("Mencari alamat lengkap..."),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.map, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            "Lokasi Terkini:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        snapshot.data ?? "Alamat tidak tersedia",
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Navigate to Chat or Profile
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text("Chat User Ini"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
        queryParameters: {
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
      return Scaffold(
        body: Center(
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text("Izin Lokasi diperlukan untuk Radar"),
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
                    final fotoProfil = user['foto_profil'];

                    return Marker(
                      point: LatLng(lat, long),
                      width: 80,
                      height: 80,
                      child: GestureDetector(
                        onTap: () => _showUserDetail(context, user),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey[200],
                                backgroundImage:
                                    (fotoProfil != null &&
                                        fotoProfil.toString().isNotEmpty)
                                    ? MemoryImage(
                                        base64Decode(fotoProfil.toString()),
                                      )
                                    : null,
                                child:
                                    (fotoProfil == null ||
                                        fotoProfil.toString().isEmpty)
                                    ? const Icon(
                                        Icons.person,
                                        size: 20,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
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
