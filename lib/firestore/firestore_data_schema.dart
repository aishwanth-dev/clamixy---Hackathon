// Firestore Data Schema for Stardust Soul App
// This file defines the data models and structure for Firebase Firestore

import 'package:cloud_firestore/cloud_firestore.dart';

/// User Profile Model
class UserProfile {
  final String userId;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int totalStars;
  final int streakDays;
  final Map<String, dynamic> preferences;

  UserProfile({
    required this.userId,
    required this.email,
    this.displayName,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    this.totalStars = 0,
    this.streakDays = 0,
    this.preferences = const {},
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      userId: doc.id,
      email: data['email'],
      displayName: data['display_name'],
      avatarUrl: data['avatar_url'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
      totalStars: data['total_stars'] ?? 0,
      streakDays: data['streak_days'] ?? 0,
      preferences: data['preferences'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'total_stars': totalStars,
      'streak_days': streakDays,
      'preferences': preferences,
    };
  }
}

/// Mood Entry Model for Emotion Galaxy
class MoodEntry {
  final String id;
  final String userId;
  final String emotion;
  final int intensity; // 1-5 scale
  final String? note;
  final DateTime createdAt;
  final Map<String, dynamic>? starData; // For galaxy visualization

  MoodEntry({
    required this.id,
    required this.userId,
    required this.emotion,
    required this.intensity,
    this.note,
    required this.createdAt,
    this.starData,
  });

  factory MoodEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MoodEntry(
      id: doc.id,
      userId: data['user_id'],
      emotion: data['emotion'],
      intensity: data['intensity'],
      note: data['note'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
      starData: data['star_data'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'emotion': emotion,
      'intensity': intensity,
      'note': note,
      'created_at': Timestamp.fromDate(createdAt),
      'star_data': starData,
    };
  }
}

/// Chat Conversation Model
class ChatConversation {
  final String id;
  final String userId;
  final String title;
  final String aiPersona; // 'listener', 'motivator', 'coach'
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessage;
  final bool isActive;

  ChatConversation({
    required this.id,
    required this.userId,
    required this.title,
    required this.aiPersona,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.isActive = true,
  });

  factory ChatConversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatConversation(
      id: doc.id,
      userId: data['user_id'],
      title: data['title'],
      aiPersona: data['ai_persona'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
      lastMessage: data['last_message'],
      isActive: data['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'title': title,
      'ai_persona': aiPersona,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'last_message': lastMessage,
      'is_active': isActive,
    };
  }
}

/// Chat Message Model
class ChatMessage {
  final String id;
  final String conversationId;
  final String content;
  final bool isUser;
  final DateTime createdAt;
  final String? messageType; // 'text', 'coping_technique', 'crisis_alert'
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.isUser,
    required this.createdAt,
    this.messageType = 'text',
    this.metadata,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      conversationId: data['conversation_id'],
      content: data['content'],
      isUser: data['is_user'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
      messageType: data['message_type'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'conversation_id': conversationId,
      'content': content,
      'is_user': isUser,
      'created_at': Timestamp.fromDate(createdAt),
      'message_type': messageType,
      'metadata': metadata,
    };
  }
}

/// Wellness Challenge Model
class WellnessChallenge {
  final String id;
  final String title;
  final String description;
  final String category; // 'mindfulness', 'gratitude', 'self_care', etc.
  final int duration; // in days
  final List<String> dailyTasks;
  final int points;
  final String? iconUrl;
  final bool isActive;

  WellnessChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.duration,
    required this.dailyTasks,
    this.points = 10,
    this.iconUrl,
    this.isActive = true,
  });

  factory WellnessChallenge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WellnessChallenge(
      id: doc.id,
      title: data['title'],
      description: data['description'],
      category: data['category'],
      duration: data['duration'],
      dailyTasks: List<String>.from(data['daily_tasks']),
      points: data['points'] ?? 10,
      iconUrl: data['icon_url'],
      isActive: data['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'duration': duration,
      'daily_tasks': dailyTasks,
      'points': points,
      'icon_url': iconUrl,
      'is_active': isActive,
    };
  }
}

/// Challenge Progress Model
class ChallengeProgress {
  final String id;
  final String userId;
  final String challengeId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int currentDay;
  final List<bool> dailyCompletion;
  final int pointsEarned;
  final bool completed;

  ChallengeProgress({
    required this.id,
    required this.userId,
    required this.challengeId,
    required this.startedAt,
    this.completedAt,
    this.currentDay = 1,
    this.dailyCompletion = const [],
    this.pointsEarned = 0,
    this.completed = false,
  });

  factory ChallengeProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChallengeProgress(
      id: doc.id,
      userId: data['user_id'],
      challengeId: data['challenge_id'],
      startedAt: (data['started_at'] as Timestamp).toDate(),
      completedAt: data['completed_at'] != null 
        ? (data['completed_at'] as Timestamp).toDate() 
        : null,
      currentDay: data['current_day'] ?? 1,
      dailyCompletion: List<bool>.from(data['daily_completion'] ?? []),
      pointsEarned: data['points_earned'] ?? 0,
      completed: data['completed'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'challenge_id': challengeId,
      'started_at': Timestamp.fromDate(startedAt),
      'completed_at': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'current_day': currentDay,
      'daily_completion': dailyCompletion,
      'points_earned': pointsEarned,
      'completed': completed,
    };
  }
}

/// User Progress Model
class UserProgress {
  final String userId;
  final int totalPoints;
  final int level;
  final int starsEarned;
  final int currentStreak;
  final int longestStreak;
  final Map<String, int> achievementCounts;
  final DateTime lastActiveDate;
  final DateTime updatedAt;

  UserProgress({
    required this.userId,
    this.totalPoints = 0,
    this.level = 1,
    this.starsEarned = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.achievementCounts = const {},
    required this.lastActiveDate,
    required this.updatedAt,
  });

  factory UserProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProgress(
      userId: doc.id,
      totalPoints: data['total_points'] ?? 0,
      level: data['level'] ?? 1,
      starsEarned: data['stars_earned'] ?? 0,
      currentStreak: data['current_streak'] ?? 0,
      longestStreak: data['longest_streak'] ?? 0,
      achievementCounts: Map<String, int>.from(data['achievement_counts'] ?? {}),
      lastActiveDate: (data['last_active_date'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'total_points': totalPoints,
      'level': level,
      'stars_earned': starsEarned,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'achievement_counts': achievementCounts,
      'last_active_date': Timestamp.fromDate(lastActiveDate),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }
}

/// Helpline Resource Model
class HelplineResource {
  final String id;
  final String name;
  final String phoneNumber;
  final String? website;
  final String country;
  final String category; // 'crisis', 'mental_health', 'teen_support'
  final String description;
  final bool isActive;

  HelplineResource({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.website,
    required this.country,
    required this.category,
    required this.description,
    this.isActive = true,
  });

  factory HelplineResource.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HelplineResource(
      id: doc.id,
      name: data['name'],
      phoneNumber: data['phone_number'],
      website: data['website'],
      country: data['country'],
      category: data['category'],
      description: data['description'],
      isActive: data['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone_number': phoneNumber,
      'website': website,
      'country': country,
      'category': category,
      'description': description,
      'is_active': isActive,
    };
  }
}