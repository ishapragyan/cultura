import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../services/llm_service.dart';
import '../services/tts_service.dart';
import '../models/city_info.dart';

class CuisineScreen extends StatefulWidget {
  const CuisineScreen({super.key});

  @override
  State<CuisineScreen> createState() => _CuisineScreenState();
}

class _CuisineScreenState extends State<CuisineScreen> {
  String? _cuisineInfo;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadCuisineData();
  }

  void _loadCuisineData() async {
    final locationService = context.read<LocationService>();
    final apiService = context.read<ApiService>();
    final llmService = context.read<LlmService>();

    if (locationService.currentCity == 'Unknown') {
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    // First get cultural info for context
    final culturalInfo = await apiService.getCulturalInfo(
      locationService.currentCity,
      locationService.currentState,
    );

    // Then generate cuisine info using AI
    final cuisineInfo = await llmService.generateCuisineInfo(
      locationService.currentCity,
      locationService.currentState,
      culturalInfo?.culturalInfo,
    );

    if (cuisineInfo != null && mounted) {
      // Remove asterisks from the cuisine info
      final cleanedCuisineInfo = _removeAsterisks(cuisineInfo);
      setState(() {
        _cuisineInfo = cleanedCuisineInfo;
        _isGenerating = false;
      });
    } else if (mounted) {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  // Helper method to remove asterisks from text
  String _removeAsterisks(String text) {
    // Remove standalone asterisks used for bold formatting
    return text.replaceAll('**', '');
  }

  @override
  Widget build(BuildContext context) {
    final locationService = context.watch<LocationService>();
    final llmService = context.watch<LlmService>();
    final ttsService = context.watch<TtsService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Cuisine'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isGenerating ? null : _loadCuisineData,
          ),
        ],
      ),
      body: _buildContent(locationService, llmService, ttsService),
    );
  }

  Widget _buildContent(LocationService location, LlmService llm, TtsService tts) {
    if (_isGenerating || llm.isLoading) {
      return _buildLoadingState(location);
    }

    if (llm.error.isNotEmpty) {
      return _buildErrorState(llm, location);
    }

    if (_cuisineInfo == null) {
      return _buildEmptyState(location);
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

  Widget _buildLoadingState(LocationService location) {
    return Column(
      children: [
        _buildLocationCard(location),
        const Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Discovering local cuisine...'),
                SizedBox(height: 8),
                Text(
                  'Generating authentic food information for your location',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(LlmService llm, LocationService location) {
    return Column(
      children: [
        _buildLocationCard(location),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load cuisine data',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    llm.error,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadCuisineData,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(LocationService location) {
    return Column(
      children: [
        _buildLocationCard(location),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.restaurant, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No cuisine data available',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Generate local cuisine information for your current location',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadCuisineData,
                    child: const Text('Generate Cuisine Info'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Local Delicacies & Food Culture',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        tts.isSpeaking ? Icons.stop : Icons.volume_up,
                        color: tts.isSpeaking ? Colors.red : Colors.blue,
                      ),
                      onPressed: () {
                        if (tts.isSpeaking) {
                          tts.stop();
                        } else {
                          tts.speak(_cuisineInfo!);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _cuisineInfo!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildFoodTips(),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodTips() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🍽️ Food Experience Tips:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.orange[800],
            ),
          ),
          const SizedBox(height: 8),
          _buildTipItem('• Try local street food for authentic flavors'),
          _buildTipItem('• Visit traditional restaurants for classic dishes'),
          _buildTipItem('• Ask locals for their favorite food spots'),
          _buildTipItem('• Be adventurous with regional specialties'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}