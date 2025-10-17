import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LlmService with ChangeNotifier {
  final String _geminiApiKey = 'AIzaSyCWhSram4YqXqJdf0K0u6N9Nn_64qbgtY0'; // User should add their API key
  bool _isLoading = false;
  String _error = '';

  bool get isLoading => _isLoading;
  String get error => _error;

  Future<String?> generateStory(String city, String culturalInfo) async {
    if (_geminiApiKey.isEmpty) {
      _error = 'Please add your Gemini API key in Settings';
      notifyListeners();
      return null;
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
        Uri.parse('https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=$_geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 500,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final story = data['candidates'][0]['content']['parts'][0]['text'];
        return story;
      } else {
        _error = 'Failed to generate story: ${response.statusCode}';
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
    if (_geminiApiKey.isEmpty) {
      return 'Add your API key to generate AI summaries';
    }

    _isLoading = true;
    notifyListeners();

    try {
      final prompt = '''
Summarize this cultural journey across Indian cities and their heritage:

${visits.map((v) => "Visited ${v['city']} - ${v['keywords'].join(', ')}").join('\n')}

Create a beautiful, reflective summary of this cultural exploration in 100 words or less.
''';

      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=$_geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final summary = data['candidates'][0]['content']['parts'][0]['text'];
        return summary;
      } else {
        return 'Unable to generate summary. Check your API key.';
      }
    } catch (e) {
      return 'Error generating summary: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateApiKey(String newKey) {
    // In a real app, store this securely
    // _geminiApiKey = newKey;
    notifyListeners();
  }
}