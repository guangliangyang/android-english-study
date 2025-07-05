import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/playlist.dart';

class YouTubePlaylistService {
  static const String _tag = 'YouTubePlaylistService';
  static const Duration _connectTimeout = Duration(seconds: 15);
  
  static final http.Client _client = http.Client();

  /// 从URL中提取播放列表ID
  static String? extractPlaylistId(String url) {
    try {
      // 支持的格式:
      // https://www.youtube.com/playlist?list=PLQ-uHSnFig5Ob4XXhgSK26Smb4oRhzFmK
      // https://youtube.com/playlist?list=PLQ-uHSnFig5Ob4XXhgSK26Smb4oRhzFmK
      // https://m.youtube.com/playlist?list=PLQ-uHSnFig5Ob4XXhgSK26Smb4oRhzFmK
      
      if (url.contains('playlist?list=')) {
        final match = RegExp(r'[?&]list=([^&]+)').firstMatch(url);
        return match?.group(1);
      }
    } catch (e) {
      developer.log('Error extracting playlist ID: $e', name: _tag);
    }
    return null;
  }

  /// 检查URL是否为YouTube播放列表
  static bool isPlaylistUrl(String url) {
    return extractPlaylistId(url) != null;
  }

  /// 获取播放列表信息
  static Future<PlaylistInfo?> getPlaylistInfo(String playlistId) async {
    try {
      developer.log('Fetching playlist info for: $playlistId', name: _tag);
      
      // 尝试从播放列表页面提取信息
      final playlistUrl = 'https://www.youtube.com/playlist?list=$playlistId';
      final response = await _client.get(
        Uri.parse(playlistUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      ).timeout(_connectTimeout);

      if (response.statusCode != 200) {
        developer.log('Failed to fetch playlist page: ${response.statusCode}', name: _tag);
        return null;
      }

      final html = response.body;
      
      // 提取播放列表标题
      String? title = _extractPlaylistTitle(html);
      
      // 提取创建者信息
      String? creator = _extractPlaylistCreator(html);
      
      // 提取视频ID列表
      List<String> videoIds = _extractVideoIds(html);
      
      if (title != null && videoIds.isNotEmpty) {
        developer.log('Successfully extracted playlist: title="$title", creator="$creator", videos=${videoIds.length}', name: _tag);
        return PlaylistInfo(
          id: playlistId,
          title: title,
          creator: creator,
          videoIds: videoIds,
          url: playlistUrl,
        );
      } else {
        developer.log('Failed to extract playlist: title=$title, videoCount=${videoIds.length}', name: _tag);
      }
      
    } catch (e) {
      developer.log('Error fetching playlist info: $e', name: _tag, error: e);
    }
    
    return null;
  }

  /// 从HTML中提取播放列表标题
  static String? _extractPlaylistTitle(String html) {
    // 按优先级排序的提取模式
    final patterns = [
      // 优先级1: HTML title标签 (最可靠)
      RegExp(r'<title[^>]*>([^<]+)</title>', caseSensitive: false),
      
      // 优先级2: og:title meta标签
      RegExp(r'<meta\s+property="og:title"\s+content="([^"]+)"', caseSensitive: false),
      
      // 优先级3: 播放列表专属的JSON字段
      RegExp(r'"playlistHeaderRenderer"[^}]*"title"[^}]*"text":"([^"]+)"'),
      RegExp(r'"metadata"[^}]*"playlistMetadataRenderer"[^}]*"title":"([^"]+)"'),
      RegExp(r'"playlistSidebarRenderer"[^}]*"title"[^}]*"text":"([^"]+)"'),
      
      // 优先级4: 通用title字段 (最后选择)
      RegExp(r'"title"\s*:\s*"([^"]+)"'),
    ];

    for (int i = 0; i < patterns.length; i++) {
      final pattern = patterns[i];
      final match = pattern.firstMatch(html);
      
      if (match != null && match.group(1) != null) {
        String title = match.group(1)!;
        
        // 清理标题
        title = _cleanTitle(title);
        
        // 验证标题是否有效
        if (_isValidPlaylistTitle(title, i)) {
          developer.log('Found playlist title using pattern $i: $title', name: _tag);
          return title;
        } else {
          developer.log('Rejected title from pattern $i: $title', name: _tag);
        }
      }
    }
    
    developer.log('No valid playlist title found', name: _tag);
    return null;
  }

  /// 清理提取的标题
  static String _cleanTitle(String title) {
    // Unicode 字符清理
    title = title.replaceAll(r'\u0026', '&');
    title = title.replaceAll(r'\\u0026', '&');
    title = title.replaceAll(r'\u003c', '<');
    title = title.replaceAll(r'\u003e', '>');
    title = title.replaceAll(r'\u0027', "'");
    title = title.replaceAll(r'\u0022', '"');
    
    // 路径分隔符清理
    title = title.replaceAll(r'\/', '/');
    title = title.replaceAll(r'\\', '');
    
    // 移除HTML实体
    title = title.replaceAll('&amp;', '&');
    title = title.replaceAll('&lt;', '<');
    title = title.replaceAll('&gt;', '>');
    title = title.replaceAll('&quot;', '"');
    title = title.replaceAll('&#39;', "'");
    
    title = title.trim();
    
    // 移除 " - YouTube" 后缀
    if (title.endsWith(' - YouTube')) {
      title = title.substring(0, title.length - 10);
    }
    
    return title;
  }

  /// 验证标题是否为有效的播放列表标题
  static bool _isValidPlaylistTitle(String title, int patternIndex) {
    if (title.isEmpty) return false;
    
    // 对于HTML title标签和og:title，标准更宽松
    if (patternIndex <= 1) {
      // 只要不是明显的错误即可
      return title.length >= 2 && 
             !title.toLowerCase().startsWith('watch') &&
             !title.toLowerCase().startsWith('youtube') &&
             !title.contains('|') && // 避免复合标题
             !title.contains('·'); // 避免复合标题
    }
    
    // 对于JSON字段，标准更严格
    return title.length >= 3 && 
           !title.toLowerCase().contains('video') &&
           !title.toLowerCase().contains('watch') &&
           !title.toLowerCase().contains('youtube');
  }

  /// 从HTML中提取创建者信息
  static String? _extractPlaylistCreator(String html) {
    final patterns = [
      // 优先级1: 播放列表专属的创建者字段
      RegExp(r'"ownerText"[^}]*"text":"([^"]+)"'),
      RegExp(r'"playlistHeaderRenderer"[^}]*"ownerText"[^}]*"text":"([^"]+)"'),
      
      // 优先级2: 通用创建者字段
      RegExp(r'"author":"([^"]+)"'),
      RegExp(r'<meta\s+name="author"\s+content="([^"]+)"', caseSensitive: false),
      
      // 优先级3: 频道相关字段
      RegExp(r'"channelName":"([^"]+)"'),
      RegExp(r'"subscriberCountText"[^}]*"text":"([^"]+)"'),
    ];

    for (int i = 0; i < patterns.length; i++) {
      final pattern = patterns[i];
      final match = pattern.firstMatch(html);
      
      if (match != null && match.group(1) != null) {
        String creator = match.group(1)!;
        creator = _cleanTitle(creator); // 使用相同的清理逻辑
        
        // 验证创建者名称
        if (_isValidCreatorName(creator)) {
          developer.log('Found playlist creator using pattern $i: $creator', name: _tag);
          return creator;
        } else {
          developer.log('Rejected creator from pattern $i: $creator', name: _tag);
        }
      }
    }
    
    return null;
  }

  /// 验证创建者名称是否有效
  static bool _isValidCreatorName(String creator) {
    if (creator.isEmpty || creator.length < 2) return false;
    
    // 过滤掉明显不是创建者名称的内容
    final lowerCreator = creator.toLowerCase();
    return !lowerCreator.contains('subscribe') &&
           !lowerCreator.contains('subscriber') &&
           !lowerCreator.contains('view') &&
           !lowerCreator.contains('youtube') &&
           !lowerCreator.contains('playlist') &&
           creator.length <= 50; // 创建者名称不应该太长
  }

  /// 从HTML中提取视频ID列表
  static List<String> _extractVideoIds(String html) {
    final videoIds = <String>{};
    
    // 多种模式提取视频ID
    final patterns = [
      RegExp(r'"videoId":"([^"]+)"'),
      RegExp(r'/watch\?v=([^&"]+)'),
      RegExp(r'"playlistVideoRenderer":[^}]*"videoId":"([^"]+)"'),
    ];

    for (int i = 0; i < patterns.length; i++) {
      final pattern = patterns[i];
      final matches = pattern.allMatches(html);
      int foundCount = 0;
      
      for (final match in matches) {
        final videoId = match.group(1);
        if (videoId != null && videoId.length == 11) {
          videoIds.add(videoId);
          foundCount++;
        }
      }
      
      if (foundCount > 0) {
        developer.log('Pattern $i found $foundCount video IDs', name: _tag);
      }
    }
    
    final uniqueVideoIds = videoIds.toList();
    developer.log('Total unique video IDs extracted: ${uniqueVideoIds.length}', name: _tag);
    return uniqueVideoIds;
  }

  /// 获取播放列表的所有视频详细信息
  static Future<List<PlaylistItem>> getPlaylistVideos(PlaylistInfo playlistInfo) async {
    final videos = <PlaylistItem>[];
    
    developer.log('Fetching ${playlistInfo.videoIds.length} videos from playlist: ${playlistInfo.title}', name: _tag);
    
    for (final videoId in playlistInfo.videoIds) {
      try {
        // 导入VideoMetadataService来获取视频详细信息
        final metadata = await _getVideoBasicInfo(videoId);
        
        final video = PlaylistItem(
          videoId: videoId,
          title: metadata['title'] ?? 'Video $videoId',
          thumbnail: metadata['thumbnail'] ?? 'https://img.youtube.com/vi/$videoId/mqdefault.jpg',
          duration: metadata['duration'],
          channelName: metadata['channelName'] ?? playlistInfo.creator,
          category: playlistInfo.title, // 使用播放列表标题作为分类
        );
        
        videos.add(video);
        
        // 添加小延迟避免请求过快
        await Future.delayed(const Duration(milliseconds: 100));
        
      } catch (e) {
        developer.log('Error fetching video $videoId: $e', name: _tag);
        
        // 即使获取失败也添加基本信息
        final video = PlaylistItem(
          videoId: videoId,
          title: 'Video $videoId',
          thumbnail: 'https://img.youtube.com/vi/$videoId/mqdefault.jpg',
          channelName: playlistInfo.creator,
          category: playlistInfo.title,
        );
        videos.add(video);
      }
    }
    
    return videos;
  }

  /// 获取单个视频的基本信息（简化版，避免循环依赖）
  static Future<Map<String, dynamic>> _getVideoBasicInfo(String videoId) async {
    try {
      // 使用oEmbed API获取基本信息
      final oembedUrl = 'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json';
      final response = await _client.get(Uri.parse(oembedUrl)).timeout(_connectTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'title': data['title'],
          'thumbnail': data['thumbnail_url'],
          'channelName': data['author_name'],
          'duration': null, // oEmbed不提供时长信息
        };
      }
    } catch (e) {
      developer.log('Error fetching video basic info: $e', name: _tag);
    }
    
    return {
      'title': 'Video $videoId',
      'thumbnail': 'https://img.youtube.com/vi/$videoId/mqdefault.jpg',
      'channelName': null,
      'duration': null,
    };
  }
}

/// 播放列表信息类
class PlaylistInfo {
  final String id;
  final String title;
  final String? creator;
  final List<String> videoIds;
  final String url;

  PlaylistInfo({
    required this.id,
    required this.title,
    this.creator,
    required this.videoIds,
    required this.url,
  });

  @override
  String toString() {
    return 'PlaylistInfo(title: $title, creator: $creator, videos: ${videoIds.length})';
  }
}