import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../core/utils/logger.dart';

/// Wraps [geolocator] + [geocoding] for complaint GPS tagging.
///
/// Exposes:
/// - [getCurrentPosition] — raw lat/lng
/// - [getPlaceName]       — human-readable address string
/// - [getLocationData]    — combined result for watermark + form prefill
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  // ─── Permission Helpers ────────────────────────────────────────────────────

  /// Returns true if location permission (fine or coarse) is granted.
  Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Requests location permission.
  /// Returns true if granted (fine or coarse), false otherwise.
  Future<bool> requestPermission() async {
    // Check if location services are enabled first
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      AppLogger.warning('LocationService: Device location services are OFF.');
      return false;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      AppLogger.warning(
        'LocationService: Permission permanently denied — opening settings.',
      );
      await Geolocator.openAppSettings();
      return false;
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  // ─── Core API ──────────────────────────────────────────────────────────────

  /// Returns the device's current [Position] with high accuracy.
  ///
  /// Throws a [LocationException] if permission is denied or services are off.
  Future<Position> getCurrentPosition() async {
    final granted = await requestPermission();
    if (!granted) {
      throw const LocationException('Location permission not granted.');
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      AppLogger.info(
        'LocationService: Got position '
        '(${position.latitude.toStringAsFixed(5)}, '
        '${position.longitude.toStringAsFixed(5)})',
      );
      return position;
    } catch (e) {
      AppLogger.error('LocationService: getCurrentPosition failed', error: e);
      rethrow;
    }
  }

  /// Reverse-geocodes a [lat]/[lng] into a human-readable address.
  ///
  /// Returns a short formatted string like "Block A, RVCE, Bengaluru".
  /// Falls back to raw coordinates if geocoding fails.
  Future<String> getPlaceName(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) {
        return _rawCoordString(lat, lng);
      }

      final p = placemarks.first;

      // Build a compact, human-readable string
      final parts = <String>[];
      if (p.subThoroughfare?.isNotEmpty == true) parts.add(p.subThoroughfare!);
      if (p.thoroughfare?.isNotEmpty == true) parts.add(p.thoroughfare!);
      if (p.subLocality?.isNotEmpty == true) parts.add(p.subLocality!);
      if (p.locality?.isNotEmpty == true) parts.add(p.locality!);

      if (parts.isEmpty) {
        if (p.administrativeArea?.isNotEmpty == true) {
          parts.add(p.administrativeArea!);
        }
        if (p.country?.isNotEmpty == true) parts.add(p.country!);
      }

      return parts.isNotEmpty ? parts.join(', ') : _rawCoordString(lat, lng);
    } catch (e) {
      AppLogger.warning(
        'LocationService: Reverse geocoding failed — ${e.toString()}',
      );
      return _rawCoordString(lat, lng);
    }
  }

  /// Fetches current position + reverse-geocoded place name in one call.
  ///
  /// Returns a [LocationData] bundle ready for use in:
  /// - Watermark stamping (location + coords)
  /// - Complaint form pre-fill
  ///
  /// Returns null if permission was denied.
  Future<LocationData?> getLocationData() async {
    try {
      final position = await getCurrentPosition();
      final placeName = await getPlaceName(
        position.latitude,
        position.longitude,
      );

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        placeName: placeName,
        accuracy: position.accuracy,
      );
    } on LocationException catch (e) {
      AppLogger.warning('LocationService: ${e.message}');
      return null;
    } catch (e) {
      AppLogger.error('LocationService: getLocationData failed', error: e);
      return null;
    }
  }

  // ─── Private ───────────────────────────────────────────────────────────────

  String _rawCoordString(double lat, double lng) {
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }
}

// ─── Data Classes ─────────────────────────────────────────────────────────────

/// Holds everything the complaint form + watermark need from a GPS fix.
class LocationData {
  final double latitude;
  final double longitude;
  final String placeName;
  final double accuracy; // metres

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.placeName,
    required this.accuracy,
  });

  @override
  String toString() =>
      'LocationData(lat=$latitude, lng=$longitude, '
      'place="$placeName", acc=${accuracy}m)';
}

/// Thrown when the location service cannot obtain a fix.
class LocationException implements Exception {
  final String message;
  const LocationException(this.message);

  @override
  String toString() => 'LocationException: $message';
}
