import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../models/user.dart';
import '../models/playlist.dart';
import 'video_metadata_service.dart';

class AuthService {
  static GoogleSignIn? _googleSignIn;
  static User? _currentUser;
  static bool _initialized = false;

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

  static Future<AuthResult> initialize() async {
    if (_initialized) {
      print('AuthService.initialize: Already initialized, skipping');
      return AuthResult(success: true, user: _currentUser, message: '已初始化');
    }
    
    try {
      final account = await googleSignIn.signInSilently();
      if (account != null) {
        _currentUser = User.fromGoogleSignInAccount(account);
        // Load saved playlist from local storage
        await _loadPlaylistFromStorage();
        print('AuthService.initialize: Created user with playlist length: ${_currentUser!.playlist.length}');
      }
      _initialized = true;
      return AuthResult(success: true, user: _currentUser, message: '初始化成功');
    } catch (e) {
      print('Error initializing auth service: $e');
      return AuthResult(success: false, message: _getErrorMessage(e));
    }
  }

  static Future<AuthResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account != null) {
        _currentUser = User.fromGoogleSignInAccount(account);
        // Load saved playlist from local storage for the new user
        await _loadPlaylistFromStorage();
        _initialized = true;
        print('AuthService.signInWithGoogle: User signed in with playlist length: ${_currentUser!.playlist.length}');
        return AuthResult(success: true, user: _currentUser, message: '登录成功');
      } else {
        return AuthResult(success: false, message: '用户取消登录');
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      return AuthResult(success: false, message: _getErrorMessage(e));
    }
  }

  static Future<void> signOut() async {
    try {
      await googleSignIn.signOut();
      _currentUser = null;
      _initialized = false;
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  static Future<void> disconnect() async {
    try {
      await googleSignIn.disconnect();
      _currentUser = null;
      _initialized = false;
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

  // Playlist management methods - using user's playlist
  static Playlist get playlist => _currentUser?.playlist ?? Playlist();

  static Future<void> addToPlaylist(String videoId, {String? title, String? channelName, Duration? duration, String? thumbnail, String? description, String category = '未分类'}) async {
    if (_currentUser == null) {
      print('AuthService.addToPlaylist: No current user, skipping');
      return;
    }
    
    print('AuthService.addToPlaylist: Adding video $videoId to playlist');

    try {
      PlaylistItem? item;
      
      // Try to get metadata from VideoMetadataService
      item = await VideoMetadataService.getVideoMetadata(videoId);
      
      // If metadata service returns null or incomplete data, create with provided data
      if (item == null) {
        item = PlaylistItem(
          videoId: videoId,
          title: title ?? 'Video $videoId',
          channelName: channelName,
          duration: duration,
          thumbnail: thumbnail,
          description: description,
          category: category,
        );
      } else {
        // Update with any additional data provided
        item = item.copyWith(
          title: title ?? item.title,
          channelName: channelName ?? item.channelName,
          duration: duration ?? item.duration,
          thumbnail: thumbnail ?? item.thumbnail,
          description: description ?? item.description,
          category: category,
        );
      }

      final newPlaylist = _currentUser!.playlist.addVideo(item);
      _currentUser = _currentUser!.copyWith(playlist: newPlaylist);
      await _savePlaylistToStorage();
      print('AuthService.addToPlaylist: Video added successfully, new playlist length: ${_currentUser!.playlist.length}');
    } catch (e) {
      print('AuthService.addToPlaylist: Error in main flow: $e');
      // Fallback: create with basic info
      final item = PlaylistItem(
        videoId: videoId,
        title: title ?? 'Video $videoId',
        channelName: channelName,
        duration: duration,
        thumbnail: thumbnail ?? 'https://img.youtube.com/vi/$videoId/mqdefault.jpg',
        description: description,
        category: category,
      );

      final newPlaylist = _currentUser!.playlist.addVideo(item);
      _currentUser = _currentUser!.copyWith(playlist: newPlaylist);
      await _savePlaylistToStorage();
      print('AuthService.addToPlaylist: Video added via fallback, new playlist length: ${_currentUser!.playlist.length}');
    }
  }

  static void removeFromPlaylist(String videoId) {
    if (_currentUser != null) {
      final newPlaylist = _currentUser!.playlist.removeVideo(videoId);
      _currentUser = _currentUser!.copyWith(playlist: newPlaylist);
      _savePlaylistToStorage();
    }
  }

  static void clearPlaylist() {
    if (_currentUser != null) {
      final newPlaylist = Playlist();
      _currentUser = _currentUser!.copyWith(playlist: newPlaylist);
      _savePlaylistToStorage();
    }
  }

  static void updateVideoCategory(String videoId, String newCategory) {
    if (_currentUser != null) {
      final newPlaylist = _currentUser!.playlist.updateVideoCategory(videoId, newCategory);
      _currentUser = _currentUser!.copyWith(playlist: newPlaylist);
      _savePlaylistToStorage();
    }
  }

  static bool isVideoInPlaylist(String videoId) {
    return _currentUser?.playlist.containsVideo(videoId) ?? false;
  }

  static PlaylistItem? getPlaylistVideo(String videoId) {
    return _currentUser?.playlist.getVideo(videoId);
  }

  static List<String> getPlaylistCategories() {
    return _currentUser?.playlist.categories ?? [];
  }

  static List<PlaylistItem> getVideosByCategory(String category) {
    return _currentUser?.playlist.getVideosByCategory(category) ?? [];
  }

  // Force refresh playlist data
  static Future<void> refreshPlaylist() async {
    if (_currentUser != null) {
      await _loadPlaylistFromStorage();
      print('AuthService.refreshPlaylist: Playlist refreshed with ${_currentUser!.playlist.length} items');
    }
  }

  // Local storage methods
  static Future<void> _savePlaylistToStorage() async {
    try {
      if (_currentUser == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      final playlistJson = json.encode(_currentUser!.playlist.toJson());
      final userKey = 'user_playlist_${_currentUser!.email}';
      await prefs.setString(userKey, playlistJson);
      print('AuthService: Saved playlist to storage with ${_currentUser!.playlist.length} items for ${_currentUser!.email}');
    } catch (e) {
      print('Error saving playlist to storage: $e');
    }
  }

  static Future<void> _loadPlaylistFromStorage() async {
    try {
      if (_currentUser == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      final userKey = 'user_playlist_${_currentUser!.email}';
      final playlistJsonString = prefs.getString(userKey);
      
      if (playlistJsonString != null) {
        final playlistJson = json.decode(playlistJsonString) as Map<String, dynamic>;
        final savedPlaylist = Playlist.fromJson(playlistJson);
        _currentUser = _currentUser!.copyWith(playlist: savedPlaylist);
        print('AuthService: Loaded playlist from storage with ${savedPlaylist.length} items for ${_currentUser!.email}');
      } else {
        print('AuthService: No saved playlist found in storage for ${_currentUser!.email}');
      }
    } catch (e) {
      print('Error loading playlist from storage: $e');
    }
  }

  static String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network_error') || errorString.contains('network')) {
      return '网络连接错误，请检查网络设置';
    } else if (errorString.contains('sign_in_canceled')) {
      return '用户取消了登录';
    } else if (errorString.contains('sign_in_failed')) {
      return 'Google 登录失败，请稍后重试';
    } else if (errorString.contains('account_exists_with_different_credential')) {
      return '该邮箱已关联其他登录方式';
    } else if (errorString.contains('invalid_credential')) {
      return '登录凭据无效，请重新登录';
    } else if (errorString.contains('user_disabled')) {
      return '该账户已被禁用';
    } else if (errorString.contains('operation_not_allowed')) {
      return 'Google 登录服务未启用';
    } else if (errorString.contains('too_many_requests')) {
      return '请求过于频繁，请稍后再试';
    } else if (errorString.contains('timeout')) {
      return '登录超时，请检查网络连接';
    } else if (errorString.contains('platform')) {
      return '平台不支持此登录方式';
    } else if (errorString.contains('service_unavailable')) {
      return 'Google 服务暂时不可用';
    } else if (errorString.contains('permission_denied')) {
      return '权限被拒绝，请检查应用权限';
    } else {
      return '登录失败：${error.toString()}';
    }
  }
}

class AuthResult {
  final bool success;
  final User? user;
  final String message;

  AuthResult({
    required this.success,
    this.user,
    required this.message,
  });
}