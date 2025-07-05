import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/transcript.dart';

class TranscriptService {
  static const String _tag = 'TranscriptService';
  static const Duration _connectTimeout = Duration(seconds: 15);
  static const Duration _receiveTimeout = Duration(seconds: 30);

  static final http.Client _client = http.Client();

  static Future<Transcript?> getTranscript(String videoId) async {
    try {
      developer.log('Fetching transcript for video: $videoId using youtube-transcript-api approach', name: _tag);
      
      // 使用类似youtube-transcript-api的方法
      return await _fetchTranscriptViaInnerTubeAPI(videoId);
      
    } catch (e) {
      developer.log('Error fetching transcript: $e', name: _tag, error: e);
      return null;
    }
  }

  static Future<Transcript?> _fetchTranscriptViaInnerTubeAPI(String videoId) async {
    try {
      developer.log('Step 1: Fetching video HTML to extract InnerTube API key', name: _tag);
      
      // 步骤1：获取视频页面HTML
      final videoUrl = 'https://www.youtube.com/watch?v=$videoId';
      final htmlResponse = await _client.get(
        Uri.parse(videoUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      ).timeout(_connectTimeout);

      if (htmlResponse.statusCode != 200) {
        developer.log('Failed to fetch video HTML: ${htmlResponse.statusCode}', name: _tag);
        return null;
      }

      final html = htmlResponse.body;
      developer.log('Fetched video HTML, length: ${html.length}', name: _tag);

      // 步骤2：提取InnerTube API key
      final apiKey = _extractInnerTubeApiKey(html);
      if (apiKey == null) {
        developer.log('Could not extract InnerTube API key from HTML', name: _tag);
        return null;
      }

      developer.log('Step 2: Extracted InnerTube API key: $apiKey', name: _tag);

      // 步骤3：调用InnerTube API获取字幕数据
      final innerTubeData = await _fetchInnerTubeData(videoId, apiKey);
      if (innerTubeData == null) {
        developer.log('Failed to fetch InnerTube data', name: _tag);
        return null;
      }

      developer.log('Step 3: Got InnerTube data, parsing captions...', name: _tag);

      // 步骤4：解析字幕数据
      return await _parseInnerTubeCaptionsData(innerTubeData, videoId);

    } catch (e) {
      developer.log('Error in fetchTranscriptViaInnerTubeAPI: $e', name: _tag, error: e);
      return null;
    }
  }

  static String? _extractInnerTubeApiKey(String html) {
    try {
      // 查找InnerTube API key的多种模式
      final patterns = [
        r'"innertubeApiKey"\s*:\s*"([^"]+)"',
        r'"INNERTUBE_API_KEY"\s*:\s*"([^"]+)"',
        r'innertubeApiKey"\s*:\s*"([^"]+)"',
        r'INNERTUBE_API_KEY"\s*:\s*"([^"]+)"',
      ];

      for (final pattern in patterns) {
        final regex = RegExp(pattern);
        final match = regex.firstMatch(html);
        if (match != null) {
          final apiKey = match.group(1);
          if (apiKey != null && apiKey.isNotEmpty) {
            developer.log('Found API key with pattern: $pattern', name: _tag);
            return apiKey;
          }
        }
      }

      developer.log('No InnerTube API key found in HTML', name: _tag);
      return null;

    } catch (e) {
      developer.log('Error extracting API key: $e', name: _tag, error: e);
      return null;
    }
  }

  static Future<String?> _fetchInnerTubeData(String videoId, String apiKey) async {
    try {
      developer.log('Calling InnerTube API with key: $apiKey', name: _tag);

      // 构建InnerTube API请求 - 使用youtube-transcript-api的格式
      final requestBody = {
        'context': {
          'client': {
            'clientName': 'ANDROID',
            'clientVersion': '20.10.38'
          }
        },
        'videoId': videoId
      };

      final response = await _client.post(
        Uri.parse('https://www.youtube.com/youtubei/v1/player?key=$apiKey'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36',
          'Accept': '*/*',
          'Content-Type': 'application/json',
          'Accept-Language': 'en-US,en;q=0.9',
        },
        body: json.encode(requestBody),
      ).timeout(_receiveTimeout);

      developer.log('InnerTube API response code: ${response.statusCode}', name: _tag);

      if (response.statusCode != 200) {
        developer.log('InnerTube API failed: ${response.statusCode} - ${response.body}', name: _tag);
        return null;
      }

      final responseBody = response.body;
      developer.log('InnerTube API response length: ${responseBody.length}', name: _tag);
      // developer.log('Response preview: ${responseBody.substring(0, responseBody.length > 300 ? 300 : responseBody.length)}...', name: _tag);

      return responseBody;

    } catch (e) {
      developer.log('Error calling InnerTube API: $e', name: _tag, error: e);
      return null;
    }
  }

  static Future<Transcript?> _parseInnerTubeCaptionsData(String jsonData, String videoId) async {
    try {
      final jsonObject = json.decode(jsonData) as Map<String, dynamic>;

      // 打印响应长度以调试（避免日志过长）
      developer.log('Parsing API response length: ${jsonData.length}', name: _tag);

      // 解析Player API响应中的字幕轨道信息
      final captions = jsonObject['captions'] as Map<String, dynamic>?;
      if (captions == null) {
        developer.log('No captions object found in player response', name: _tag);
        // 打印所有顶级键以了解响应结构
        final keys = jsonObject.keys.toList();
        developer.log('Available top-level keys: ${keys.join(", ")}', name: _tag);
        return null;
      }

      developer.log('Found captions object', name: _tag);

      final playerCaptionsRenderer = captions['playerCaptionsTracklistRenderer'] as Map<String, dynamic>?;
      if (playerCaptionsRenderer == null) {
        developer.log('No playerCaptionsTracklistRenderer found', name: _tag);
        // 打印captions对象的所有键
        final captionKeys = captions.keys.toList();
        developer.log('Available caption keys: ${captionKeys.join(", ")}', name: _tag);
        return null;
      }

      final captionTracks = playerCaptionsRenderer['captionTracks'] as List<dynamic>?;
      if (captionTracks == null) {
        developer.log('No captionTracks found', name: _tag);
        return null;
      }

      developer.log('Found ${captionTracks.length} caption tracks', name: _tag);

      // 查找英文字幕轨道
      for (int i = 0; i < captionTracks.length; i++) {
        final track = captionTracks[i] as Map<String, dynamic>;
        final languageCode = track['languageCode'] as String? ?? '';
        final baseUrl = track['baseUrl'] as String? ?? '';

        developer.log('Caption track $i: language=$languageCode, hasUrl=${baseUrl.isNotEmpty}', name: _tag);

        if (languageCode.startsWith('en') && baseUrl.isNotEmpty) {
          developer.log('Found English caption track, fetching transcript from: $baseUrl', name: _tag);
          return await _fetchAndParseTranscriptXml(baseUrl, videoId);
        }
      }

      developer.log('No English caption tracks found', name: _tag);
      return null;

    } catch (e) {
      developer.log('Error parsing player API response: $e', name: _tag, error: e);
      return null;
    }
  }

  static Future<Transcript?> _fetchAndParseTranscriptXml(String url, String videoId) async {
    try {
      developer.log('Fetching transcript XML from: $url', name: _tag);

      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36',
        },
      ).timeout(_receiveTimeout);

      if (response.statusCode != 200) {
        developer.log('Failed to fetch transcript XML: ${response.statusCode}', name: _tag);
        return null;
      }

      final xml = response.body;
      developer.log('Downloaded transcript XML, length: ${xml.length}', name: _tag);

      return _parseTranscriptXml(xml, videoId);

    } catch (e) {
      developer.log('Error fetching transcript XML: $e', name: _tag, error: e);
      return null;
    }
  }

  static Transcript? _parseTranscriptXml(String xml, String videoId) {
    try {
      final segments = <TranscriptSegment>[];

      developer.log('Parsing XML format, length: ${xml.length}', name: _tag);

      // 解析srv3格式的XML字幕 - 使用<p>标签
      final paragraphPattern = RegExp(
        r'<p t="([^"]+)" d="([^"]+)"[^>]*>(.*?)</p>',
        caseSensitive: false,
        dotAll: true,
      );

      final matches = paragraphPattern.allMatches(xml);

      for (final match in matches) {
        try {
          final startTimeMs = int.tryParse(match.group(1) ?? '');
          final durationMs = int.tryParse(match.group(2) ?? '');
          final content = match.group(3) ?? '';

          if (startTimeMs == null || durationMs == null) continue;

          // 转换毫秒到秒
          final startTime = startTimeMs / 1000.0;
          final duration = durationMs / 1000.0;

          // 检测XML格式类型并相应解析
          final text = content.contains('<s') 
              ? _parseWithSTags(content)
              : _parseDirectText(content);

          if (text.isNotEmpty) {
            segments.add(TranscriptSegment(
              text: text,
              startTime: startTime,
              endTime: startTime + duration,
            ));
            // developer.log('Parsed segment: ${startTime.toStringAsFixed(2)}s - \'$text\'', name: _tag);
          }

        } catch (e) {
          developer.log('Error parsing paragraph: $e', name: _tag);
          continue;
        }
      }

      if (segments.isNotEmpty) {
        developer.log('Successfully parsed ${segments.length} transcript segments from srv3 XML', name: _tag);
        segments.sort((a, b) => a.startTime.compareTo(b.startTime));
        return Transcript(
          segments: segments,
          videoId: videoId,
          title: 'English Transcript',
          language: 'en',
        );
      } else {
        developer.log('No transcript segments found in srv3 XML', name: _tag);
        return null;
      }

    } catch (e) {
      developer.log('Error parsing transcript XML: $e', name: _tag, error: e);
      return null;
    }
  }

  static String _parseWithSTags(String content) {
    // 格式1: 提取<s>标签中的文本
    final textBuffer = StringBuffer();
    final sPattern = RegExp(r'<s[^>]*>([^<]*)</s>', caseSensitive: false);
    final matches = sPattern.allMatches(content);

    for (final match in matches) {
      final sText = match.group(1) ?? '';
      textBuffer.write(sText);
    }

    return _cleanText(textBuffer.toString());
  }

  static String _parseDirectText(String content) {
    // 格式2: 直接解析文本内容，移除任何HTML标签
    final textWithoutTags = content
        .replaceAll(RegExp(r'<[^>]*>'), '') // 移除任何HTML标签
        .replaceAll(RegExp(r'\s+'), ' '); // 规范化空格

    return _cleanText(textWithoutTags);
  }

  static String _cleanText(String text) {
    // 统一的文本清理函数
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // 为了兼容性保留的静态方法
  static Future<void> addRecentVideo(String videoId) async {
    // 实现添加最近视频的逻辑
  }

  static Future<void> incrementSegmentClicks() async {
    // 实现增加片段点击次数的逻辑
  }
}