import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService with ChangeNotifier {
  String _currentCity = 'Unknown';
  String _currentState = 'Unknown';
  bool _isLoading = false;
  String _error = '';
  bool _permissionDenied = false;

  String get currentCity => _currentCity;
  String get currentState => _currentState;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get permissionDenied => _permissionDenied;

  Future<void> initializeLocation() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = 'Location services are disabled. Please enable location services.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Location permissions are denied. Please grant location access in app settings.';
          _permissionDenied = true;
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error = 'Location permissions are permanently denied. Please enable them in app settings.';
        _permissionDenied = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        // Get current position with lower accuracy for city-level detection
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
        );

        // Reverse geocoding to get city and state
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark placemark = placemarks.first;
          _currentCity = placemark.locality ?? 'Unknown City';
          _currentState = placemark.administrativeArea ?? 'Unknown State';

          // Clean up city name (remove area names)
          if (_currentCity.contains(',')) {
            _currentCity = _currentCity.split(',').first;
          }

          // Fallback if locality is null
          if (_currentCity == 'Unknown City' && placemark.subAdministrativeArea != null) {
            _currentCity = placemark.subAdministrativeArea!;
          }
        }

        _error = '';
        _permissionDenied = false;
      }
    } catch (e) {
      _error = 'Failed to get location: $e';
      _currentCity = 'Unknown';
      _currentState = 'Unknown';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  void updateLocation(String city, String state) {
    _currentCity = city;
    _currentState = state;
    notifyListeners();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }
}