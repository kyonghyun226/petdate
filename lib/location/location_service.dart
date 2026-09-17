import 'package:geolocator/geolocator.dart';
import 'package:petdate/location/geo.dart';

/// Platform location access. Tests inject a fake.
abstract class LocationService {
  Future<bool> isServiceEnabled();
  Future<LocationPermissionStatus> checkPermission();
  Future<LocationPermissionStatus> requestPermission();
  Future<ApproxLatLng?> currentPosition();
  Future<void> openAppSettings();
  Future<void> openLocationSettings();
}

enum LocationPermissionStatus {
  denied,
  deniedForever,
  whileInUse,
  always,
  unableToDetermine,
}

extension LocationPermissionStatusX on LocationPermissionStatus {
  bool get isGranted =>
      this == LocationPermissionStatus.whileInUse ||
      this == LocationPermissionStatus.always;
}

class GeolocatorLocationService implements LocationService {
  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermissionStatus> checkPermission() async {
    return _map(await Geolocator.checkPermission());
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    return _map(await Geolocator.requestPermission());
  }

  @override
  Future<ApproxLatLng?> currentPosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return ApproxLatLng.approximate(pos.latitude, pos.longitude);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  LocationPermissionStatus _map(LocationPermission p) {
    return switch (p) {
      LocationPermission.denied => LocationPermissionStatus.denied,
      LocationPermission.deniedForever => LocationPermissionStatus.deniedForever,
      LocationPermission.whileInUse => LocationPermissionStatus.whileInUse,
      LocationPermission.always => LocationPermissionStatus.always,
      LocationPermission.unableToDetermine =>
        LocationPermissionStatus.unableToDetermine,
    };
  }
}

/// Deterministic stand-in for widget / unit tests.
class FakeLocationService implements LocationService {
  FakeLocationService({
    this.serviceEnabled = true,
    this.permission = LocationPermissionStatus.denied,
    this.position,
  });

  bool serviceEnabled;
  LocationPermissionStatus permission;
  ApproxLatLng? position;
  int requestCount = 0;

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermissionStatus> checkPermission() async => permission;

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    requestCount++;
    if (permission == LocationPermissionStatus.denied) {
      permission = LocationPermissionStatus.whileInUse;
    }
    return permission;
  }

  @override
  Future<ApproxLatLng?> currentPosition() async => position;

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}
}
