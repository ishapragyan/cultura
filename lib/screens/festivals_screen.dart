import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../services/llm_service.dart';
import '../services/tts_service.dart';

class FestivalsScreen extends StatefulWidget {
  const FestivalsScreen({super.key});

  @override
  State<FestivalsScreen> createState() => _FestivalsScreenState();
}

class _FestivalsScreenState extends State<FestivalsScreen> {
  String? _festivalsInfo;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadFestivalsData();
  }

  void _loadFestivalsData() async {
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

    // Then generate festivals info using AI
    final festivalsInfo = await llmService.generateFestivalsInfo(
      locationService.currentCity,
      locationService.currentState,
      culturalInfo?.culturalInfo,
    );

    if (festivalsInfo != null && mounted) {
      setState(() {
        _festivalsInfo = festivalsInfo;
        _isGenerating = false;
      });
    } else if (mounted) {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationService = context.watch<LocationService>();
    final llmService = context.watch<LlmService>();
    final ttsService = context.watch<TtsService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Festivals'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isGenerating ? null : _loadFestivalsData,
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

    if (_festivalsInfo == null) {
      return _buildEmptyState(location);
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
                Text('Discovering local festivals...'),
                SizedBox(height: 8),
                Text(
                  'Generating authentic festival information for your location',
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
                    'Failed to load festival data',
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
                    onPressed: _loadFestivalsData,
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
                  const Icon(Icons.celebration, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No festival data available',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Generate local festival information for your current location',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadFestivalsData,
                    child: const Text('Generate Festival Info'),
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
                  'Cultural Celebrations & Festivals',
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
                          tts.speak(_festivalsInfo!);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _festivalsInfo!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildFestivalTips(),
          ],
        ),
      ),
    );
  }

  Widget _buildFestivalTips() {
    return Container(
      width: double.infinity, // Ensure it takes full width
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎉 Festival Experience Tips:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
          const SizedBox(height: 8),
          _buildTipItem('• Respect local customs and traditions'),
          _buildTipItem('• Dress appropriately for religious sites'),
          _buildTipItem('• Ask before taking photos during ceremonies'),
          _buildTipItem('• Try festival-specific foods and sweets'),
          _buildTipItem('• Participate in community celebrations'),
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