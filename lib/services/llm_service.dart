import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LlmService with ChangeNotifier {
  // Replace with your actual Gemini API key
  final String _geminiApiKey = 'AIzaSyCWhSram4YqXqJdf0K0u6N9Nn_64qbgtY0'; // Your actual API key here
  bool _isLoading = false;
  String _error = '';

  bool get isLoading => _isLoading;
  String get error => _error;

  Future<String?> generateStory(String city, String culturalInfo) async {
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
            'maxOutputTokens': 300,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final summary = data['candidates'][0]['content']['parts'][0]['text'];
        return summary;
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

// Remove the API key settings since it's hardcoded now
// void updateApiKey(String newKey) {}
}