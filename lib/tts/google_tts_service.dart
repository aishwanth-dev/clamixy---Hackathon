import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GoogleTtsService {
  // For prototyping. Prefer securing keys via server or Dreamflow runtime config.
  static const String _apiKey = String.fromEnvironment(
    'GOOGLE_TTS_API_KEY',
    defaultValue: 'REPLACE_WITH_YOUR_GOOGLE_TTS_API_KEY',
  );

  // Standard Google Cloud TTS REST API (web-friendly)
  static const String _endpoint = 'https://texttospeech.googleapis.com/v1/text:synthesize';

  // Generate MP3 bytes for the given text using India English voice
  static Future<Uint8List> synthesize({
    required String text,
    String languageCode = 'en-IN',
    String voiceName = 'en-IN-Standard-A',
    double speakingRate = 1.0,
    double pitch = 0.0,
  }) async {
    final uri = Uri.parse('$_endpoint?key=$_apiKey');

    final body = {
      'input': {
        'text': text,
      },
      'voice': {
        'languageCode': languageCode,
        'name': voiceName,
      },
      'audioConfig': {
        'audioEncoding': 'MP3',
        'speakingRate': speakingRate,
        'pitch': pitch,
      }
    };

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final b64 = data['audioContent']?.toString();
      if (b64 != null && b64.isNotEmpty) {
        return base64Decode(b64);
      }
      throw Exception('TTS response missing audioContent');
    } else {
      throw Exception('TTS failed: ${res.statusCode} ${res.body}');
    }
  }
}
