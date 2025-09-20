import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stardust_soul/models.dart';

class OpenAIService {
  static const String apiKey = String.fromEnvironment('OPENAI_PROXY_API_KEY');
  static const String endpoint = String.fromEnvironment('OPENAI_PROXY_ENDPOINT');

  static Future<String> getChatResponse({
    required String message,
    required AiRole role,
    String? moodContext,
    List<ChatMessage>? conversationHistory,
  }) async {
    try {
      final systemPrompt = _getSystemPrompt(role, moodContext);
      final messages = _buildMessageHistory(systemPrompt, message, conversationHistory);

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': messages,
          'max_tokens': 300,
          'temperature': 0.8,
          'presence_penalty': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        return _getOfflineFallback(role, message);
      }
    } catch (e) {
      return _getOfflineFallback(role, message);
    }
  }

  static Future<String> generateDailyReflection({
    required MoodEntry moodEntry,
  }) async {
    try {
      final prompt = _getReflectionPrompt(moodEntry);
      
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'system', 'content': prompt},
            {'role': 'user', 'content': 'Generate a reflection for this mood entry.'},
          ],
          'max_tokens': 150,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        return _getReflectionFallback(moodEntry.emotion);
      }
    } catch (e) {
      return _getReflectionFallback(moodEntry.emotion);
    }
  }

  static Future<List<WellnessChallenge>> generateWeeklyChallenges({
    required UserProgress progress,
    required List<MoodEntry> recentMoods,
  }) async {
    try {
      final prompt = _getChallengePrompt(progress, recentMoods);
      
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'o3-mini',
          'messages': [
            {'role': 'system', 'content': prompt},
            {'role': 'user', 'content': 'Generate 3 personalized wellness challenges based on this data.'},
          ],
          'max_tokens': 400,
          'temperature': 0.6,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        return _parseChallengesFromJson(content);
      } else {
        return _getFallbackChallenges();
      }
    } catch (e) {
      return _getFallbackChallenges();
    }
  }

  static String _getSystemPrompt(AiRole role, String? moodContext) {
    final basePrompt = '''You are a compassionate AI wellness companion for young people in India. 
Always be supportive, culturally sensitive, and age-appropriate. Keep responses concise but meaningful.
Detect if someone mentions self-harm, suicide, or crisis situations and gently suggest professional help.''';

    final moodContextPrompt = moodContext != null 
        ? '\n\nCurrent mood context: $moodContext' 
        : '';

    switch (role) {
      case AiRole.listener:
        return '''$basePrompt

You are the Listener 🌸 - gentle, empathetic, and focused on validation.
- Ask follow-up questions to understand deeper
- Validate emotions without judgment  
- Offer gentle breathing exercises or mindfulness when appropriate
- Use warm, caring language$moodContextPrompt''';

      case AiRole.motivator:
        return '''$basePrompt

You are the Motivator ⚡ - energetic, encouraging, and uplifting.
- Focus on strengths and possibilities
- Share positive affirmations
- Suggest small actionable steps
- Use encouraging, energetic language
- Help reframe challenges as opportunities$moodContextPrompt''';

      case AiRole.coach:
        return '''$basePrompt

You are the Coach 🎯 - strategic, goal-oriented, and solution-focused.
- Help break down problems into manageable steps
- Suggest practical coping strategies
- Focus on goal-setting and progress tracking
- Ask questions that promote self-reflection
- Provide structured approaches to challenges$moodContextPrompt''';
    }
  }

  static List<Map<String, String>> _buildMessageHistory(
    String systemPrompt, 
    String currentMessage, 
    List<ChatMessage>? history,
  ) {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    // Add recent conversation history (last 10 messages for context)
    if (history != null) {
      final recentMessages = history.length > 10 
          ? history.sublist(history.length - 10) 
          : history;
      
      for (final msg in recentMessages) {
        messages.add({
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.content,
        });
      }
    }

    messages.add({'role': 'user', 'content': currentMessage});
    return messages;
  }

  static String _getReflectionPrompt(MoodEntry moodEntry) {
    return '''Generate a personalized, encouraging reflection for a young person's mood entry.

Mood: ${moodEntry.emotion.name} ${moodEntry.emotion.emoji}
Intensity: ${moodEntry.intensity}/5
Note: ${moodEntry.note}
Date: ${moodEntry.date.toString().split(' ')[0]}

Guidelines:
- Keep it to 1-2 sentences, warm and supportive
- Acknowledge their emotion as valid
- Offer gentle insight or encouragement
- Be culturally sensitive for Indian youth
- Avoid being preachy or overly clinical''';
  }

  static String _getChallengePrompt(UserProgress progress, List<MoodEntry> recentMoods) {
    final dominantEmotions = progress.emotionCounts.entries
        .where((e) => e.value > 0)
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

    return '''Generate 3 personalized wellness challenges for a young person based on their data.

Current Progress:
- Current streak: ${progress.currentStreak} days
- Total points: ${progress.totalPoints}
- Total mood entries: ${progress.totalStars}

Recent emotional patterns: ${dominantEmotions.take(3).map((e) => '${e.key.name} (${e.value} times)').join(', ')}

Requirements:
- Each challenge should be achievable in 1 week
- Points between 30-80 based on difficulty  
- Be specific and actionable
- Consider their current emotional state
- Make it engaging for young people

Return as JSON object with this exact format:
{
  "challenges": [
    {
      "title": "Challenge Title",
      "description": "Specific description of what to do",
      "points": 50
    }
  ]
}''';
  }

  static List<WellnessChallenge> _parseChallengesFromJson(String jsonContent) {
    try {
      final data = jsonDecode(jsonContent);
      final challengesList = data['challenges'] as List;
      
      return challengesList.asMap().entries.map((entry) {
        final index = entry.key;
        final challenge = entry.value;
        
        return WellnessChallenge(
          id: DateTime.now().millisecondsSinceEpoch.toString() + index.toString(),
          title: challenge['title'],
          description: challenge['description'],
          points: challenge['points'],
          deadline: DateTime.now().add(const Duration(days: 7)),
        );
      }).toList();
    } catch (e) {
      return _getFallbackChallenges();
    }
  }

  static String _getOfflineFallback(AiRole role, String message) {
    switch (role) {
      case AiRole.listener:
        return "I hear you, and your feelings are completely valid. Sometimes just expressing what's on your mind can be the first step toward feeling better. Would you like to share more about what's going on?";
      
      case AiRole.motivator:
        return "You know what? Just by reaching out and sharing your thoughts, you're already showing incredible strength! 💪 Every small step counts, and you're capable of more than you realize. What's one tiny thing that made you smile recently?";
      
      case AiRole.coach:
        return "Let's break this down together. When we organize our thoughts, challenges become more manageable. What's the most important thing you'd like to focus on right now? We can create a simple plan to move forward step by step.";
    }
  }

  static String _getReflectionFallback(Emotion emotion) {
    switch (emotion) {
      case Emotion.happy:
        return "Your happiness today is a reminder of all the good things life has to offer. Hold onto this feeling! ✨";
      case Emotion.sad:
        return "It's okay to feel sad sometimes. These feelings show your depth and compassion. Tomorrow brings new possibilities.";
      case Emotion.angry:
        return "Your anger shows you care deeply about something. Channel this energy into positive action when you're ready.";
      case Emotion.calm:
        return "This peaceful moment is your inner strength showing. Return to this calm whenever you need grounding.";
      case Emotion.anxious:
        return "Anxiety means you care. Take a deep breath - you have more control than you realize right now.";
      case Emotion.excited:
        return "Your excitement is contagious! This energy shows your passion for life. Embrace these joyful moments!";
      case Emotion.neutral:
        return "Steady, calm days are just as important as exciting ones. You're exactly where you need to be right now.";
    }
  }

  static List<WellnessChallenge> _getFallbackChallenges() {
    final now = DateTime.now();
    return [
      WellnessChallenge(
        id: '${now.millisecondsSinceEpoch}1',
        title: 'Gratitude Galaxy',
        description: 'Write down 3 things you\'re grateful for each day for 5 days',
        points: 50,
        deadline: now.add(const Duration(days: 7)),
      ),
      WellnessChallenge(
        id: '${now.millisecondsSinceEpoch}2',
        title: 'Mindful Moments',
        description: 'Practice 5-minute deep breathing sessions for 4 days',
        points: 40,
        deadline: now.add(const Duration(days: 7)),
      ),
      WellnessChallenge(
        id: '${now.millisecondsSinceEpoch}3',
        title: 'Creative Expression',
        description: 'Write a short poem or draw something that represents your mood each day',
        points: 60,
        deadline: now.add(const Duration(days: 7)),
      ),
    ];
  }
}