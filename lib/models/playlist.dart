class PlaylistItem {
  final String videoId;
  final String title;
  final String? thumbnail;
  final Duration? duration;
  final DateTime addedAt;
  final String? channelName;
  final String? description;
  final String category;

  PlaylistItem({
    required this.videoId,
    required this.title,
    this.thumbnail,
    this.duration,
    DateTime? addedAt,
    this.channelName,
    this.description,
    this.category = '未分类',
  }) : addedAt = addedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'title': title,
      'thumbnail': thumbnail,
      'duration': duration?.inSeconds,
      'addedAt': addedAt.toIso8601String(),
      'channelName': channelName,
      'description': description,
      'category': category,
    };
  }

  factory PlaylistItem.fromJson(Map<String, dynamic> json) {
    return PlaylistItem(
      videoId: json['videoId'] ?? '',
      title: json['title'] ?? '',
      thumbnail: json['thumbnail'],
      duration: json['duration'] != null ? Duration(seconds: json['duration']) : null,
      addedAt: DateTime.tryParse(json['addedAt'] ?? '') ?? DateTime.now(),
      channelName: json['channelName'],
      description: json['description'],
      category: json['category'] ?? '未分类',
    );
  }

  PlaylistItem copyWith({
    String? videoId,
    String? title,
    String? thumbnail,
    Duration? duration,
    DateTime? addedAt,
    String? channelName,
    String? description,
    String? category,
  }) {
    return PlaylistItem(
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      thumbnail: thumbnail ?? this.thumbnail,
      duration: duration ?? this.duration,
      addedAt: addedAt ?? this.addedAt,
      channelName: channelName ?? this.channelName,
      description: description ?? this.description,
      category: category ?? this.category,
    );
  }

  String get formattedDuration {
    if (duration == null) return '';
    final hours = duration!.inHours;
    final minutes = duration!.inMinutes % 60;
    final seconds = duration!.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  String get youtubeUrl => 'https://www.youtube.com/watch?v=$videoId';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlaylistItem && other.videoId == videoId;
  }

  @override
  int get hashCode => videoId.hashCode;

  @override
  String toString() {
    return 'PlaylistItem(videoId: $videoId, title: $title)';
  }
}

class Playlist {
  final List<PlaylistItem> items;
  final DateTime lastUpdated;

  Playlist({
    List<PlaylistItem>? items,
    DateTime? lastUpdated,
  }) : items = items ?? [],
        lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      items: (json['items'] as List?)
          ?.map((item) => PlaylistItem.fromJson(item))
          .toList() ?? [],
      lastUpdated: DateTime.tryParse(json['lastUpdated'] ?? '') ?? DateTime.now(),
    );
  }

  Playlist copyWith({
    List<PlaylistItem>? items,
    DateTime? lastUpdated,
  }) {
    return Playlist(
      items: items ?? this.items,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // 添加视频到播放列表
  Playlist addVideo(PlaylistItem item) {
    final newItems = List<PlaylistItem>.from(items);
    
    // 如果视频已存在，移除旧的
    newItems.removeWhere((existingItem) => existingItem.videoId == item.videoId);
    
    // 在开头添加新视频
    newItems.insert(0, item);
    
    // 保持最多50个视频
    if (newItems.length > 50) {
      newItems.removeRange(50, newItems.length);
    }
    
    return copyWith(
      items: newItems,
      lastUpdated: DateTime.now(),
    );
  }

  // 移除视频
  Playlist removeVideo(String videoId) {
    final newItems = items.where((item) => item.videoId != videoId).toList();
    return copyWith(
      items: newItems,
      lastUpdated: DateTime.now(),
    );
  }

  // 检查视频是否存在
  bool containsVideo(String videoId) {
    return items.any((item) => item.videoId == videoId);
  }

  // 获取视频
  PlaylistItem? getVideo(String videoId) {
    try {
      return items.firstWhere((item) => item.videoId == videoId);
    } catch (e) {
      return null;
    }
  }

  // 清空播放列表
  Playlist clear() {
    return copyWith(
      items: [],
      lastUpdated: DateTime.now(),
    );
  }

  // 更新视频分类
  Playlist updateVideoCategory(String videoId, String newCategory) {
    final newItems = items.map((item) {
      if (item.videoId == videoId) {
        return item.copyWith(category: newCategory);
      }
      return item;
    }).toList();
    
    return copyWith(
      items: newItems,
      lastUpdated: DateTime.now(),
    );
  }

  // 获取所有分类
  List<String> get categories {
    final categorySet = <String>{};
    for (final item in items) {
      categorySet.add(item.category);
    }
    return categorySet.toList()..sort();
  }

  // 根据分类筛选视频
  List<PlaylistItem> getVideosByCategory(String category) {
    return items.where((item) => item.category == category).toList();
  }

  // 获取总时长
  Duration get totalDuration {
    return items.fold(Duration.zero, (total, item) {
      return total + (item.duration ?? Duration.zero);
    });
  }

  String get formattedTotalDuration {
    final total = totalDuration;
    final hours = total.inHours;
    final minutes = total.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  int get length => items.length;
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  @override
  String toString() {
    return 'Playlist(items: ${items.length}, lastUpdated: $lastUpdated)';
  }
}