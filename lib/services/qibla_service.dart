// lib/services/qibla_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math' as math;

class QiblaService {
  static const double kaabaLatitude = 21.4225;
  static const double kaabaLongitude = 39.8262;

  double? currentHeading;
  double? qiblaDirection;
  Position? currentPosition;
  bool hasLocationPermission = false;
  bool hasSensorSupport = false;

  Future<void> initializeQibla() async {
    try {
      await _checkLocationPermission();
      if (!hasLocationPermission) {
        throw Exception('Location permission is required to find Qibla direction');
      }
      await _getCurrentLocation();
      await _checkCompassSupport();
      if (currentPosition != null) {
        _calculateQiblaDirection();
        startCompassListening(() => {});
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied. Please enable it in settings.');
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Location permission is required to determine Qibla direction.');
    }
    hasLocationPermission = true;
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
      if (position.accuracy > 50) {
        throw Exception('Lokasi tidak cukup akurat. Coba di area dengan sinyal GPS lebih baik.');
      }
      currentPosition = position;
    } catch (e) {
      throw Exception('Unable to get current location: ${e.toString()}');
    }
  }

  Future<void> _checkCompassSupport() async {
    try {
      final bool? hasCompass = await FlutterCompass.events?.isEmpty;
      hasSensorSupport = hasCompass != true;
      if (!hasSensorSupport) {
        throw Exception('Device does not support compass functionality');
      }
    } catch (e) {
      hasSensorSupport = false;
    }
  }

  void _calculateQiblaDirection() {
    if (currentPosition == null) return;
    final double lat1 = _degreesToRadians(currentPosition!.latitude);
    final double lng1 = _degreesToRadians(currentPosition!.longitude);
    final double lat2 = _degreesToRadians(kaabaLatitude);
    final double lng2 = _degreesToRadians(kaabaLongitude);
    final double deltaLng = lng2 - lng1;
    final double y = math.sin(deltaLng) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
                     math.sin(lat1) * math.cos(lat2) * math.cos(deltaLng);
    double bearing = math.atan2(y, x);
    bearing = _radiansToDegrees(bearing);
    bearing = (bearing + 360) % 360;
    qiblaDirection = bearing;
  }

  void startCompassListening(void Function() setState) {
    if (!hasSensorSupport) return;
    FlutterCompass.events?.listen((CompassEvent event) {
      if (event.accuracy != null && event.accuracy! < 0.1) {
        print('Compass needs calibration'); // Debugging
        return;
      }
      currentHeading = event.heading;
      print('Compass heading: ${event.heading}'); // Debugging
      setState();
    });
  }

  double _degreesToRadians(double degrees) => degrees * (math.pi / 180);
  double _radiansToDegrees(double radians) => radians * (180 / math.pi);

  double getQiblaAngle() => qiblaDirection != null && currentHeading != null
      ? qiblaDirection! - currentHeading!
      : 0;
}