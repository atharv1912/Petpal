import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

Future<LocationPermission> checkLocationPermission() async {
  // First check if location services are enabled
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return LocationPermission.denied;
  }

  // Check permission status
  var status = await Permission.location.status;
  if (status.isDenied) {
    // Request permission if denied
    status = await Permission.location.request();
  }

  // Map PermissionStatus to LocationPermission
  if (status.isPermanentlyDenied) {
    return LocationPermission.deniedForever;
  } else if (status.isGranted) {
    return LocationPermission.whileInUse;
  } else {
    return LocationPermission.denied;
  }
}

Future<bool> requestLocationPermission() async {
  final status = await Permission.location.request();
  return status.isGranted;
}
