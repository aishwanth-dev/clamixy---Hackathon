import 'package:flutter/material.dart';

enum Emotion {
  happy(color: Color(0xFFFFD700), emoji: '😊'),
  sad(color: Color(0xFF4A90E2), emoji: '😢'),
  angry(color: Color(0xFFE74C3C), emoji: '😠'),
  calm(color: Color(0xFF9B59B6), emoji: '😌'),
  anxious(color: Color(0xFFF39C12), emoji: '😰'),
  excited(color: Color(0xFFE67E22), emoji: '🤩'),
  neutral(color: Color(0xFF95A5A6), emoji: '😐');

  const Emotion({required this.color, required this.emoji});
  final Color color;
  final String emoji;
}

// Legacy roles retained for backward compatibility but not used in new chat flow
enum AiRole {
  listener(name: 'Listener', emoji: '🌸', description: 'Gentle and empathetic, here to listen'),
  motivator(name: 'Motivator', emoji: '⚡', description: 'Energetic and encouraging, pushing you forward'),
  coach(name: 'Coach', emoji: '🎯', description: 'Strategic and goal-oriented, helping you plan');

  const AiRole({required this.name, required this.emoji, required this.description});
  final String name;
  final String emoji; 
  final String description;
}

class MoodEntry {
  final DateTime date;
  final Emotion emotion;
  final int intensity; // 1-5 scale
  final String note;
  final String? aiReflection;

  MoodEntry({
    required this.date,
    required this.emotion,
    required this.intensity,
    required this.note,
    this.aiReflection,
  });

  Map<String, dynamic> toJson() => {
    'date': date.millisecondsSinceEpoch,
    'emotion': emotion.index,
    'intensity': intensity,
    'note': note,
    'aiReflection': aiReflection,
  };

  factory MoodEntry.fromJson(Map<String, dynamic> json) => MoodEntry(
    date: DateTime.fromMillisecondsSinceEpoch(json['date']),
    emotion: Emotion.values[json['emotion']],
    intensity: json['intensity'],
    note: json['note'],
    aiReflection: json['aiReflection'],
  );
}

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final AiRole? aiRole;
  final String? moodContext;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.aiRole,
    this.moodContext,
  });

  Map<String, dynamic> toJson() => {
    'content': content,
    'isUser': isUser,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'aiRole': aiRole?.index,
    'moodContext': moodContext,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    content: json['content'],
    isUser: json['isUser'],
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    aiRole: json['aiRole'] != null ? AiRole.values[json['aiRole']] : null,
    moodContext: json['moodContext'],
  );
}

class WellnessChallenge {
  final String id;
  final String title;
  final String description;
  final int points;
  final DateTime deadline;
  final bool completed;
  final DateTime? completedAt;

  WellnessChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.deadline,
    this.completed = false,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'points': points,
    'deadline': deadline.millisecondsSinceEpoch,
    'completed': completed,
    'completedAt': completedAt?.millisecondsSinceEpoch,
  };

  factory WellnessChallenge.fromJson(Map<String, dynamic> json) => WellnessChallenge(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    points: json['points'],
    deadline: DateTime.fromMillisecondsSinceEpoch(json['deadline']),
    completed: json['completed'],
    completedAt: json['completedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(json['completedAt']) : null,
  );
}

class UserProgress {
  final int currentStreak;
  final int longestStreak;
  final int totalPoints;
  final List<String> unlockedRewards;
  final int totalStars;
  final Map<Emotion, int> emotionCounts;

  UserProgress({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalPoints = 0,
    this.unlockedRewards = const [],
    this.totalStars = 0,
    this.emotionCounts = const {},
  });

  Map<String, dynamic> toJson() => {
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'totalPoints': totalPoints,
    'unlockedRewards': unlockedRewards,
    'totalStars': totalStars,
    'emotionCounts': emotionCounts.map((key, value) => MapEntry(key.index.toString(), value)),
  };

  factory UserProgress.fromJson(Map<String, dynamic> json) => UserProgress(
    currentStreak: json['currentStreak'] ?? 0,
    longestStreak: json['longestStreak'] ?? 0,
    totalPoints: json['totalPoints'] ?? 0,
    unlockedRewards: List<String>.from(json['unlockedRewards'] ?? []),
    totalStars: json['totalStars'] ?? 0,
    emotionCounts: (json['emotionCounts'] as Map<String, dynamic>? ?? {})
        .map((key, value) => MapEntry(Emotion.values[int.parse(key)], value as int)),
  );
}

// New: Journal model for diary-style entries
class JournalEntry {
  final String id;
  final DateTime date;
  final String text;

  JournalEntry({
    required this.id,
    required this.date,
    required this.text,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.millisecondsSinceEpoch,
    'text': text,
  };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
    id: json['id'],
    date: DateTime.fromMillisecondsSinceEpoch(json['date']),
    text: json['text'],
  );
}
