import 'package:location/location.dart';

class LocationService {
  final Location _location = Location();

  Future<bool> _checkAndRequestPermission() async {
    var permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return false; // User denied permission
      }
    }

    var serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return false; // User didn't enable location service
      }
    }
    return true;
  }

  Future<LocationData?> getCurrentLocation() async {
    final hasPermission = await _checkAndRequestPermission();
    if (!hasPermission) {
      print("Location permission or service denied.");
      return null;
    }
    try {
      // May need to adjust accuracy based on needs
      return await _location.getLocation();
    } catch (e) {
      print("Error getting location: $e");
      return null;
    }
  }
}