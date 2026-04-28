import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationResult {
  final double lat;
  final double lng;
  final String? address;

  const LocationResult({required this.lat, required this.lng, this.address});
}

class LocationService {
  // ── GPS ─────────────────────────────────────────────────────────────────

  /// Request permission then return current GPS position + reverse-geocoded address.
  static Future<LocationResult> getCurrentLocation() async {
    // 1. Check if GPS is enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        'GPS is disabled on your device. Please turn on Location Services and try again.',
      );
    }

    // 2. Check / request permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException(
          'Location permission denied. Please allow location access for this app.',
        );
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Location permission is permanently denied. Open Settings → App permissions to enable it.',
      );
    }

    // 3. Fetch position
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );

    // 4. Reverse geocode (best-effort — won't throw)
    final address = await _reverseGeocode(pos.latitude, pos.longitude);

    return LocationResult(lat: pos.latitude, lng: pos.longitude, address: address);
  }

  // ── Reverse geocode ──────────────────────────────────────────────────────

  /// Convert lat/lng → human-readable address string. Returns null on failure.
  static Future<String?> _reverseGeocode(double lat, double lng) async {
    try {
      final marks = await placemarkFromCoordinates(lat, lng);
      if (marks.isEmpty) return null;
      final p = marks.first;
      final parts = <String>[
        if (p.street?.isNotEmpty ?? false) p.street!,
        if (p.subLocality?.isNotEmpty ?? false) p.subLocality!,
        if (p.locality?.isNotEmpty ?? false) p.locality!,
        if (p.administrativeArea?.isNotEmpty ?? false) p.administrativeArea!,
        if (p.country?.isNotEmpty ?? false) p.country!,
      ];
      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  // ── Forward geocode (work location search) ───────────────────────────────

  /// Search an address string → return best-matching LocationResult.
  /// Returns null if nothing found or service unavailable.
  static Future<LocationResult?> searchAddress(String query) async {
    if (query.trim().isEmpty) return null;
    try {
      final locations = await locationFromAddress(query.trim());
      if (locations.isEmpty) return null;
      final loc = locations.first;
      // Reverse geocode the result to get a clean address label
      final address =
          await _reverseGeocode(loc.latitude, loc.longitude) ?? query.trim();
      return LocationResult(
        lat: loc.latitude,
        lng: loc.longitude,
        address: address,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Distance ─────────────────────────────────────────────────────────────

  /// Haversine straight-line distance in km between two coordinates.
  static double haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _rad(double deg) => deg * math.pi / 180;
}

class LocationException implements Exception {
  final String message;
  const LocationException(this.message);

  @override
  String toString() => message;
}
