import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stardust_soul/models.dart';
import 'package:stardust_soul/relief_story_models.dart';

class DataService {
  static const String _moodEntriesKey = 'mood_entries';
  static const String _chatMessagesKey = 'chat_messages';
  static const String _challengesKey = 'challenges';
  static const String _userProgressKey = 'user_progress';
  static const String _lastCheckInKey = 'last_checkin';
  static const String _journalEntriesKey = 'journal_entries';
  static const String _storyLibraryKey = 'story_library';
  static const String _reliefLibraryKey = 'relief_library';

  // Mood Entries
  static Future<List<MoodEntry>> getMoodEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_moodEntriesKey);
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => MoodEntry.fromJson(json)).toList();
  }

  static Future<void> saveMoodEntry(MoodEntry entry) async {
    final entries = await getMoodEntries();
    entries.add(entry);
    
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_moodEntriesKey, jsonString);
    
    // Update progress
    await _updateProgress();
  }

  // Chat Messages  
  static Future<List<ChatMessage>> getChatMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_chatMessagesKey);
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => ChatMessage.fromJson(json)).toList();
  }

  static Future<void> saveChatMessage(ChatMessage message) async {
    final messages = await getChatMessages();
    messages.add(message);
    
    // Keep only last 100 messages for performance
    if (messages.length > 100) {
      messages.removeRange(0, messages.length - 100);
    }
    
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(messages.map((m) => m.toJson()).toList());
    await prefs.setString(_chatMessagesKey, jsonString);
  }

  // Journal
  static Future<List<JournalEntry>> getJournalEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_journalEntriesKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    final entries = jsonList.map((e) => JournalEntry.fromJson(e)).toList();
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  static Future<void> addJournalEntry(JournalEntry entry) async {
    final entries = await getJournalEntries();
    entries.add(entry);

    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_journalEntriesKey, jsonString);
  }

  static Future<void> deleteJournalEntry(String id) async {
    final entries = await getJournalEntries();
    entries.removeWhere((e) => e.id == id);
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_journalEntriesKey, jsonString);
  }

  static Future<void> updateJournalEntry(JournalEntry updated) async {
    final entries = await getJournalEntries();
    final index = entries.indexWhere((e) => e.id == updated.id);
    if (index != -1) {
      entries[index] = updated;
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(entries.map((e) => e.toJson()).toList());
      await prefs.setString(_journalEntriesKey, jsonString);
    }
  }

  // Story Library
  static Future<List<StoryRecord>> getStoryLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storyLibraryKey);
    if (jsonString == null) return [];
    final List<dynamic> list = json.decode(jsonString);
    return list.map((e) {
      return StoryRecord(
        id: e['id'] as String,
        title: e['title'] as String,
        body: e['body'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(e['createdAt'] as int),
        mood: e['mood'] as String?,
      );
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> saveStoryToLibrary(StoryRecord story) async {
    final stories = await getStoryLibrary();
    stories.insert(0, story);
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(stories.map((s) => {
      'id': s.id,
      'title': s.title,
      'body': s.body,
      'createdAt': s.createdAt.millisecondsSinceEpoch,
      'mood': s.mood,
    }).toList());
    await prefs.setString(_storyLibraryKey, jsonString);
  }

  static Future<void> deleteStoryFromLibrary(String id) async {
    final stories = await getStoryLibrary();
    stories.removeWhere((s) => s.id == id);
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(stories.map((s) => {
      'id': s.id,
      'title': s.title,
      'body': s.body,
      'createdAt': s.createdAt.millisecondsSinceEpoch,
      'mood': s.mood,
    }).toList());
    await prefs.setString(_storyLibraryKey, jsonString);
  }

  // Relief Library
  static Future<List<ReliefPackageModel>> getReliefLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_reliefLibraryKey);
    if (jsonString == null) return [];
    final List<dynamic> list = json.decode(jsonString);
    return list.map((e) {
      return ReliefPackageModel.fromJson(e as Map<String, dynamic>);
    }).toList();
  }

  static Future<void> saveReliefToLibrary(ReliefPackageModel pkg) async {
    final list = await getReliefLibrary();
    list.insert(0, pkg);
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(list.map((p) => {
      'mood': p.mood,
      'title': p.title,
      'points': p.points,
      'steps': p.steps.map((s) => {
        'type': s.type,
        'title': s.title,
        'durationSec': s.durationSec,
        'instruction': s.instruction,
      }).toList(),
    }).toList());
    await prefs.setString(_reliefLibraryKey, jsonString);
  }

  static Future<void> deleteReliefFromLibrary(int index) async {
    final list = await getReliefLibrary();
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(list.map((p) => {
        'mood': p.mood,
        'title': p.title,
        'points': p.points,
        'steps': p.steps.map((s) => {
          'type': s.type,
          'title': s.title,
          'durationSec': s.durationSec,
          'instruction': s.instruction,
        }).toList(),
      }).toList());
      final prefs2 = await SharedPreferences.getInstance();
      await prefs2.setString(_reliefLibraryKey, jsonString);
    }
  }

  // Challenges
  static Future<List<WellnessChallenge>> getChallenges() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_challengesKey);
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => WellnessChallenge.fromJson(json)).toList();
  }

  static Future<void> saveChallenges(List<WellnessChallenge> challenges) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(challenges.map((c) => c.toJson()).toList());
    await prefs.setString(_challengesKey, jsonString);
  }

  static Future<void> completeChallenge(String challengeId) async {
    final challenges = await getChallenges();
    final challengeIndex = challenges.indexWhere((c) => c.id == challengeId);
    
    if (challengeIndex != -1) {
      final challenge = challenges[challengeIndex];
      challenges[challengeIndex] = WellnessChallenge(
        id: challenge.id,
        title: challenge.title,
        description: challenge.description,
        points: challenge.points,
        deadline: challenge.deadline,
        completed: true,
        completedAt: DateTime.now(),
      );
      
      await saveChallenges(challenges);
      await _updateProgress();
    }
  }

  // User Progress
  static Future<UserProgress> getUserProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_userProgressKey);
    if (jsonString == null) return UserProgress();
    
    return UserProgress.fromJson(json.decode(jsonString));
  }

  static Future<void> _updateProgress() async {
    final moodEntries = await getMoodEntries();
    final challenges = await getChallenges();
    final completedChallenges = challenges.where((c) => c.completed).toList();
    
    // Calculate streaks
    int currentStreak = _calculateCurrentStreak(moodEntries);
    int longestStreak = _calculateLongestStreak(moodEntries);
    
    // Calculate total points
    int totalPoints = completedChallenges.fold(0, (sum, c) => sum + c.points);
    
    // Calculate emotion counts
    Map<Emotion, int> emotionCounts = {};
    for (final entry in moodEntries) {
      emotionCounts[entry.emotion] = (emotionCounts[entry.emotion] ?? 0) + 1;
    }
    
    final progress = UserProgress(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalPoints: totalPoints,
      unlockedRewards: _getUnlockedRewards(totalPoints),
      totalStars: moodEntries.length,
      emotionCounts: emotionCounts,
    );
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userProgressKey, json.encode(progress.toJson()));
  }

  static int _calculateCurrentStreak(List<MoodEntry> entries) {
    if (entries.isEmpty) return 0;
    
    entries.sort((a, b) => b.date.compareTo(a.date));
    int streak = 0;
    DateTime? lastDate;
    
    for (final entry in entries) {
      final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
      
      if (lastDate == null) {
        lastDate = entryDate;
        streak = 1;
      } else {
        final daysDiff = lastDate.difference(entryDate).inDays;
        if (daysDiff == 1) {
          streak++;
          lastDate = entryDate;
        } else {
          break;
        }
      }
    }
    
    return streak;
  }

  static int _calculateLongestStreak(List<MoodEntry> entries) {
    if (entries.isEmpty) return 0;
    
    entries.sort((a, b) => a.date.compareTo(b.date));
    int longestStreak = 0;
    int currentStreak = 0;
    DateTime? lastDate;
    
    for (final entry in entries) {
      final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
      
      if (lastDate == null || entryDate.difference(lastDate).inDays == 1) {
        currentStreak++;
        longestStreak = currentStreak > longestStreak ? currentStreak : longestStreak;
      } else {
        currentStreak = 1;
      }
      lastDate = entryDate;
    }
    
    return longestStreak;
  }

  static List<String> _getUnlockedRewards(int points) {
    final rewards = <String>[];
    if (points >= 50) rewards.add('Galaxy Explorer');
    if (points >= 100) rewards.add('Mood Master');
    if (points >= 200) rewards.add('Wellness Warrior');
    if (points >= 500) rewards.add('Stardust Champion');
    return rewards;
  }

  // Check-in tracking
  static Future<bool> hasCheckedInToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheckIn = prefs.getString(_lastCheckInKey);
    if (lastCheckIn == null) return false;
    
    final lastDate = DateTime.parse(lastCheckIn);
    final today = DateTime.now();
    
    return lastDate.year == today.year && 
           lastDate.month == today.month && 
           lastDate.day == today.day;
  }

  static Future<void> markCheckInComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastCheckInKey, DateTime.now().toIso8601String());
  }

  // Sample data generation
  static Future<void> generateSampleData() async {
    final prefs = await SharedPreferences.getInstance();
    final hasData = prefs.containsKey(_moodEntriesKey);
    if (hasData) return;
    
    // Generate sample mood entries for the past 2 weeks
    final sampleEntries = <MoodEntry>[];
    final now = DateTime.now();
    
    for (int i = 14; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      if (i % 3 == 0) continue; // Skip some days for realistic data
      
      final emotions = Emotion.values;
      final randomEmotion = emotions[i % emotions.length];
      
      sampleEntries.add(MoodEntry(
        date: date,
        emotion: randomEmotion,
        intensity: 3 + (i % 3),
        note: _getSampleNote(randomEmotion),
        aiReflection: _getSampleReflection(randomEmotion),
      ));
    }
    
    final jsonString = json.encode(sampleEntries.map((e) => e.toJson()).toList());
    await prefs.setString(_moodEntriesKey, jsonString);
    
    // Generate sample challenges
    final sampleChallenges = [
      WellnessChallenge(
        id: '1',
        title: 'Daily Gratitude',
        description: 'Write 3 things you\'re grateful for each day this week',
        points: 70,
        deadline: DateTime.now().add(const Duration(days: 7)),
        completed: true,
        completedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      WellnessChallenge(
        id: '2', 
        title: 'Mindful Breathing',
        description: 'Practice 5-minute breathing sessions for 5 days',
        points: 50,
        deadline: DateTime.now().add(const Duration(days: 5)),
      ),
      WellnessChallenge(
        id: '3',
        title: 'Poetry Reflection',
        description: 'Write a short poem about your day for 3 days',
        points: 60,
        deadline: DateTime.now().add(const Duration(days: 10)),
      ),
    ];
    
    final challengesJson = json.encode(sampleChallenges.map((c) => c.toJson()).toList());
    await prefs.setString(_challengesKey, challengesJson);
    
    await _updateProgress();
  }

  static String _getSampleNote(Emotion emotion) {
    switch (emotion) {
      case Emotion.happy:
        return 'Had a great day with friends! Feeling grateful.';
      case Emotion.sad:
        return 'Missing home today. Everything feels overwhelming.';
      case Emotion.angry:
        return 'Frustrated with the project deadline. Need to find balance.';
      case Emotion.calm:
        return 'Peaceful morning meditation. Feeling centered.';
      case Emotion.anxious:
        return 'Worried about tomorrow\'s presentation. Heart racing.';
      case Emotion.excited:
        return 'Got accepted to the internship! Can\'t contain my joy!';
      case Emotion.neutral:
        return 'Regular day. Nothing special but feeling okay.';
    }
  }

  static String _getSampleReflection(Emotion emotion) {
    switch (emotion) {
      case Emotion.happy:
        return 'Your joy today shows the power of connection. Remember this feeling when challenges arise.';
      case Emotion.sad:
        return 'It\'s okay to feel homesick. These emotions show how much you care. You\'re stronger than you know.';
      case Emotion.angry:
        return 'Your frustration is valid. Channel this energy into problem-solving. You have the skills to overcome this.';
      case Emotion.calm:
        return 'This peaceful state is your natural foundation. Return to this feeling whenever you need grounding.';
      case Emotion.anxious:
        return 'Anxiety before something important shows you care. Take deep breaths. You\'re prepared for this.';
      case Emotion.excited:
        return 'Your excitement is contagious! This achievement reflects your hard work and dedication.';
      case Emotion.neutral:
        return 'Steady days are the foundation of growth. Every moment doesn\'t need to be extraordinary.';
    }
  }
}
