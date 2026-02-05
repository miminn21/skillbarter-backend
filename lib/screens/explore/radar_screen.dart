import 'dart:convert';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import 'user_profile_screen.dart';
import '../../services/app_localizations.dart';

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  List<dynamic> _nearbyUsers = [];
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isLoading = true;

  // Cache addresses to avoid spamming API
  final Map<String, String> _addressCache = {};

  @override
  void initState() {
    super.initState();
    _startListeningLocation();
  }

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
        final address =
            data['display_name'] ??
            AppLocalizations.of(context)!.translate('radar_address_not_found');
        _addressCache[key] = address;
        if (mounted) setState(() {}); // Refresh UI if needed
        return address;
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
    }
    return AppLocalizations.of(context)!.translate('radar_address_fail');
  }

  void _showUserDetail(BuildContext context, dynamic user) {
    final lat = double.parse(user['latitude'].toString());
    final long = double.parse(user['longitude'].toString());
    final fotoProfil = user['foto_profil'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar with Ring
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.grey[100],
                  backgroundImage:
                      (fotoProfil != null && fotoProfil.toString().isNotEmpty)
                      ? MemoryImage(base64Decode(fotoProfil.toString()))
                      : null,
                  child: (fotoProfil == null || fotoProfil.toString().isEmpty)
                      ? Icon(Icons.person, size: 45, color: Colors.grey[400])
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // Name & Handle
              Text(
                user['nama_lengkap'] ?? 'User SkillBarter',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                "@${user['nama_panggilan']}",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 24),

              // Location Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).scaffoldBackgroundColor
                      : Colors.grey[50], // Adaptive
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]!
                        : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.translate('radar_current_location'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FutureBuilder<String>(
                            future: _getAddress(lat, long),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('radar_address_loading'),
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                );
                              }
                              return Text(
                                snapshot.data ??
                                    AppLocalizations.of(
                                      context,
                                    )!.translate('radar_address_unavailable'),
                                style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey[400]
                                      : Colors.black54,
                                  height: 1.4,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            UserProfileScreen(nik: user['nik'].toString()),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_rounded),
                  label: Text(
                    AppLocalizations.of(context)!.translate('btn_view_profile'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startListeningLocation() async {
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

      // 2. Start Stream (~High accuracy)
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.best, // Highest accuracy
        distanceFilter: 5, // Update every 5 meters moved
      );

      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen((Position position) {
            setState(() {
              _currentLocation = LatLng(position.latitude, position.longitude);
              _isLoading = false;
            });

            // Background update (fire and forget)
            _updateBackendLocation(position.latitude, position.longitude);
            // Refresh nearby users when we move significantly?
            // Optional, but good for accuracy. For now, let's pull nearby users on first load or manual refresh.
            // Or we can fetch effectively.
            if (_nearbyUsers.isEmpty) {
              _fetchNearbyUsers(position.latitude, position.longitude);
            }
          });
    } catch (e) {
      debugPrint("Error listening location: $e");
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
        queryParameters: {'latitude': lat, 'longitude': long, 'radius': 10000},
      );
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _nearbyUsers = response.data['data'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint("Fetch nearby failed: $e");
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentLocation == null) {
      return Scaffold(
        body: Center(
          child: _isLoading
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.translate('radar_calibrating'),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                )
              : Text(
                  AppLocalizations.of(
                    context,
                  )!.translate('radar_permission_needed'),
                ),
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
              initialZoom: 19.0, // Start very close
              minZoom: 10.0,
              maxZoom: 22.0, // Allow "digital zoom" deep into buildings
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.skillbarter',
                maxNativeZoom: 19, // Max level supported by OSM server
              ),
              MarkerLayer(
                markers: [
                  // --- My Location (Accurate Dot) ---
                  Marker(
                    point: _currentLocation!,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- Other Users ---
                  ..._nearbyUsers.map((user) {
                    final lat = double.parse(user['latitude'].toString());
                    final long = double.parse(user['longitude'].toString());
                    final fotoProfil = user['foto_profil'];

                    return Marker(
                      point: LatLng(lat, long),
                      width: 70,
                      height: 80,
                      child: GestureDetector(
                        onTap: () => _showUserDetail(context, user),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Avatar Pin
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 22,
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
                                        size: 22,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                            ),

                            // Pointer
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),

                            // Label
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                user['nama_panggilan'] ?? 'User',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
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

          // --- Refresh/Recenter Button ---
          Positioned(
            right: 20,
            bottom: 30,
            child: FloatingActionButton(
              onPressed: () {
                if (_currentLocation != null) {
                  _mapController.move(_currentLocation!, 17.5);
                  _fetchNearbyUsers(
                    _currentLocation!.latitude,
                    _currentLocation!.longitude,
                  );
                }
              },
              backgroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.my_location,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
