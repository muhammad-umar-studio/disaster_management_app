import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String address;
  final String city;
  final String country;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.city,
    required this.country,
  });
}

class LocationService {
  static LocationData? _cached;
  static LocationData? get cached => _cached;

  static Future<LocationData?> getCurrentLocation() async {
    try {
      // Check service enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      // Check/request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      // Get position
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Reverse geocode
      String address = '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      String city    = 'Unknown';
      String country = '';

      try {
        final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          city    = p.locality ?? p.administrativeArea ?? 'Unknown';
          country = p.country  ?? '';
          address = [p.street, p.subLocality, city, country].where((s) => s != null && s.isNotEmpty).join(', ');
        }
      } catch (_) {}

      _cached = LocationData(
        latitude:  pos.latitude,
        longitude: pos.longitude,
        address:   address,
        city:      city,
        country:   country,
      );
      return _cached;
    } catch (_) {
      return null;
    }
  }

  static Future<double?> getDistanceTo(double lat, double lon) async {
    final loc = _cached ?? await getCurrentLocation();
    if (loc == null) return null;
    return Geolocator.distanceBetween(loc.latitude, loc.longitude, lat, lon) / 1000;
  }

  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // update every 50m
      ),
    );
  }
}
