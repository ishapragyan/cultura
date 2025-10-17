import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService with ChangeNotifier {
  String _currentCity = 'Unknown';
  String _currentState = 'Unknown';
  bool _isLoading = false;
  String _error = '';

  String get currentCity => _currentCity;
  String get currentState => _currentState;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> initializeLocation() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Location permissions are denied';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error = 'Location permissions are permanently denied';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get current position
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
      }

      _error = '';
    } catch (e) {
      _error = 'Failed to get location: $e';
      _currentCity = 'Unknown';
      _currentState = 'Unknown';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateLocation(String city, String state) {
    _currentCity = city;
    _currentState = state;
    notifyListeners();
  }
}
