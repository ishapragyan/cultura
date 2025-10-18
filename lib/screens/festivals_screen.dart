import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../services/tts_service.dart';
import '../models/city_info.dart';

class FestivalsScreen extends StatefulWidget {
  const FestivalsScreen({super.key});

  @override
  State<FestivalsScreen> createState() => _FestivalsScreenState();
}

class _FestivalsScreenState extends State<FestivalsScreen> {
  CityInfo? _currentCityInfo;

  @override
  void initState() {
    super.initState();
    _loadFestivalData();
  }

  void _loadFestivalData() async {
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
        title: const Text('Local Festivals'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFestivalData,
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
          _buildFestivalsCard(tts),
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
          Text('Discovering local festivals...'),
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
              'Unable to load festival data',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFestivalData,
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
            const Icon(Icons.celebration, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Festivals of',
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

  Widget _buildFestivalsCard(TtsService tts) {
    final festivalsInfo = _currentCityInfo?.festivals ?? 'Festival information not available for this location.';

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
                  'Cultural Celebrations',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: Icon(
                    tts.ttsState == TtsState.playing
                        ? Icons.volume_up
                        : Icons.volume_down,
                  ),
                  onPressed: () => tts.speak(festivalsInfo),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildFestivalsContent(festivalsInfo),
          ],
        ),
      ),
    );
  }

  Widget _buildFestivalsContent(String festivalsInfo) {
    if (festivalsInfo == 'Festival information not available for this location.') {
      return Column(
        children: [
          const Icon(Icons.celebration, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            festivalsInfo,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }

    // If we have actual festival data, format it nicely
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          festivalsInfo,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        _buildFestivalList(festivalsInfo),
      ],
    );
  }

  Widget _buildFestivalList(String festivalsInfo) {
    // Extract festival names from the text
    final festivals = _extractFestivalsFromText(festivalsInfo);

    if (festivals.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Major Festivals:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...festivals.map((festival) => _buildFestivalItem(festival)),
      ],
    );
  }

  Widget _buildFestivalItem(String festival) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.festival, color: Colors.green[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              festival,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _extractFestivalsFromText(String text) {
    // Simple extraction of potential festival names
    final festivalKeywords = [
      'ratha yatra', 'durga puja', 'diwali', 'holi', 'ganesh chaturthi',
      'pongal', 'onam', 'bihu', 'lohri', 'makar sankranti', 'navratri',
      'eid', 'christmas', 'guru purnima', 'rakhi', 'janmashtami'
    ];
    final foundFestivals = <String>[];

    for (final keyword in festivalKeywords) {
      if (text.toLowerCase().contains(keyword)) {
        foundFestivals.add(keyword.split(' ').map((word) =>
        word[0].toUpperCase() + word.substring(1)).join(' '));
      }
    }

    return foundFestivals.take(5).toList();
  }
}