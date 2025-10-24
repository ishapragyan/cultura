import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../services/llm_service.dart';
import '../services/tts_service.dart';
import '../services/api_service.dart';

class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  String? _generatedStory;

  @override
  Widget build(BuildContext context) {
    final locationService = context.watch<LocationService>();
    final llmService = context.watch<LlmService>();
    final ttsService = context.watch<TtsService>();
    final apiService = context.watch<ApiService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Folk Stories'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLocationHeader(locationService),
            const SizedBox(height: 20),
            _buildGenerateButton(locationService, llmService, apiService),
            const SizedBox(height: 20),
            _buildStoryContent(llmService, ttsService, locationService),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationHeader(LocationService location) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.auto_stories, color: Colors.purple),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Folk Stories from',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Text(
                    location.currentCity,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton(
      LocationService location,
      LlmService llm,
      ApiService api,
      ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: llm.isLoading
            ? const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : const Icon(Icons.auto_awesome),
        label: Text(llm.isLoading ? 'Generating Story...' : 'Generate Folk Story'),
        onPressed: llm.isLoading
            ? null
            : () async {
          if (location.currentCity == 'Unknown') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location not available')),
            );
            return;
          }

          final culturalInfo = await api.getCulturalInfo(
            location.currentCity,
            location.currentState,
          );

          if (culturalInfo != null) {
            final story = await llm.generateStory(
              location.currentCity,
              culturalInfo.culturalInfo ?? '',
            );

            if (story != null) {
              setState(() {
                _generatedStory = story;
              });
            }
          }
        },
      ),
    );
  }

  Widget _buildStoryContent(LlmService llm, TtsService tts, LocationService location) {
    if (llm.error.isNotEmpty) {
      return Card(
        color: Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(height: 8),
              Text(
                'Error: ${llm.error}',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_generatedStory == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(Icons.auto_stories, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Generate a folk story inspired by your current location',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The Legend of ${location.currentCity}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        tts.isSpeaking ? Icons.stop : Icons.play_arrow,
                        color: tts.isSpeaking ? Colors.red : Colors.green,
                      ),
                      onPressed: () {
                        if (tts.isSpeaking) {
                          tts.stop();
                        } else {
                          tts.speak(_generatedStory!);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _generatedStory!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}