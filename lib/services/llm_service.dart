import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LlmService with ChangeNotifier {
  // OpenRouter configuration for Mistral 7B (free tier)
  final String _openRouterApiKey = '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';
  final String _model = 'mistralai/mistral-7b-instruct:free';
  bool _isLoading = false;
  String _error = '';

  // Complete cache storage for all features
  final Map<String, String> _storyCache = {};
  final Map<String, String> _summaryCache = {};
  final Map<String, List<Phrase>> _phrasesCache = {};
  final Map<String, String> _cuisineCache = {};
  final Map<String, String> _festivalsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheDuration = const Duration(hours: 24);

  bool get isLoading => _isLoading;
  String get error => _error;

  // STORY GENERATION with Cache
  Future<String?> generateStory(String city, String culturalInfo) async {
    final cacheKey = 'story_${city}_${culturalInfo.hashCode}';

    if (_isValidCache(cacheKey) && _storyCache.containsKey(cacheKey)) {
      return _storyCache[cacheKey];
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final prompt = '''
Based on this information about $city: "$culturalInfo"

Generate a short 150-word folk-style story or legend written in an engaging narrative tone. Make it culturally authentic and captivating.
''';

      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openRouterApiKey',
          'HTTP-Referer': 'https://cultura-app.com',
          'X-Title': 'Cultura Cultural Explorer',
        },
        body: json.encode({
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final story = data['choices'][0]['message']['content'];
        final cleanedStory = _cleanResponse(story);

        // Cache the result
        _storyCache[cacheKey] = cleanedStory;
        _cacheTimestamps[cacheKey] = DateTime.now();

        return cleanedStory;
      } else {
        final errorData = json.decode(response.body);
        _error = 'Failed to generate story: ${errorData['error']['message'] ?? response.statusCode}';
        return null;
      }
    } catch (e) {
      _error = 'Error generating story: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // CUISINE GENERATION with Cache
  Future<String?> generateCuisineInfo(String city, String state, String? culturalInfo) async {
    final cacheKey = 'cuisine_${city}_$state';

    if (_isValidCache(cacheKey) && _cuisineCache.containsKey(cacheKey)) {
      return _cuisineCache[cacheKey];
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final prompt = '''
For the city $city in $state, India, generate detailed information about the local cuisine and food culture.

${culturalInfo != null ? "Context about the city: $culturalInfo" : ""}

Please provide comprehensive information about:
1. Signature dishes and specialties
2. Unique ingredients and cooking techniques
3. Street food culture
4. Traditional meals and eating habits
5. Cultural significance of food
6. Must-try local delicacies

Make it informative, engaging, and around 200-250 words. Focus on authentic local cuisine.
''';

      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openRouterApiKey',
          'HTTP-Referer': 'https://cultura-app.com',
          'X-Title': 'Cultura Cultural Explorer',
        },
        body: json.encode({
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': 600,
          'temperature': 0.6,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final cuisineInfo = data['choices'][0]['message']['content'];
        final cleanedInfo = _cleanResponse(cuisineInfo);

        // Cache the result
        _cuisineCache[cacheKey] = cleanedInfo;
        _cacheTimestamps[cacheKey] = DateTime.now();

        return cleanedInfo;
      } else {
        final errorData = json.decode(response.body);
        _error = 'Failed to generate cuisine info: ${errorData['error']['message'] ?? response.statusCode}';
        return _getFallbackCuisine(city, state);
      }
    } catch (e) {
      _error = 'Error generating cuisine info: $e';
      return _getFallbackCuisine(city, state);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // FESTIVALS GENERATION with Cache
  Future<String?> generateFestivalsInfo(String city, String state, String? culturalInfo) async {
    final cacheKey = 'festivals_${city}_$state';

    if (_isValidCache(cacheKey) && _festivalsCache.containsKey(cacheKey)) {
      return _festivalsCache[cacheKey];
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final prompt = '''
For the city $city in $state, India, generate detailed information about local festivals, celebrations, and cultural events.

${culturalInfo != null ? "Context about the city: $culturalInfo" : ""}

Please provide comprehensive information about:
1. Major religious and cultural festivals
2. Unique local celebrations and traditions
3. Festival dates and significance
4. Traditional rituals and customs
5. Community participation and celebrations
6. Special foods and activities during festivals

Make it informative, engaging, and around 200-250 words. Focus on authentic local traditions.
''';

      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openRouterApiKey',
          'HTTP-Referer': 'https://cultura-app.com',
          'X-Title': 'Cultura Cultural Explorer',
        },
        body: json.encode({
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': 600,
          'temperature': 0.6,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final festivalsInfo = data['choices'][0]['message']['content'];
        final cleanedInfo = _cleanResponse(festivalsInfo);

        // Cache the result
        _festivalsCache[cacheKey] = cleanedInfo;
        _cacheTimestamps[cacheKey] = DateTime.now();

        return cleanedInfo;
      } else {
        final errorData = json.decode(response.body);
        _error = 'Failed to generate festivals info: ${errorData['error']['message'] ?? response.statusCode}';
        return _getFallbackFestivals(city, state);
      }
    } catch (e) {
      _error = 'Error generating festivals info: $e';
      return _getFallbackFestivals(city, state);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // PHRASEBOOK GENERATION with Cache
  Future<List<Phrase>?> generateLocalPhrases(String city, String state, String? culturalInfo) async {
    final cacheKey = 'phrases_${city}_$state';

    if (_isValidCache(cacheKey) && _phrasesCache.containsKey(cacheKey)) {
      return _phrasesCache[cacheKey];
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final prompt = '''
For the city $city in $state, India, generate 8-10 essential local phrases that travelers should know.

${culturalInfo ?? ''}

Please provide the phrases in this exact JSON format:
{
  "phrases": [
    {
      "english": "English phrase",
      "local": "Local language phrase", 
      "localScript": "Text in local script if applicable",
      "language": "Name of local language",
      "pronunciation": "English pronunciation guide"
    }
  ]
}

Include these essential categories:
1. Greetings
2. Thank you
3. Basic questions (How are you?, What is your name?)
4. Directions
5. Food-related phrases
6. Numbers 1-5
7. Emergency phrases
8. Cultural courtesy phrases

Make sure the phrases are authentic to the local language and culture of $city, $state.
''';

      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openRouterApiKey',
          'HTTP-Referer': 'https://cultura-app.com',
          'X-Title': 'Cultura Cultural Explorer',
        },
        body: json.encode({
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': 800,
          'temperature': 0.5,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'];

        // Extract JSON from the response
        final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(content);
        if (jsonMatch != null) {
          final jsonString = jsonMatch.group(0);
          if (jsonString != null) {
            final phrasesData = json.decode(jsonString);
            final phrasesList = phrasesData['phrases'] as List;

            final phrases = phrasesList.map((phraseJson) {
              return Phrase(
                english: phraseJson['english']?.toString() ?? '',
                local: phraseJson['local']?.toString() ?? '',
                localScript: phraseJson['localScript']?.toString(),
                language: phraseJson['language']?.toString() ?? 'Local Language',
                pronunciation: phraseJson['pronunciation']?.toString() ?? '',
              );
            }).toList();

            // Cache the result
            _phrasesCache[cacheKey] = phrases;
            _cacheTimestamps[cacheKey] = DateTime.now();

            return phrases;
          }
        }
        _error = 'Could not parse phrases from AI response';
        return _getFallbackPhrases(city, state);
      } else {
        _error = 'Failed to generate phrases: ${response.statusCode}';
        return _getFallbackPhrases(city, state);
      }
    } catch (e) {
      _error = 'Error generating phrases: $e';
      return _getFallbackPhrases(city, state);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // JOURNEY SUMMARY with Cache
  Future<String?> generateJourneySummary(List<Map<String, dynamic>> visits) async {
    final visitsHash = visits.fold<int>(0, (hash, visit) {
      return hash ^ visit['city'].hashCode ^ visit['keywords'].join().hashCode;
    });
    final cacheKey = 'summary_$visitsHash';

    if (_isValidCache(cacheKey) && _summaryCache.containsKey(cacheKey)) {
      return _summaryCache[cacheKey];
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final prompt = '''
Summarize this cultural journey across Indian cities and their heritage:

${visits.map((v) => "Visited ${v['city']} - ${v['keywords'].join(', ')}").join('\n')}

Create a beautiful, reflective summary of this cultural exploration in 100 words or less.
''';

      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openRouterApiKey',
          'HTTP-Referer': 'https://cultura-app.com',
          'X-Title': 'Cultura Cultural Explorer',
        },
        body: json.encode({
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': 300,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final summary = data['choices'][0]['message']['content'];
        final cleanedSummary = _cleanResponse(summary);

        // Cache the result
        _summaryCache[cacheKey] = cleanedSummary;
        _cacheTimestamps[cacheKey] = DateTime.now();

        return cleanedSummary;
      } else {
        final errorData = json.decode(response.body);
        _error = 'Failed to generate summary: ${errorData['error']['message'] ?? response.statusCode}';
        return null;
      }
    } catch (e) {
      _error = 'Error generating summary: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cache validation
  bool _isValidCache(String cacheKey) {
    if (!_cacheTimestamps.containsKey(cacheKey)) {
      return false;
    }

    final timestamp = _cacheTimestamps[cacheKey]!;
    final now = DateTime.now();
    return now.difference(timestamp) < _cacheDuration;
  }

  // Fallback methods
  String _getFallbackCuisine(String city, String state) {
    return '''
Discover the authentic flavors of $city, $state! This region offers a unique culinary heritage with traditional dishes passed down through generations. 

Local cuisine typically features a blend of aromatic spices, fresh local ingredients, and traditional cooking methods. From street food delights to festive specialties, the food culture here reflects the rich cultural tapestry of the region.

Must-try dishes often include traditional breads, flavorful curries, sweet delicacies, and unique local specialties that you won't find anywhere else in India. The cuisine tells the story of the land and its people through every bite.
''';
  }

  String _getFallbackFestivals(String city, String state) {
    return '''
Experience the vibrant festival culture of $city, $state! This region celebrates a rich calendar of cultural and religious festivals throughout the year.

Local festivals typically include major Hindu celebrations, regional harvest festivals, and unique local traditions that have been preserved for centuries. Communities come together with colorful processions, traditional music, dance performances, and elaborate decorations.

The festivals reflect the deep spiritual and cultural roots of the region, offering visitors a chance to witness authentic traditions and participate in joyful celebrations that showcase the local way of life.
''';
  }

  List<Phrase> _getFallbackPhrases(String city, String state) {
    return [
      Phrase(
        english: "Hello",
        local: "Namaste",
        localScript: "नमस्ते",
        language: "Hindi",
        pronunciation: "nuh-muh-stay",
      ),
      Phrase(
        english: "Thank you",
        local: "Dhanyavaad",
        localScript: "धन्यवाद",
        language: "Hindi",
        pronunciation: "dhun-yuh-vaad",
      ),
      Phrase(
        english: "How are you?",
        local: "Aap kaise hain?",
        localScript: "आप कैसे हैं?",
        language: "Hindi",
        pronunciation: "aap kai-se hain",
      ),
      Phrase(
        english: "What is your name?",
        local: "Aapka naam kya hai?",
        localScript: "आपका नाम क्या है?",
        language: "Hindi",
        pronunciation: "aap-ka naam kya hai",
      ),
      Phrase(
        english: "I don't understand",
        local: "Mujhe samajh nahi aaya",
        localScript: "मुझे समझ नहीं आया",
        language: "Hindi",
        pronunciation: "muj-he su-mujh na-hee a-ya",
      ),
    ];
  }

  // Cache management methods
  void clearStoryCache() {
    _storyCache.clear();
    _cacheTimestamps.removeWhere((key, value) => key.startsWith('story_'));
    notifyListeners();
  }

  void clearCuisineCache() {
    _cuisineCache.clear();
    _cacheTimestamps.removeWhere((key, value) => key.startsWith('cuisine_'));
    notifyListeners();
  }

  void clearFestivalsCache() {
    _festivalsCache.clear();
    _cacheTimestamps.removeWhere((key, value) => key.startsWith('festivals_'));
    notifyListeners();
  }

  void clearPhrasesCache() {
    _phrasesCache.clear();
    _cacheTimestamps.removeWhere((key, value) => key.startsWith('phrases_'));
    notifyListeners();
  }

  void clearSummaryCache() {
    _summaryCache.clear();
    _cacheTimestamps.removeWhere((key, value) => key.startsWith('summary_'));
    notifyListeners();
  }

  void clearAllCache() {
    _storyCache.clear();
    _cuisineCache.clear();
    _festivalsCache.clear();
    _phrasesCache.clear();
    _summaryCache.clear();
    _cacheTimestamps.clear();
    notifyListeners();
  }

  // Cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'storyCache': _storyCache.length,
      'cuisineCache': _cuisineCache.length,
      'festivalsCache': _festivalsCache.length,
      'phrasesCache': _phrasesCache.length,
      'summaryCache': _summaryCache.length,
      'totalCache': _cacheTimestamps.length,
    };
  }

  String _cleanResponse(String response) {
    return response.trim().replaceAll(RegExp(r'^"|"$'), '');
  }
}

class Phrase {
  final String english;
  final String local;
  final String? localScript;
  final String language;
  final String pronunciation;

  Phrase({
    required this.english,
    required this.local,
    this.localScript,
    required this.language,
    required this.pronunciation,
  });

  factory Phrase.fromJson(Map<String, dynamic> json) {
    return Phrase(
      english: json['english']?.toString() ?? '',
      local: json['local']?.toString() ?? '',
      localScript: json['localScript']?.toString(),
      language: json['language']?.toString() ?? 'Local Language',
      pronunciation: json['pronunciation']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'english': english,
      'local': local,
      'localScript': localScript,
      'language': language,
      'pronunciation': pronunciation,
    };
  }
}