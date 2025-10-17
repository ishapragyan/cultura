import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/city_info.dart';

class ApiService with ChangeNotifier {
  final Map<String, CityInfo> _cache = {};
  bool _isLoading = false;
  String _error = '';

  bool get isLoading => _isLoading;
  String get error => _error;

  Future<CityInfo?> getCulturalInfo(String city, String state) async {
    // Check cache first
    final cacheKey = '$city-$state';
    if (_cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      final now = DateTime.now();
      if (now.difference(cached.lastUpdated).inHours < 24) {
        return cached;
      }
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Wikipedia API for cultural information
      final response = await http.get(
        Uri.parse(
          'https://en.wikipedia.org/api/rest_v1/page/summary/${city.replaceAll(' ', '_')}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final extract = data['extract'] ?? 'No cultural information available.';

        // Create CityInfo object
        final cityInfo = CityInfo(
          cityName: city,
          state: state,
          culturalInfo: extract,
          lastUpdated: DateTime.now(),
        );

        // Cache the result
        _cache[cacheKey] = cityInfo;

        return cityInfo;
      } else {
        _error = 'Failed to fetch cultural information';
        return null;
      }
    } catch (e) {
      _error = 'Error fetching data: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }
}