import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../theme/theme_x.dart';

/// Delivery location pin - flutter_map + OpenStreetMap tiles (no API key
/// needed). Returns the picked LatLng via Navigator.pop, or null if cancelled.
class LocationPickerScreen extends StatefulWidget {
  final LatLng? initial;
  const LocationPickerScreen({super.key, this.initial});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _fallbackCenter = LatLng(24.8607, 67.0011); // Karachi

  final _mapController = MapController();
  LatLng? _picked;
  bool _locating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _picked = widget.initial;
  }

  Future<void> _useMyLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          _locating = false;
          _error = 'Location permission denied. Please pick the point on the map instead.';
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final point = LatLng(pos.latitude, pos.longitude);
      _mapController.move(point, 16);
      setState(() {
        _picked = point;
        _locating = false;
      });
    } catch (_) {
      setState(() {
        _locating = false;
        _error = 'Could not detect your location. Please pick the point on the map instead.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appTheme.colors;
    final start = widget.initial ?? _fallbackCenter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Delivery Location'),
        actions: [
          TextButton(
            onPressed: _picked == null ? null : () => Navigator.pop(context, _picked),
            child: const Text('Confirm'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Tap on the map (or drag the pin) to mark exactly where the order should be delivered.',
                    style: TextStyle(color: c.textMuted, fontSize: 12.5),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _locating ? null : _useMyLocation,
                  icon: _locating
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location, size: 16),
                  label: const Text('My Location'),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12.5)),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: start,
                initialZoom: widget.initial != null ? 15 : 5,
                onTap: (_, point) => setState(() => _picked = point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.smartmart.mobile',
                  subdomains: const ['a', 'b', 'c'],
                ),
                if (_picked != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _picked!,
                        width: 40,
                        height: 40,
                        child: Icon(Icons.location_pin, color: c.primary, size: 40),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
