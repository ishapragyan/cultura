import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LlmService with ChangeNotifier {
  // OpenRouter configuration for Mistral 7B (free tier)
  final String _openRouterApiKey = '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'; // Get from https://openrouter.ai/
  final String _model = 'mistralai/mistral-7b-instruct:free';
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
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openRouterApiKey',
          'HTTP-Referer': 'https://cultura-app.com', // Required by OpenRouter
          'X-Title': 'Cultura Cultural Explorer', // Required by OpenRouter
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
        return _cleanResponse(story);
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
        return _cleanResponse(summary);
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

  // Helper method to clean the response
  String _cleanResponse(String response) {
    // Remove any leading/trailing whitespace and quotes
    return response.trim().replaceAll(RegExp(r'^"|"$'), '');
  }
}