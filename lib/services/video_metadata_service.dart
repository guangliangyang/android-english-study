import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/playlist.dart';

class VideoMetadataService {
  static const String _tag = 'VideoMetadataService';
  static const Duration _connectTimeout = Duration(seconds: 10);
  
  static final http.Client _client = http.Client();

  /// 获取YouTube视频的元数据信息
  static Future<PlaylistItem?> getVideoMetadata(String videoId) async {
    try {
      developer.log('Fetching metadata for video: $videoId', name: _tag);
      
      // 方法1: 尝试从YouTube页面HTML提取信息
      final item = await _extractFromVideoPage(videoId);
      if (item != null) {
        return item;
      }
      
      // 方法2: 从oEmbed API获取基本信息
      return await _getFromOEmbed(videoId);
      
    } catch (e) {
      developer.log('Error fetching video metadata: $e', name: _tag, error: e);
      
      // 返回基本的PlaylistItem
      return PlaylistItem(
        videoId: videoId,
        title: 'Video $videoId',
        thumbnail: 'https://img.youtube.com/vi/$videoId/mqdefault.jpg',
      );
    }
  }

  /// 从YouTube视频页面HTML提取元数据
  static Future<PlaylistItem?> _extractFromVideoPage(String videoId) async {
    try {
      final videoUrl = 'https://www.youtube.com/watch?v=$videoId';
      final response = await _client.get(
        Uri.parse(videoUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      ).timeout(_connectTimeout);

      if (response.statusCode != 200) {
        developer.log('Failed to fetch video page: ${response.statusCode}', name: _tag);
        return null;
      }

      final html = response.body;
      
      // 提取标题
      String? title = _extractTitle(html);
      
      // 提取频道名称
      String? channelName = _extractChannelName(html);
      
      // 提取视频时长
      Duration? duration = _extractDuration(html);
      
      // 提取描述
      String? description = _extractDescription(html);

      if (title != null) {
        return PlaylistItem(
          videoId: videoId,
          title: title,
          thumbnail: 'https://img.youtube.com/vi/$videoId/mqdefault.jpg',
          duration: duration,
          channelName: channelName,
          description: description,
        );
      }
      
    } catch (e) {
      developer.log('Error extracting from video page: $e', name: _tag);
    }
    
    return null;
  }

  /// 从YouTube oEmbed API获取基本信息
  static Future<PlaylistItem?> _getFromOEmbed(String videoId) async {
    try {
      final oembedUrl = 'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json';
      final response = await _client.get(Uri.parse(oembedUrl)).timeout(_connectTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PlaylistItem(
          videoId: videoId,
          title: data['title'] ?? 'Unknown Title',
          thumbnail: data['thumbnail_url'] ?? 'https://img.youtube.com/vi/$videoId/mqdefault.jpg',
          channelName: data['author_name'],
        );
      }
    } catch (e) {
      developer.log('Error fetching from oEmbed: $e', name: _tag);
    }
    
    return null;
  }

  /// 从HTML中提取视频标题
  static String? _extractTitle(String html) {
    // 尝试多种方法提取标题
    final patterns = [
      RegExp(r'"title":\s*"([^"]+)"'),
      RegExp(r'<title[^>]*>([^<]+)</title>', caseSensitive: false),
      RegExp(r'"videoDetails":\s*{[^}]*"title":\s*"([^"]+)"'),
      RegExp(r'<meta\s+property="og:title"\s+content="([^"]+)"', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      if (match != null && match.group(1) != null) {
        String title = match.group(1)!;
        // 清理标题
        title = title.replaceAll(r'\u0026', '&');
        title = title.replaceAll(r'\\u0026', '&');
        title = title.replaceAll(r'\/', '/');
        title = title.replaceAll(r'\\', '');
        title = title.trim();
        
        // 移除 " - YouTube" 后缀
        if (title.endsWith(' - YouTube')) {
          title = title.substring(0, title.length - 10);
        }
        
        if (title.isNotEmpty) {
          return title;
        }
      }
    }
    
    return null;
  }

  /// 从HTML中提取频道名称
  static String? _extractChannelName(String html) {
    final patterns = [
      RegExp(r'"author":\s*"([^"]+)"'),
      RegExp(r'"channelMetadata":\s*{[^}]*"title":\s*"([^"]+)"'),
      RegExp(r'<meta\s+name="author"\s+content="([^"]+)"', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      if (match != null && match.group(1) != null) {
        String channelName = match.group(1)!;
        channelName = channelName.replaceAll(r'\u0026', '&');
        channelName = channelName.replaceAll(r'\\u0026', '&');
        channelName = channelName.trim();
        
        if (channelName.isNotEmpty) {
          return channelName;
        }
      }
    }
    
    return null;
  }

  /// 从HTML中提取视频时长
  static Duration? _extractDuration(String html) {
    final patterns = [
      RegExp(r'"lengthSeconds":\s*"(\d+)"'),
      RegExp(r'"duration":\s*"(\d+)"'),
      RegExp(r'content="PT(\d+)(?:H(\d+))?(?:M(\d+))?(?:S(\d+))?'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      if (match != null) {
        if (pattern == patterns[2]) {
          // ISO 8601 duration format
          final hours = int.tryParse(match.group(2) ?? '0') ?? 0;
          final minutes = int.tryParse(match.group(3) ?? '0') ?? 0;
          final seconds = int.tryParse(match.group(4) ?? '0') ?? 0;
          return Duration(hours: hours, minutes: minutes, seconds: seconds);
        } else {
          // Seconds format
          final seconds = int.tryParse(match.group(1) ?? '0');
          if (seconds != null && seconds > 0) {
            return Duration(seconds: seconds);
          }
        }
      }
    }
    
    return null;
  }

  /// 从HTML中提取视频描述
  static String? _extractDescription(String html) {
    final patterns = [
      RegExp(r'"shortDescription":\s*"([^"]*)"'),
      RegExp(r'<meta\s+property="og:description"\s+content="([^"]*)"', caseSensitive: false),
      RegExp(r'<meta\s+name="description"\s+content="([^"]*)"', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      if (match != null && match.group(1) != null) {
        String description = match.group(1)!;
        description = description.replaceAll(r'\n', '\n');
        description = description.replaceAll(r'\u0026', '&');
        description = description.replaceAll(r'\\u0026', '&');
        description = description.trim();
        
        if (description.isNotEmpty) {
          // 限制描述长度
          if (description.length > 200) {
            description = description.substring(0, 200) + '...';
          }
          return description;
        }
      }
    }
    
    return null;
  }

  /// 获取视频缩略图URL
  static String getThumbnailUrl(String videoId, {String quality = 'mqdefault'}) {
    // 可用的质量选项: default, mqdefault, hqdefault, sddefault, maxresdefault
    return 'https://img.youtube.com/vi/$videoId/$quality.jpg';
  }

  /// 获取不同质量的缩略图URLs
  static Map<String, String> getAllThumbnailUrls(String videoId) {
    return {
      'default': getThumbnailUrl(videoId, quality: 'default'),
      'medium': getThumbnailUrl(videoId, quality: 'mqdefault'),
      'high': getThumbnailUrl(videoId, quality: 'hqdefault'),
      'standard': getThumbnailUrl(videoId, quality: 'sddefault'),
      'maxres': getThumbnailUrl(videoId, quality: 'maxresdefault'),
    };
  }
}