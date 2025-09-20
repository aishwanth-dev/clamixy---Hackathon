// Firestore Service for Stardust Soul App
// This service handles all Firestore database operations

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_data_schema.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // User Profile Operations
  Future<void> createUserProfile(UserProfile profile) async {
    await _firestore
        .collection('user_profiles')
        .doc(profile.userId)
        .set(profile.toFirestore());
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('user_profiles').doc(userId).get();
    return doc.exists ? UserProfile.fromFirestore(doc) : null;
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    await _firestore
        .collection('user_profiles')
        .doc(userId)
        .update({...updates, 'updated_at': FieldValue.serverTimestamp()});
  }

  // Mood Entry Operations
  Future<String> createMoodEntry(MoodEntry entry) async {
    final docRef = await _firestore
        .collection('mood_entries')
        .add(entry.toFirestore());
    return docRef.id;
  }

  Stream<List<MoodEntry>> getUserMoodEntries(String userId, {int limit = 30}) {
    return _firestore
        .collection('mood_entries')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MoodEntry.fromFirestore(doc)).toList());
  }

  Future<List<MoodEntry>> getMoodEntriesByEmotion(String userId, String emotion) async {
    final snapshot = await _firestore
        .collection('mood_entries')
        .where('user_id', isEqualTo: userId)
        .where('emotion', isEqualTo: emotion)
        .orderBy('created_at', descending: true)
        .limit(20)
        .get();
    
    return snapshot.docs.map((doc) => MoodEntry.fromFirestore(doc)).toList();
  }

  // Chat Operations
  Future<String> createChatConversation(ChatConversation conversation) async {
    final docRef = await _firestore
        .collection('chat_conversations')
        .add(conversation.toFirestore());
    return docRef.id;
  }

  Stream<List<ChatConversation>> getUserConversations(String userId) {
    return _firestore
        .collection('chat_conversations')
        .where('user_id', isEqualTo: userId)
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatConversation.fromFirestore(doc))
            .toList());
  }

  Future<void> updateConversation(String conversationId, Map<String, dynamic> updates) async {
    await _firestore
        .collection('chat_conversations')
        .doc(conversationId)
        .update({...updates, 'updated_at': FieldValue.serverTimestamp()});
  }

  Future<String> addChatMessage(ChatMessage message) async {
    final docRef = await _firestore
        .collection('chat_conversations')
        .doc(message.conversationId)
        .collection('messages')
        .add(message.toFirestore());
    
    // Update conversation's last message and timestamp
    await updateConversation(message.conversationId, {
      'last_message': message.content,
      'updated_at': FieldValue.serverTimestamp(),
    });
    
    return docRef.id;
  }

  Stream<List<ChatMessage>> getConversationMessages(String conversationId, {int limit = 50}) {
    return _firestore
        .collection('chat_conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList()
            .reversed
            .toList());
  }

  // Challenge Operations
  Stream<List<WellnessChallenge>> getActiveChallenges() {
    return _firestore
        .collection('wellness_challenges')
        .where('is_active', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WellnessChallenge.fromFirestore(doc))
            .toList());
  }

  Future<WellnessChallenge?> getChallenge(String challengeId) async {
    final doc = await _firestore.collection('wellness_challenges').doc(challengeId).get();
    return doc.exists ? WellnessChallenge.fromFirestore(doc) : null;
  }

  Future<String> startChallenge(String userId, String challengeId) async {
    final progress = ChallengeProgress(
      id: '',
      userId: userId,
      challengeId: challengeId,
      startedAt: DateTime.now(),
      dailyCompletion: [],
    );
    
    final docRef = await _firestore
        .collection('challenge_progress')
        .add(progress.toFirestore());
    
    return docRef.id;
  }

  Stream<List<ChallengeProgress>> getUserChallengeProgress(String userId) {
    return _firestore
        .collection('challenge_progress')
        .where('user_id', isEqualTo: userId)
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChallengeProgress.fromFirestore(doc))
            .toList());
  }

  Future<void> updateChallengeProgress(String progressId, Map<String, dynamic> updates) async {
    await _firestore
        .collection('challenge_progress')
        .doc(progressId)
        .update({...updates, 'updated_at': FieldValue.serverTimestamp()});
  }

  // User Progress Operations
  Future<void> createUserProgress(UserProgress progress) async {
    await _firestore
        .collection('user_progress')
        .doc(progress.userId)
        .set(progress.toFirestore());
  }

  Future<UserProgress?> getUserProgress(String userId) async {
    final doc = await _firestore.collection('user_progress').doc(userId).get();
    return doc.exists ? UserProgress.fromFirestore(doc) : null;
  }

  Future<void> updateUserProgress(String userId, Map<String, dynamic> updates) async {
    await _firestore
        .collection('user_progress')
        .doc(userId)
        .update({...updates, 'updated_at': FieldValue.serverTimestamp()});
  }

  // Helper method to increment user points and update level
  Future<void> addPointsToUser(String userId, int points) async {
    final userProgressRef = _firestore.collection('user_progress').doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(userProgressRef);
      
      if (!doc.exists) {
        // Create initial progress if doesn't exist
        final newProgress = UserProgress(
          userId: userId,
          totalPoints: points,
          lastActiveDate: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        transaction.set(userProgressRef, newProgress.toFirestore());
        return;
      }
      
      final currentProgress = UserProgress.fromFirestore(doc);
      final newTotalPoints = currentProgress.totalPoints + points;
      final newLevel = (newTotalPoints / 100).floor() + 1; // 100 points per level
      
      transaction.update(userProgressRef, {
        'total_points': newTotalPoints,
        'level': newLevel,
        'last_active_date': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  // Helpline Resources
  Stream<List<HelplineResource>> getHelplineResources({String? category}) {
    Query query = _firestore
        .collection('helpline_resources')
        .where('is_active', isEqualTo: true);
    
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    
    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => HelplineResource.fromFirestore(doc))
        .toList());
  }

  // Analytics and Aggregations
  Future<Map<String, int>> getMoodAnalytics(String userId, {int days = 30}) async {
    final startDate = DateTime.now().subtract(Duration(days: days));
    
    final snapshot = await _firestore
        .collection('mood_entries')
        .where('user_id', isEqualTo: userId)
        .where('created_at', isGreaterThan: Timestamp.fromDate(startDate))
        .get();
    
    final moodCounts = <String, int>{};
    for (final doc in snapshot.docs) {
      final entry = MoodEntry.fromFirestore(doc);
      moodCounts[entry.emotion] = (moodCounts[entry.emotion] ?? 0) + 1;
    }
    
    return moodCounts;
  }

  Future<int> getActiveStreakDays(String userId) async {
    final entries = await _firestore
        .collection('mood_entries')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(30)
        .get();
    
    if (entries.docs.isEmpty) return 0;
    
    int streakDays = 0;
    DateTime? lastEntryDate;
    final today = DateTime.now();
    
    for (final doc in entries.docs) {
      final entryDate = (doc.data()['created_at'] as Timestamp).toDate();
      final daysDiff = today.difference(entryDate).inDays;
      
      if (lastEntryDate == null) {
        if (daysDiff <= 1) {
          streakDays = 1;
          lastEntryDate = entryDate;
        } else {
          break;
        }
      } else {
        final daysBetween = lastEntryDate.difference(entryDate).inDays;
        if (daysBetween <= 1) {
          streakDays++;
          lastEntryDate = entryDate;
        } else {
          break;
        }
      }
    }
    
    return streakDays;
  }

  // Batch operations for performance
  Future<void> batchCreateMoodEntries(List<MoodEntry> entries) async {
    final batch = _firestore.batch();
    
    for (final entry in entries) {
      final docRef = _firestore.collection('mood_entries').doc();
      batch.set(docRef, entry.toFirestore());
    }
    
    await batch.commit();
  }
}