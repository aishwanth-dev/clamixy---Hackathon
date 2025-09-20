import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stardust_soul/models.dart' as local;

class GeminiService {
  // You can move this key to a secure runtime config. For now we honor the provided key for prototyping.
  static const String _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AIzaSyC_meFvwj7O-r_vH-s9OaM8VnLGUFY1478',
  );

  static const String _base = 'https://generativelanguage.googleapis.com/v1beta';
  static const String _chatModel = 'models/gemini-1.5-flash';

  static Future<String> generateChatResponse({
    required String message,
    String? moodContext,
  }) async {
    final system = _chatSafetyPreamble(moodContext: moodContext);

    final uri = Uri.parse('$_base/$_chatModel:generateContent?key=$_apiKey');
    final body = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': system},
            {'text': '\nUser: $message'}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'topP': 0.9,
        'topK': 40,
        'maxOutputTokens': 350,
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
        {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_NONE'},
        {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_NONE'},
      ],
    };

    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates.first['content']?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            return parts.map((p) => p['text']?.toString() ?? '').join().trim();
          }
        }
      }
    } catch (_) {}

    return _fallbackResponse(message);
  }

  // New: history-aware chat, ChatGPT-style context
  static Future<String> generateChatResponseWithHistory({
    required List<local.ChatMessage> history,
    required String message,
    String? moodContext,
  }) async {
    final system = _chatSafetyPreamble(moodContext: moodContext);

    // Build contents with past turns (limit to last 20 to stay light)
    final trimmed = history.length > 20 ? history.sublist(history.length - 20) : history;
    final contents = <Map<String, dynamic>>[];

    // Add preamble as the first user message
    contents.add({
      'role': 'user',
      'parts': [
        {'text': system},
      ]
    });

    for (final msg in trimmed) {
      contents.add({
        'role': msg.isUser ? 'user' : 'model',
        'parts': [
          {'text': msg.content},
        ]
      });
    }

    // Add the new user message
    contents.add({
      'role': 'user',
      'parts': [
        {'text': message},
      ]
    });

    final uri = Uri.parse('$_base/$_chatModel:generateContent?key=$_apiKey');
    final body = {
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'topP': 0.9,
        'topK': 40,
        'maxOutputTokens': 350,
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
        {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_NONE'},
        {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_NONE'},
      ],
    };

    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates.first['content']?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            return parts.map((p) => p['text']?.toString() ?? '').join().trim();
          }
        }
      }
    } catch (_) {}

    return _fallbackResponse(message);
  }

  static Future<Map<String, dynamic>> generateReliefPackageFromMessage(String message) async {
    final uri = Uri.parse('$_base/$_chatModel:generateContent?key=$_apiKey');

    final prompt = '''You create short, practical, positive 5-step relief packages for teens and young adults.
Return strict JSON with this shape:
{
  "mood": "anger|stress|anxiety|sadness|calm|other",
  "title": "string",
  "points": number,
  "steps": [
    {"type":"breathing","title":"string","durationSec":40,"instruction":"string"},
    {"type":"mindfulness","title":"string","durationSec":120,"instruction":"string"},
    {"type":"activity","title":"string","durationSec":120,"instruction":"string"},
    {"type":"journaling","title":"string","durationSec":90,"instruction":"string"},
    {"type":"reflection","title":"string","durationSec":60,"instruction":"string"}
  ]
}
Rules: be supportive, culturally sensitive for India, no judgment, no negative language.''';

    final body = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
            {'text': '\nUser mood/problem: $message'}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.6,
        'maxOutputTokens': 500,
        'response_mime_type': 'application/json',
      },
    };

    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final text = (data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '').toString();
        if (text.isNotEmpty) {
          return jsonDecode(text) as Map<String, dynamic>;
        }
      }
    } catch (_) {}

    // fallback simple package
    return {
      'mood': 'other',
      'title': 'Reset in 5 Steps',
      'points': 20,
      'steps': [
        {
          'type': 'breathing',
          'title': '4-4-6 Breathing',
          'durationSec': 40,
          'instruction': 'Inhale 4 • Hold 4 • Exhale 6. Repeat until timer ends.'
        },
        {
          'type': 'mindfulness',
          'title': 'Calm Memory',
          'durationSec': 120,
          'instruction': 'Think of a safe, soothing place. Notice 3 sights, 2 sounds, 1 scent.'
        },
        {
          'type': 'activity',
          'title': 'Move It',
          'durationSec': 120,
          'instruction': 'Stand, roll shoulders, stretch arms, take 20 slow steps.'
        },
        {
          'type': 'journaling',
          'title': 'Name It',
          'durationSec': 90,
          'instruction': 'Write 2–3 lines: What I feel, why I might feel it, one gentle thing I can do next.'
        },
        {
          'type': 'reflection',
          'title': 'Check-in',
          'durationSec': 60,
          'instruction': 'Close eyes and ask: Do I feel a little lighter? Rate 1–5.'
        }
      ]
    };
  }

  static Future<String> generateUpliftingStory({required String prompt}) async {
    final uri = Uri.parse('$_base/$_chatModel:generateContent?key=$_apiKey');

    final system = '''Create a positive, calming story of at least 5 minutes of reading (~700+ words), tailored to the given mood/problem.
Embed simple mini-exercises naturally inside the story (breathing, gentle stretch, mindful noticing).
Tone: warm, supportive, youth-friendly, India-aware. Avoid negative or judgmental language.''';

    final body = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': system},
            {'text': '\nMood/problem: $prompt'}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.8,
        'topP': 0.9,
        'maxOutputTokens': 1600,
      },
    };

    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates.first['content']?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            return parts.map((p) => p['text']?.toString() ?? '').join().trim();
          }
        }
      }
    } catch (_) {}

    return _fallbackStory(prompt);
  }

  static String _chatSafetyPreamble({String? moodContext}) {
    final ctx = moodContext != null ? '\nMood context: $moodContext' : '';
    return '''You are Calmixy – a single, empathetic, positive-only AI companion for youth.
- Always validate feelings; be kind, brief, and practical.
- Suggest coping skills when relevant (breathing, grounding, journaling).
- If crisis or self-harm is hinted, gently suggest helplines without panic.
- Avoid negative, abusive, or judgmental language. Only positive, supportive tone.
$ctx''';
  }

  static String _fallbackResponse(String message) {
    return "I hear you. Thank you for sharing this with me. Take a slow breath with me now – inhale 4, hold 4, exhale 6. If you'd like, tell me a little more about what's going on.";
  }

  static String _fallbackStory(String prompt) {
    return "Under a soft evening sky, you find a quiet bench beneath a neem tree... (offline calming story placeholder).";
  }
}
