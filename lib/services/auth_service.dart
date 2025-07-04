import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';

class AuthService {
  static GoogleSignIn? _googleSignIn;
  static User? _currentUser;

  static GoogleSignIn get googleSignIn {
    _googleSignIn ??= GoogleSignIn(
      scopes: [
        'email',
        'profile',
      ],
    );
    return _googleSignIn!;
  }

  static User? get currentUser => _currentUser;
  static bool get isSignedIn => _currentUser != null;

  static Future<void> initialize() async {
    try {
      final account = await googleSignIn.signInSilently();
      if (account != null) {
        _currentUser = User.fromGoogleSignInAccount(account);
      }
    } catch (e) {
      print('Error initializing auth service: $e');
    }
  }

  static Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account != null) {
        _currentUser = User.fromGoogleSignInAccount(account);
        return _currentUser;
      }
    } catch (e) {
      print('Error signing in with Google: $e');
    }
    return null;
  }

  static Future<void> signOut() async {
    try {
      await googleSignIn.signOut();
      _currentUser = null;
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  static Future<void> disconnect() async {
    try {
      await googleSignIn.disconnect();
      _currentUser = null;
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }

  static Future<User?> refreshUserData() async {
    try {
      final account = await googleSignIn.signInSilently();
      if (account != null) {
        _currentUser = User.fromGoogleSignInAccount(account);
        return _currentUser;
      }
    } catch (e) {
      print('Error refreshing user data: $e');
    }
    return null;
  }

  static Future<bool> isUserSignedIn() async {
    try {
      final account = await googleSignIn.signInSilently();
      return account != null;
    } catch (e) {
      print('Error checking sign in status: $e');
      return false;
    }
  }

  static Future<String?> getAccessToken() async {
    try {
      final account = await googleSignIn.signInSilently();
      if (account != null) {
        final auth = await account.authentication;
        return auth.accessToken;
      }
    } catch (e) {
      print('Error getting access token: $e');
    }
    return null;
  }

  static Future<String?> getIdToken() async {
    try {
      final account = await googleSignIn.signInSilently();
      if (account != null) {
        final auth = await account.authentication;
        return auth.idToken;
      }
    } catch (e) {
      print('Error getting ID token: $e');
    }
    return null;
  }

  static void updateUserPreferences(UserPreferences preferences) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(preferences: preferences);
    }
  }

  static void updateUserStats(UserStats stats) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(stats: stats);
    }
  }

  static void addRecentVideo(String videoId) {
    if (_currentUser != null) {
      final recentIds = List<String>.from(_currentUser!.recentVideoIds);
      recentIds.removeWhere((id) => id == videoId);
      recentIds.insert(0, videoId);
      
      // Keep only the last 10 recent videos
      if (recentIds.length > 10) {
        recentIds.removeRange(10, recentIds.length);
      }
      
      _currentUser = _currentUser!.copyWith(recentVideoIds: recentIds);
    }
  }

  static void updateVideoProgress(String videoId, double progress) {
    if (_currentUser != null) {
      final progressMap = Map<String, double>.from(_currentUser!.videoProgress);
      progressMap[videoId] = progress;
      _currentUser = _currentUser!.copyWith(videoProgress: progressMap);
    }
  }

  static void toggleFavoriteVideo(String videoId) {
    if (_currentUser != null) {
      final favoriteIds = List<String>.from(_currentUser!.favoriteVideoIds);
      if (favoriteIds.contains(videoId)) {
        favoriteIds.remove(videoId);
      } else {
        favoriteIds.add(videoId);
      }
      _currentUser = _currentUser!.copyWith(favoriteVideoIds: favoriteIds);
    }
  }

  static bool isVideoFavorite(String videoId) {
    return _currentUser?.favoriteVideoIds.contains(videoId) ?? false;
  }

  static double getVideoProgress(String videoId) {
    return _currentUser?.videoProgress[videoId] ?? 0.0;
  }

  static void incrementSegmentClicks() {
    if (_currentUser != null) {
      final newStats = _currentUser!.stats.copyWith(
        totalSegmentsClicked: _currentUser!.stats.totalSegmentsClicked + 1,
      );
      _currentUser = _currentUser!.copyWith(stats: newStats);
    }
  }

  static void addStudyTime(int seconds) {
    if (_currentUser != null) {
      final now = DateTime.now();
      final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      final dailyActivity = Map<String, int>.from(_currentUser!.stats.dailyActivity);
      dailyActivity[todayKey] = (dailyActivity[todayKey] ?? 0) + (seconds ~/ 60);
      
      final newStats = _currentUser!.stats.copyWith(
        totalTimeSpent: _currentUser!.stats.totalTimeSpent + seconds,
        dailyActivity: dailyActivity,
        lastStudyDate: now,
      );
      
      _currentUser = _currentUser!.copyWith(stats: newStats);
    }
  }

  static void completeVideo(String videoId) {
    if (_currentUser != null) {
      final newStats = _currentUser!.stats.copyWith(
        totalVideosWatched: _currentUser!.stats.totalVideosWatched + 1,
      );
      _currentUser = _currentUser!.copyWith(stats: newStats);
    }
  }
}