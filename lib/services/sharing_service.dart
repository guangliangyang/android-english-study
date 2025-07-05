import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/playlist.dart';

class SharingService {
  static const String _shareHeader = '📚【英语学习分享】来自「LearnMate App」';
  static const String _importInstructions = '''
💡 如何导入？
复制这段文字，打开 LearnMate App，在「导入学习资源」中粘贴，即可保存到你的学习计划！
''';

  /// 生成分享文本
  static String generateShareText(String categoryName, List<PlaylistItem> videos) {
    final buffer = StringBuffer();
    
    // 添加头部
    buffer.writeln(_shareHeader);
    buffer.writeln();
    
    // 添加分类信息
    buffer.writeln('🗂 主分类：$categoryName');
    buffer.writeln();
    
    // 添加视频列表
    buffer.writeln('🎥 视频清单：');
    for (int i = 0; i < videos.length; i++) {
      final video = videos[i];
      buffer.writeln('${i + 1}. ${video.title}');
      buffer.writeln('   📂 分类：${video.category}');
      buffer.writeln('   🔗 链接：${video.youtubeUrl}');
      if (i < videos.length - 1) buffer.writeln();
    }
    
    buffer.writeln();
    buffer.writeln(_importInstructions);
    
    return buffer.toString();
  }

  /// 分享到系统
  static Future<void> shareToSystem(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// 检测剪贴板中是否有分享内容
  static Future<ShareParseResult?> detectShareContent() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text?.trim();
      
      if (text == null || text.isEmpty) {
        return null;
      }
      
      return parseShareText(text);
    } catch (e) {
      return null;
    }
  }

  /// 解析分享文本
  static ShareParseResult? parseShareText(String text) {
    try {
      // 检查是否包含分享头部
      if (!text.contains('英语学习分享') || !text.contains('LearnMate App')) {
        return null;
      }
      
      final lines = text.split('\n').map((line) => line.trim()).toList();
      
      String? categoryName;
      List<ShareVideoItem> videos = [];
      
      bool inVideoSection = false;
      ShareVideoItem? currentVideo;
      
      for (String line in lines) {
        if (line.isEmpty) continue;
        
        // 解析主分类
        if (line.startsWith('🗂 主分类：')) {
          categoryName = line.substring('🗂 主分类：'.length).trim();
        }
        // 兼容旧格式
        else if (line.startsWith('🗂 分类：')) {
          categoryName = line.substring('🗂 分类：'.length).trim();
        }
        
        // 检测视频清单开始
        if (line.contains('🎥 视频清单：')) {
          inVideoSection = true;
          continue;
        }
        
        // 检测导入说明开始（视频清单结束）
        if (line.contains('💡 如何导入？')) {
          inVideoSection = false;
          if (currentVideo != null) {
            videos.add(currentVideo);
            currentVideo = null;
          }
          break;
        }
        
        if (inVideoSection) {
          // 检测视频标题行 (数字. 标题)
          final titleMatch = RegExp(r'^\d+\.\s+(.+)$').firstMatch(line);
          if (titleMatch != null) {
            // 保存上一个视频
            if (currentVideo != null) {
              videos.add(currentVideo);
            }
            // 开始新视频
            currentVideo = ShareVideoItem(
              title: titleMatch.group(1)!.trim(),
              url: '',
              category: categoryName ?? '未分类', // 默认使用主分类
            );
          }
          // 检测分类行 (📂 分类：xxx)
          else if (line.startsWith('📂 分类：')) {
            if (currentVideo != null) {
              final videoCategory = line.substring('📂 分类：'.length).trim();
              currentVideo = ShareVideoItem(
                title: currentVideo.title,
                url: currentVideo.url,
                category: videoCategory,
              );
            }
          }
          // 检测链接行 (🔗 链接：xxx 或直接的URL)
          else if (line.startsWith('🔗 链接：')) {
            final url = line.substring('🔗 链接：'.length).trim();
            if (currentVideo != null) {
              currentVideo = ShareVideoItem(
                title: currentVideo.title,
                url: url,
                category: currentVideo.category,
              );
            }
          }
          // 兼容旧格式：直接的URL行
          else if (line.startsWith('https://www.youtube.com/watch?v=') || 
                   line.startsWith('https://youtu.be/')) {
            if (currentVideo != null) {
              currentVideo = ShareVideoItem(
                title: currentVideo.title,
                url: line,
                category: currentVideo.category,
              );
            }
          }
        }
      }
      
      // 添加最后一个视频
      if (currentVideo != null) {
        videos.add(currentVideo);
      }
      
      if (categoryName == null || videos.isEmpty) {
        return null;
      }
      
      return ShareParseResult(
        categoryName: categoryName,
        videos: videos,
      );
    } catch (e) {
      return null;
    }
  }
}

class ShareVideoItem {
  final String title;
  final String url;
  final String category;
  
  ShareVideoItem({
    required this.title,
    required this.url,
    this.category = '未分类',
  });
  
  String? get videoId {
    if (url.contains('youtube.com/watch?v=')) {
      final match = RegExp(r'[?&]v=([^&]+)').firstMatch(url);
      return match?.group(1);
    } else if (url.contains('youtu.be/')) {
      final match = RegExp(r'youtu\.be/([^?]+)').firstMatch(url);
      return match?.group(1);
    }
    return null;
  }
}

class ShareParseResult {
  final String categoryName;
  final List<ShareVideoItem> videos;
  
  ShareParseResult({
    required this.categoryName,
    required this.videos,
  });
  
  List<ShareVideoItem> get validVideos {
    return videos.where((video) => video.videoId != null).toList();
  }
}