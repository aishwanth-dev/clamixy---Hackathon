// App Provider for Stardust Soul
// This provider manages the global app state including authentication and user data

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firestore/auth_service.dart';
import '../firestore/firestore_service.dart';
import '../firestore/firestore_data_schema.dart';

class AppProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  User? _user;
  UserProfile? _userProfile;
  UserProgress? _userProgress;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  UserProgress? get userProgress => _userProgress;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AppProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _authService.userStream.listen((User? user) {
      _user = user;
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        _userProfile = null;
        _userProgress = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserData(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Load user profile and progress
      final profileFuture = _firestoreService.getUserProfile(userId);
      final progressFuture = _firestoreService.getUserProgress(userId);

      final results = await Future.wait([profileFuture, progressFuture]);
      
      _userProfile = results[0] as UserProfile?;
      _userProgress = results[1] as UserProgress?;

      // Create user progress if it doesn't exist
      if (_userProgress == null && _userProfile != null) {
        final newProgress = UserProgress(
          userId: userId,
          lastActiveDate: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _firestoreService.createUserProgress(newProgress);
        _userProgress = newProgress;
      }

    } catch (e) {
      _error = 'Failed to load user data: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Authentication methods
  Future<bool> signUpWithEmailPassword(String email, String password, {String? displayName}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.signUpWithEmailPassword(email, password, displayName: displayName);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithEmailPassword(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.signInWithEmailPassword(email, password);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.signInWithGoogle();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInAnonymously() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.signInAnonymously();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // User data methods
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    if (_user == null) return;

    try {
      await _firestoreService.updateUserProfile(_user!.uid, updates);
      await _loadUserData(_user!.uid); // Refresh data
    } catch (e) {
      _error = 'Failed to update profile: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> addPointsToUser(int points) async {
    if (_user == null) return;

    try {
      await _firestoreService.addPointsToUser(_user!.uid, points);
      await _loadUserData(_user!.uid); // Refresh data
    } catch (e) {
      _error = 'Failed to add points: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> updateStreak() async {
    if (_user == null) return;

    try {
      final streakDays = await _firestoreService.getActiveStreakDays(_user!.uid);
      await _firestoreService.updateUserProgress(_user!.uid, {
        'current_streak': streakDays,
        'longest_streak': _userProgress != null && streakDays > _userProgress!.longestStreak 
          ? streakDays 
          : _userProgress?.longestStreak ?? 0,
      });
      await _loadUserData(_user!.uid); // Refresh data
    } catch (e) {
      _error = 'Failed to update streak: ${e.toString()}';
      notifyListeners();
    }
  }

  // Utility methods
  void clearError() {
    _error = null;
    notifyListeners();
  }

  bool get canEarnDailyPoints {
    if (_userProgress == null) return true;
    
    final lastActive = _userProgress!.lastActiveDate;
    final today = DateTime.now();
    
    return !_isSameDay(lastActive, today);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  int get currentLevel {
    if (_userProgress == null) return 1;
    return _userProgress!.level;
  }

  int get pointsToNextLevel {
    if (_userProgress == null) return 100;
    final currentLevelPoints = (_userProgress!.level - 1) * 100;
    return (_userProgress!.level * 100) - (_userProgress!.totalPoints - currentLevelPoints);
  }

  double get levelProgress {
    if (_userProgress == null) return 0.0;
    final currentLevelPoints = (_userProgress!.level - 1) * 100;
    final pointsInCurrentLevel = _userProgress!.totalPoints - currentLevelPoints;
    return pointsInCurrentLevel / 100.0;
  }
}