import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

class LocationResult {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speedKmH;
  final DateTime timestamp;

  LocationResult({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speedKmH,
    required this.timestamp,
  });
}

class LocationService {
  /// Check if location services (GPS) are enabled on the device
  Future<bool> isServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('[LocationService] isLocationServiceEnabled error: $e');
      return false;
    }
  }

  /// Check and request location permissions if needed.
  /// Returns true if permission is granted (whileInUse or always).
  Future<bool> checkAndRequestPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[LocationService] Location permission denied by user.');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Location permission denied forever.');
        return false;
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      debugPrint('[LocationService] Permission check error: $e');
      return false;
    }
  }

  /// Fetches current high-accuracy device position.
  /// Returns null if GPS is disabled or permission denied.
  Future<LocationResult?> getCurrentLocation({Duration timeout = const Duration(seconds: 12)}) async {
    try {
      final serviceEnabled = await isServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] GPS is disabled on device.');
        return null;
      }

      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) {
        debugPrint('[LocationService] No location permission.');
        return null;
      }

      // First attempt: get current position
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (e) {
        debugPrint('[LocationService] getCurrentPosition timeout/error, trying last known: $e');
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) return null;

      final speedInKmH = position.speed >= 0 ? (position.speed * 3.6) : null;

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speedKmH: speedInKmH,
        timestamp: position.timestamp,
      );
    } catch (e) {
      debugPrint('[LocationService] Failed to get location: $e');
      return null;
    }
  }

  /// Open Android location settings so user can enable GPS if turned off
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      return false;
    }
  }

  /// Open App system settings so user can grant permission if denied forever
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      return false;
    }
  }
}
