import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tts_service.dart';
import '../services/llm_service.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';

class PhrasebookScreen extends StatefulWidget {
  const PhrasebookScreen({super.key});

  @override
  State<PhrasebookScreen> createState() => _PhrasebookScreenState();
}

class _PhrasebookScreenState extends State<PhrasebookScreen> {
  List<Phrase> _phrases = [];
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _generateLocalPhrases();
  }

  Future<void> _generateLocalPhrases() async {
    final locationService = context.read<LocationService>();
    final llmService = context.read<LlmService>();
    final apiService = context.read<ApiService>();

    if (locationService.currentCity == 'Unknown') {
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    // Get cultural info first to provide context to the AI
    final culturalInfo = await apiService.getCulturalInfo(
      locationService.currentCity,
      locationService.currentState,
    );

    final phrases = await llmService.generateLocalPhrases(
      locationService.currentCity,
      locationService.currentState,
      culturalInfo?.culturalInfo,
    );

    if (phrases != null && mounted) {
      setState(() {
        _phrases = phrases;
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
    final ttsService = context.watch<TtsService>();
    final locationService = context.watch<LocationService>();
    final llmService = context.watch<LlmService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Regional Phrasebook'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isGenerating ? null : _generateLocalPhrases,
          ),
        ],
      ),
      body: _buildContent(ttsService, locationService, llmService),
    );
  }

  Widget _buildContent(TtsService tts, LocationService location, LlmService llm) {
    if (_isGenerating || llm.isLoading) {
      return _buildLoadingState(location);
    }

    if (llm.error.isNotEmpty) {
      return _buildErrorState(llm, location);
    }

    if (_phrases.isEmpty) {
      return _buildEmptyState(location);
    }

    return Column(
      children: [
        _buildLocationHeader(location),
        Expanded(
          child: _buildPhraseList(tts),
        ),
      ],
    );
  }

  Widget _buildLoadingState(LocationService location) {
    return Column(
      children: [
        _buildLocationHeader(location),
        const Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generating local phrases...'),
                SizedBox(height: 8),
                Text(
                  'Creating authentic phrases for your location',
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
        _buildLocationHeader(location),
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
                    'Failed to generate phrases',
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
                    onPressed: _generateLocalPhrases,
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
        _buildLocationHeader(location),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.translate, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No phrases generated',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Generate local phrases for your current location',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _generateLocalPhrases,
                    child: const Text('Generate Phrases'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationHeader(LocationService location) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Local Phrases for',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Text(
                    location.currentCity,
                    style: Theme.of(context).textTheme.headlineSmall,
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

  Widget _buildPhraseList(TtsService tts) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _phrases.length,
      itemBuilder: (context, index) {
        final phrase = _phrases[index];
        return _buildPhraseCard(phrase, tts);
      },
    );
  }

  Widget _buildPhraseCard(Phrase phrase, TtsService tts) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        phrase.english,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phrase.local,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (phrase.localScript != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          phrase.localScript!,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontFamily: 'NotoSans',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    tts.isSpeaking ? Icons.stop : Icons.volume_up,
                    color: tts.isSpeaking ? Colors.red : Colors.blue,
                  ),
                  onPressed: () {
                    if (tts.isSpeaking) {
                      tts.stop();
                    } else {
                      tts.speak(phrase.local);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pronunciation: ${phrase.pronunciation}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Language: ${phrase.language}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}