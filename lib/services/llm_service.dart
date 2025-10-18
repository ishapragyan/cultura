import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LlmService with ChangeNotifier {
  // OpenRouter configuration for Mistral 7B (free tier)
  final String _openRouterApiKey = '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';
  final String _model = 'mistralai/mistral-7b-instruct:free';
  bool _isLoading = false;
  String _error = '';

  // Cache storage
  final Map<String, String> _storyCache = {};
  final Map<String, String> _summaryCache = {};
  final Map<String, List<Phrase>> _phrasesCache = {};

  bool get isLoading => _isLoading;
  String get error => _error;

  Future<String?> generateStory(String city, String culturalInfo) async {
    final cacheKey = 'story_${city}_${culturalInfo.hashCode}';

    if (_storyCache.containsKey(cacheKey)) {
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

        _storyCache[cacheKey] = cleanedStory;
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

  Future<String?> generateJourneySummary(List<Map<String, dynamic>> visits) async {
    final visitsHash = visits.fold<int>(0, (hash, visit) {
      return hash ^ visit['city'].hashCode ^ visit['keywords'].join().hashCode;
    });
    final cacheKey = 'summary_$visitsHash';

    if (_summaryCache.containsKey(cacheKey)) {
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

        _summaryCache[cacheKey] = cleanedSummary;
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

  // NEW METHOD: Generate local phrases based on city and state
  Future<List<Phrase>?> generateLocalPhrases(String city, String state, String? culturalInfo) async {
    final cacheKey = 'phrases_${city}_$state';

    if (_phrasesCache.containsKey(cacheKey)) {
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

            _phrasesCache[cacheKey] = phrases;
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

  // Fallback phrases in case API fails
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

  // Clear cache methods
  void clearStoryCache() {
    _storyCache.clear();
    notifyListeners();
  }

  void clearSummaryCache() {
    _summaryCache.clear();
    notifyListeners();
  }

  void clearPhrasesCache() {
    _phrasesCache.clear();
    notifyListeners();
  }

  void clearAllCache() {
    _storyCache.clear();
    _summaryCache.clear();
    _phrasesCache.clear();
    notifyListeners();
  }

  String _cleanResponse(String response) {
    return response.trim().replaceAll(RegExp(r'^"|"$'), '');
  }
}

// Phrase model class
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
