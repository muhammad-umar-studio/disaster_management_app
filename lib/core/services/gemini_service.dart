import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_keys.dart';

class GeminiService {
  static final List<Map<String, dynamic>> _history = [];
  static bool _initialized = false;

  static const String _systemInstruction = '''
You are AEGIS, an expert emergency response and disaster management AI assistant.
Your purpose is to help people during natural disasters and emergencies.

Capabilities:
- Provide real-time disaster guidance (wildfires, floods, earthquakes, hurricanes)
- Give evacuation route recommendations
- Identify nearest safe zones and shelters
- Provide first aid and medical guidance
- Analyze weather data for disaster risk
- Help with emergency preparedness

Communication style:
- Be concise and clear — people may be in danger
- Use bullet points for actionable steps
- Prioritize life safety above all
- Always recommend calling 911/emergency services for immediate life-threatening situations
- Be calm and reassuring but direct

Context: The user is using the AEGIS disaster management app which monitors active disasters.
''';

  static Future<void> init() async {
    _history.clear();
    _initialized = true;
  }

  static Future<String> sendMessage(String userMessage) async {
    if (!_initialized) {
      await init();
    }

    String apiKeyToUse = ApiKeys.gemini.trim();
    // Sanitize key
    if ((apiKeyToUse.startsWith("'") && apiKeyToUse.endsWith("'")) ||
        (apiKeyToUse.startsWith('"') && apiKeyToUse.endsWith('"'))) {
      if (apiKeyToUse.length > 2) {
        apiKeyToUse = apiKeyToUse.substring(1, apiKeyToUse.length - 1).trim();
      }
    }

    // Append new user message to history
    _history.add({
      'role': 'user',
      'parts': [
        {'text': userMessage}
      ]
    });

    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKeyToUse');

    try {
      final payload = {
        'contents': _history,
        'systemInstruction': {
          'parts': [
            {'text': _systemInstruction}
          ]
        },
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 512,
        }
      };

      debugPrint('[Gemini] Sending payload to Gemini 2.5 Flash API...');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint('[Gemini] Error Response: ${response.body}');
        final errJson = jsonDecode(response.body);
        final errMsg = errJson['error']?['message'] ?? 'Unknown API error';
        
        // Remove the last added user message from history on failure so we don't pollute it
        if (_history.isNotEmpty) _history.removeLast();

        if (errMsg.contains('API_KEY_INVALID') || errMsg.contains('key') || response.statusCode == 400) {
          return '⚠️ Invalid Gemini API Key or the key is blocked. Please check your credentials.\nError: $errMsg';
        }
        return 'AI service error (${response.statusCode}): $errMsg';
      }

      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;

      if (text != null && text.isNotEmpty) {
        // Append model response to history
        _history.add({
          'role': 'model',
          'parts': [
            {'text': text}
          ]
        });
        return text;
      } else {
        if (_history.isNotEmpty) _history.removeLast();
        return 'I apologize, I could not generate a response. Please try again.';
      }
    } catch (e) {
      debugPrint('[Gemini] Exception during call: $e');
      if (_history.isNotEmpty) _history.removeLast();
      
      final estr = e.toString().toLowerCase();
      if (estr.contains('api_key') || estr.contains('invalid') || estr.contains('blocked')) {
        return '⚠️ The Gemini API key is invalid or blocked. Please verify the setup.';
      }
      return 'Connection error. Please check your internet and try again.';
    }
  }

  static Future<String> analyzeDisaster({
    required String type,
    required String location,
    required double riskScore,
    required String weatherCondition,
  }) async {
    final prompt = '''
Analyze this disaster situation and provide a brief, actionable safety assessment:
- Disaster type: $type
- Location: $location  
- AI Risk Score: ${riskScore.toInt()}%
- Current weather: $weatherCondition

Provide: 1) Immediate action (1 sentence), 2) Top 3 safety steps, 3) Evacuation recommendation.
Keep response under 150 words.
''';
    // For single assessments, we don't want to pollute or accumulate in the chat history.
    // Let's call a stateless generation:
    String apiKeyToUse = ApiKeys.gemini.trim();
    if ((apiKeyToUse.startsWith("'") && apiKeyToUse.endsWith("'")) ||
        (apiKeyToUse.startsWith('"') && apiKeyToUse.endsWith('"'))) {
      if (apiKeyToUse.length > 2) {
        apiKeyToUse = apiKeyToUse.substring(1, apiKeyToUse.length - 1).trim();
      }
    }

    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKeyToUse');

    try {
      final payload = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'systemInstruction': {
          'parts': [
            {'text': _systemInstruction}
          ]
        },
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 512,
        }
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return 'Disaster assessment temporarily unavailable.';
      }

      final data = jsonDecode(response.body);
      return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'Disaster assessment unavailable.';
    } catch (_) {
      return 'Disaster assessment unavailable due to connection issues.';
    }
  }

  static void clearHistory() {
    _history.clear();
  }
}
