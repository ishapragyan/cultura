import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../services/tts_service.dart';
import '../models/city_info.dart';

class CuisineScreen extends StatefulWidget {
  const CuisineScreen({super.key});

  @override
  State<CuisineScreen> createState() => _CuisineScreenState();
}

class _CuisineScreenState extends State<CuisineScreen> {
  CityInfo? _currentCityInfo;

  @override
  void initState() {
    super.initState();
    _loadCuisineData();
  }

  void _loadCuisineData() async {
    final locationService = context.read<LocationService>();
    final apiService = context.read<ApiService>();

    if (locationService.currentCity != 'Unknown') {
      final cityInfo = await apiService.getCulturalInfo(
        locationService.currentCity,
        locationService.currentState,
      );

      if (mounted) {
        setState(() {
          _currentCityInfo = cityInfo;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationService = context.watch<LocationService>();
    final apiService = context.watch<ApiService>();
    final ttsService = context.watch<TtsService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Cuisine'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCuisineData,
          ),
        ],
      ),
      body: _buildBody(locationService, apiService, ttsService),
    );
  }

  Widget _buildBody(LocationService location, ApiService api, TtsService tts) {
    if (location.isLoading || api.isLoading) {
      return _buildLoading();
    }

    if (location.error.isNotEmpty) {
      return _buildError(location.error);
    }

    if (api.error.isNotEmpty) {
      return _buildError(api.error);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLocationCard(location),
          const SizedBox(height: 20),
          _buildCuisineCard(tts),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Discovering local cuisine...'),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Unable to load cuisine data',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCuisineData,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(LocationService location) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.restaurant, color: Colors.orange, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cuisine of',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Text(
                    location.currentCity,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    location.currentState,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCuisineCard(TtsService tts) {
    final cuisineInfo = _currentCityInfo?.cuisine ?? 'Cuisine information not available for this location.';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Local Delicacies',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: Icon(
                    tts.ttsState == TtsState.playing
                        ? Icons.volume_up
                        : Icons.volume_down,
                  ),
                  onPressed: () => tts.speak(cuisineInfo),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCuisineContent(cuisineInfo),
          ],
        ),
      ),
    );
  }

  Widget _buildCuisineContent(String cuisineInfo) {
    if (cuisineInfo == 'Cuisine information not available for this location.') {
      return Column(
        children: [
          const Icon(Icons.fastfood, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            cuisineInfo,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }

    // If we have actual cuisine data, format it nicely
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          cuisineInfo,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        _buildPopularDishes(cuisineInfo),
      ],
    );
  }

  Widget _buildPopularDishes(String cuisineInfo) {
    // Extract potential dish names from the cuisine info
    final dishes = _extractDishesFromText(cuisineInfo);

    if (dishes.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular Dishes:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: dishes.map((dish) {
            return Chip(
              label: Text(dish),
              backgroundColor: Colors.orange[50],
            );
          }).toList(),
        ),
      ],
    );
  }

  List<String> _extractDishesFromText(String text) {
    // Simple extraction of potential dish names (you can enhance this)
    final dishKeywords = ['pakhal', 'bhat', 'dalma', 'chhena', 'poda', 'vada', 'pav', 'bhaji', 'biryani', 'dosa', 'idli'];
    final foundDishes = <String>[];

    for (final keyword in dishKeywords) {
      if (text.toLowerCase().contains(keyword)) {
        foundDishes.add(keyword);
      }
    }

    return foundDishes.take(5).toList();
  }
}