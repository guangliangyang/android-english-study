import 'package:google_sign_in/google_sign_in.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final UserPreferences preferences;
  final List<String> recentVideoIds;
  final Map<String, double> videoProgress;
  final List<String> favoriteVideoIds;
  final UserStats stats;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    UserPreferences? preferences,
    List<String>? recentVideoIds,
    Map<String, double>? videoProgress,
    List<String>? favoriteVideoIds,
    UserStats? stats,
  }) : createdAt = createdAt ?? DateTime.now(),
        lastActiveAt = lastActiveAt ?? DateTime.now(),
        preferences = preferences ?? UserPreferences(),
        recentVideoIds = recentVideoIds ?? [],
        videoProgress = videoProgress ?? {},
        favoriteVideoIds = favoriteVideoIds ?? [],
        stats = stats ?? UserStats();

  factory User.fromGoogleSignInAccount(GoogleSignInAccount account) {
    return User(
      id: account.id,
      name: account.displayName ?? '',
      email: account.email,
      photoUrl: account.photoUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
      'preferences': preferences.toJson(),
      'recentVideoIds': recentVideoIds,
      'videoProgress': videoProgress,
      'favoriteVideoIds': favoriteVideoIds,
      'stats': stats.toJson(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      photoUrl: json['photoUrl'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      lastActiveAt: DateTime.tryParse(json['lastActiveAt'] ?? '') ?? DateTime.now(),
      preferences: UserPreferences.fromJson(json['preferences'] ?? {}),
      recentVideoIds: List<String>.from(json['recentVideoIds'] ?? []),
      videoProgress: Map<String, double>.from(json['videoProgress'] ?? {}),
      favoriteVideoIds: List<String>.from(json['favoriteVideoIds'] ?? []),
      stats: UserStats.fromJson(json['stats'] ?? {}),
    );
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    UserPreferences? preferences,
    List<String>? recentVideoIds,
    Map<String, double>? videoProgress,
    List<String>? favoriteVideoIds,
    UserStats? stats,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      preferences: preferences ?? this.preferences,
      recentVideoIds: recentVideoIds ?? this.recentVideoIds,
      videoProgress: videoProgress ?? this.videoProgress,
      favoriteVideoIds: favoriteVideoIds ?? this.favoriteVideoIds,
      stats: stats ?? this.stats,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id && other.email == email;
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}

class UserPreferences {
  final bool showChineseTranslation;
  final bool showPronunciation;
  final bool autoPlayNext;
  final double playbackSpeed;
  final bool loopMode;
  final bool darkMode;
  final String language;
  final bool showTimestamps;
  final bool highlightCurrentSegment;
  final double fontSize;

  UserPreferences({
    this.showChineseTranslation = true,
    this.showPronunciation = false,
    this.autoPlayNext = false,
    this.playbackSpeed = 1.0,
    this.loopMode = false,
    this.darkMode = true,
    this.language = 'en',
    this.showTimestamps = true,
    this.highlightCurrentSegment = true,
    this.fontSize = 16.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'showChineseTranslation': showChineseTranslation,
      'showPronunciation': showPronunciation,
      'autoPlayNext': autoPlayNext,
      'playbackSpeed': playbackSpeed,
      'loopMode': loopMode,
      'darkMode': darkMode,
      'language': language,
      'showTimestamps': showTimestamps,
      'highlightCurrentSegment': highlightCurrentSegment,
      'fontSize': fontSize,
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      showChineseTranslation: json['showChineseTranslation'] ?? true,
      showPronunciation: json['showPronunciation'] ?? false,
      autoPlayNext: json['autoPlayNext'] ?? false,
      playbackSpeed: (json['playbackSpeed'] ?? 1.0).toDouble(),
      loopMode: json['loopMode'] ?? false,
      darkMode: json['darkMode'] ?? true,
      language: json['language'] ?? 'en',
      showTimestamps: json['showTimestamps'] ?? true,
      highlightCurrentSegment: json['highlightCurrentSegment'] ?? true,
      fontSize: (json['fontSize'] ?? 16.0).toDouble(),
    );
  }

  UserPreferences copyWith({
    bool? showChineseTranslation,
    bool? showPronunciation,
    bool? autoPlayNext,
    double? playbackSpeed,
    bool? loopMode,
    bool? darkMode,
    String? language,
    bool? showTimestamps,
    bool? highlightCurrentSegment,
    double? fontSize,
  }) {
    return UserPreferences(
      showChineseTranslation: showChineseTranslation ?? this.showChineseTranslation,
      showPronunciation: showPronunciation ?? this.showPronunciation,
      autoPlayNext: autoPlayNext ?? this.autoPlayNext,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      loopMode: loopMode ?? this.loopMode,
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
      showTimestamps: showTimestamps ?? this.showTimestamps,
      highlightCurrentSegment: highlightCurrentSegment ?? this.highlightCurrentSegment,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

class UserStats {
  final int totalVideosWatched;
  final int totalTimeSpent; // in seconds
  final int totalWordsLearned;
  final Map<String, int> dailyActivity; // date -> minutes spent
  final DateTime lastStudyDate;
  final int streak; // consecutive days of study
  final int totalSegmentsClicked;
  final Map<String, int> categoryStats; // category -> videos watched

  UserStats({
    this.totalVideosWatched = 0,
    this.totalTimeSpent = 0,
    this.totalWordsLearned = 0,
    Map<String, int>? dailyActivity,
    DateTime? lastStudyDate,
    this.streak = 0,
    this.totalSegmentsClicked = 0,
    Map<String, int>? categoryStats,
  }) : dailyActivity = dailyActivity ?? {},
        lastStudyDate = lastStudyDate ?? DateTime.now(),
        categoryStats = categoryStats ?? {};

  Map<String, dynamic> toJson() {
    return {
      'totalVideosWatched': totalVideosWatched,
      'totalTimeSpent': totalTimeSpent,
      'totalWordsLearned': totalWordsLearned,
      'dailyActivity': dailyActivity,
      'lastStudyDate': lastStudyDate.toIso8601String(),
      'streak': streak,
      'totalSegmentsClicked': totalSegmentsClicked,
      'categoryStats': categoryStats,
    };
  }

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalVideosWatched: json['totalVideosWatched'] ?? 0,
      totalTimeSpent: json['totalTimeSpent'] ?? 0,
      totalWordsLearned: json['totalWordsLearned'] ?? 0,
      dailyActivity: Map<String, int>.from(json['dailyActivity'] ?? {}),
      lastStudyDate: DateTime.tryParse(json['lastStudyDate'] ?? '') ?? DateTime.now(),
      streak: json['streak'] ?? 0,
      totalSegmentsClicked: json['totalSegmentsClicked'] ?? 0,
      categoryStats: Map<String, int>.from(json['categoryStats'] ?? {}),
    );
  }

  UserStats copyWith({
    int? totalVideosWatched,
    int? totalTimeSpent,
    int? totalWordsLearned,
    Map<String, int>? dailyActivity,
    DateTime? lastStudyDate,
    int? streak,
    int? totalSegmentsClicked,
    Map<String, int>? categoryStats,
  }) {
    return UserStats(
      totalVideosWatched: totalVideosWatched ?? this.totalVideosWatched,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
      totalWordsLearned: totalWordsLearned ?? this.totalWordsLearned,
      dailyActivity: dailyActivity ?? this.dailyActivity,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      streak: streak ?? this.streak,
      totalSegmentsClicked: totalSegmentsClicked ?? this.totalSegmentsClicked,
      categoryStats: categoryStats ?? this.categoryStats,
    );
  }

  String get formattedTotalTime {
    final hours = totalTimeSpent ~/ 3600;
    final minutes = (totalTimeSpent % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  double get averageTimePerVideo {
    if (totalVideosWatched == 0) return 0.0;
    return totalTimeSpent / totalVideosWatched;
  }

  int get todayMinutes {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return dailyActivity[todayKey] ?? 0;
  }
}