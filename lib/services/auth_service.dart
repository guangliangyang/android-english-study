import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import '../models/playlist.dart';
import 'video_metadata_service.dart';

class AuthService {
  static User? _currentUser;
  static bool _initialized = false;
  static const String _defaultUserEmail = 'local_user@englishstudy.app';
  static const String _defaultUserName = '英语学习用户';

  static User? get currentUser => _currentUser;
  static bool get isSignedIn => _currentUser != null;

  static Future<AuthResult> initialize() async {
    if (_initialized) {
      print('AuthService.initialize: Already initialized, skipping');
      return AuthResult(success: true, user: _currentUser, message: '已初始化');
    }
    
    try {
      // Create a default local user
      _currentUser = User(
        id: 'local_user',
        email: _defaultUserEmail,
        name: _defaultUserName,
        photoUrl: null,
        playlist: Playlist(),
        recentVideoIds: [],
        favoriteVideoIds: [],
        videoProgress: {},
        preferences: UserPreferences(),
        stats: UserStats(),
      );
      
      // Load saved playlist from local storage
      await _loadPlaylistFromStorage();
      print('AuthService.initialize: Created local user with playlist length: ${_currentUser!.playlist.length}');
      
      _initialized = true;
      return AuthResult(success: true, user: _currentUser, message: '初始化成功');
    } catch (e) {
      print('Error initializing auth service: $e');
      return AuthResult(success: false, message: '初始化失败：${e.toString()}');
    }
  }

  // Single-user app doesn't need sign-in, just initialize
  static Future<AuthResult> signIn() async {
    return await initialize();
  }

  static Future<void> signOut() async {
    try {
      _currentUser = null;
      _initialized = false;
      print('User signed out');
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _currentUser = null;
      _initialized = false;
      print('All user data cleared');
    } catch (e) {
      print('Error clearing data: $e');
    }
  }

  static Future<User?> refreshUserData() async {
    try {
      if (_currentUser != null) {
        await _loadPlaylistFromStorage();
        return _currentUser;
      }
    } catch (e) {
      print('Error refreshing user data: $e');
    }
    return null;
  }

  static Future<bool> isUserSignedIn() async {
    return _currentUser != null;
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

  static Future<void> addToPlaylist(String videoId, {String? title, String? channelName, Duration? duration, String? thumbnail, String? description, String? category}) async {
    if (_currentUser == null) {
      print('AuthService.addToPlaylist: No current user, skipping');
      return;
    }
    
    print('AuthService.addToPlaylist: Adding video $videoId to playlist');

    try {
      // Check if video already exists in playlist to preserve its category
      final existingVideo = _currentUser!.playlist.getVideo(videoId);
      final finalCategory = category ?? existingVideo?.category ?? '未分类';
      
      PlaylistItem? item;
      
      // Try to get metadata from VideoMetadataService
      item = await VideoMetadataService.getVideoMetadata(videoId);
      
      // If metadata service returns null or incomplete data, create with provided data
      if (item == null) {
        item = PlaylistItem(
          videoId: videoId,
          title: title ?? existingVideo?.title ?? 'Video $videoId',
          channelName: channelName ?? existingVideo?.channelName,
          duration: duration ?? existingVideo?.duration,
          thumbnail: thumbnail ?? existingVideo?.thumbnail,
          description: description ?? existingVideo?.description,
          category: finalCategory,
        );
      } else {
        // Update with any additional data provided, preserving existing category if not specified
        item = item.copyWith(
          title: title ?? item.title,
          channelName: channelName ?? item.channelName,
          duration: duration ?? item.duration,
          thumbnail: thumbnail ?? item.thumbnail,
          description: description ?? item.description,
          category: finalCategory,
        );
      }

      final newPlaylist = _currentUser!.playlist.addVideo(item);
      _currentUser = _currentUser!.copyWith(playlist: newPlaylist);
      await _savePlaylistToStorage();
      print('AuthService.addToPlaylist: Video added successfully with category "$finalCategory", new playlist length: ${_currentUser!.playlist.length}');
    } catch (e) {
      print('AuthService.addToPlaylist: Error in main flow: $e');
      // Fallback: create with basic info, preserving existing category
      final existingVideo = _currentUser!.playlist.getVideo(videoId);
      final finalCategory = category ?? existingVideo?.category ?? '未分类';
      
      final item = PlaylistItem(
        videoId: videoId,
        title: title ?? existingVideo?.title ?? 'Video $videoId',
        channelName: channelName ?? existingVideo?.channelName,
        duration: duration ?? existingVideo?.duration,
        thumbnail: thumbnail ?? existingVideo?.thumbnail ?? 'https://img.youtube.com/vi/$videoId/mqdefault.jpg',
        description: description ?? existingVideo?.description,
        category: finalCategory,
      );

      final newPlaylist = _currentUser!.playlist.addVideo(item);
      _currentUser = _currentUser!.copyWith(playlist: newPlaylist);
      await _savePlaylistToStorage();
      print('AuthService.addToPlaylist: Video added via fallback with category "$finalCategory", new playlist length: ${_currentUser!.playlist.length}');
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
      await prefs.setString('user_playlist', playlistJson);
      print('AuthService: Saved playlist to storage with ${_currentUser!.playlist.length} items');
    } catch (e) {
      print('Error saving playlist to storage: $e');
    }
  }

  static Future<void> _loadPlaylistFromStorage() async {
    try {
      if (_currentUser == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      final playlistJsonString = prefs.getString('user_playlist');
      
      if (playlistJsonString != null) {
        final playlistJson = json.decode(playlistJsonString) as Map<String, dynamic>;
        final savedPlaylist = Playlist.fromJson(playlistJson);
        _currentUser = _currentUser!.copyWith(playlist: savedPlaylist);
        print('AuthService: Loaded playlist from storage with ${savedPlaylist.length} items');
      } else {
        print('AuthService: No saved playlist found in storage');
      }
    } catch (e) {
      print('Error loading playlist from storage: $e');
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