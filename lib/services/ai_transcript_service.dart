import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import '../models/transcript.dart';
import 'transcript_service.dart';

class AITranscriptService {
  static const String _tag = 'AITranscriptService';

  // Environment variable accessors
  static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static String get _apiUrl => dotenv.env['OPENAI_API_URL'] ?? 'https://api.openai.com/v1/chat/completions';
  static String get _model => dotenv.env['OPENAI_MODEL'] ?? 'gpt-3.5-turbo';
  static int get _timeout => int.tryParse(dotenv.env['AI_TRANSCRIPT_TIMEOUT'] ?? '30000') ?? 30000;
  static double get _temperature => double.tryParse(dotenv.env['AI_TRANSCRIPT_TEMPERATURE'] ?? '0.1') ?? 0.1;
  
  // Configuration validation
  static bool get _isConfigured => _apiKey.isNotEmpty && _apiKey.startsWith('sk-');
  
  static final http.Client _client = http.Client();

  /// Generate AI transcript from original transcript with progress callback
  static Future<EnhancedTranscript?> generateFromOriginal(
    String videoId, {
    Function(int currentBatch, int totalBatches, int processedSegments, int totalSegments)? onProgress,
  }) async {
    try {
      if (!_isConfigured) {
        throw Exception('OpenAI API key not configured. Please check your .env file.');
      }

      developer.log('Generating AI transcript for video: $videoId', name: _tag);
      
      // Load original transcript
      final originalTranscript = await TranscriptService.loadOriginalTranscript(videoId);
      if (originalTranscript == null) {
        throw Exception('No original transcript found for video: $videoId');
      }

      developer.log('Processing ${originalTranscript.segments.length} total segments in batches of 20', name: _tag);

      // Process all segments in batches of 20
      final allSentences = <Sentence>[];
      final totalSegments = originalTranscript.segments.length;
      final totalBatches = (totalSegments / 20).ceil();
      
      for (int i = 0; i < totalSegments; i += 20) {
        final endIndex = (i + 20).clamp(0, totalSegments);
        final batchSegments = originalTranscript.segments.sublist(i, endIndex);
        final currentBatch = (i ~/ 20) + 1;
        
        developer.log('Processing batch $currentBatch/$totalBatches: segments ${i + 1}-$endIndex', name: _tag);
        
        // Call progress callback before processing batch
        onProgress?.call(currentBatch, totalBatches, i, totalSegments);
        
        // Create temporary transcript for this batch
        final batchTranscript = Transcript(
          segments: batchSegments,
          videoId: videoId,
          title: originalTranscript.title,
          language: originalTranscript.language,
        );
        
        // Build prompt with batch transcript data
        final transcriptData = _buildTranscriptData(batchTranscript);
        final aiResponse = await _callOpenAI(transcriptData);
        
        // Parse AI response for this batch
        final batchEnhancedTranscript = _parseAIResponse(aiResponse, videoId);
        
        if (batchEnhancedTranscript != null) {
          allSentences.addAll(batchEnhancedTranscript.sentences);
          developer.log('Successfully processed batch $currentBatch, total sentences so far: ${allSentences.length}', name: _tag);
        } else {
          developer.log('Failed to process batch $currentBatch', name: _tag);
        }
        
        // Call progress callback after processing batch
        onProgress?.call(currentBatch, totalBatches, endIndex, totalSegments);
        
        // Add a small delay between batches to avoid rate limiting
        if (i + 20 < totalSegments) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      if (allSentences.isNotEmpty) {
        final enhancedTranscript = EnhancedTranscript(
          videoId: videoId,
          title: originalTranscript.title,
          language: originalTranscript.language,
          sentences: allSentences,
          isAIGenerated: true,
          aiGeneratedAt: DateTime.now(),
        );
        
        // Save to local storage
        await saveAITranscript(videoId, enhancedTranscript);
        
        developer.log('Successfully generated AI transcript with ${allSentences.length} sentences', name: _tag);
        return enhancedTranscript;
      }
      
      return null;
      
    } catch (e) {
      developer.log('Error generating AI transcript: $e', name: _tag, error: e);
      return null;
    }
  }

  /// Load AI transcript from local storage
  static Future<EnhancedTranscript?> loadAITranscript(String videoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('ai_transcript_$videoId');
      
      if (jsonString != null) {
        final jsonData = json.decode(jsonString);
        return EnhancedTranscript.fromJson(jsonData);
      }
      
      return null;
    } catch (e) {
      developer.log('Error loading AI transcript: $e', name: _tag, error: e);
      return null;
    }
  }

  /// Save AI transcript to local storage
  static Future<void> saveAITranscript(String videoId, EnhancedTranscript transcript) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(transcript.toJson());
      await prefs.setString('ai_transcript_$videoId', jsonString);
      
      // Update cache list
      final cacheList = prefs.getStringList('ai_transcript_cache_list') ?? [];
      if (!cacheList.contains(videoId)) {
        cacheList.add(videoId);
        await prefs.setStringList('ai_transcript_cache_list', cacheList);
      }
      
      developer.log('AI transcript saved for video: $videoId', name: _tag);
    } catch (e) {
      developer.log('Error saving AI transcript: $e', name: _tag, error: e);
    }
  }

  /// Check if AI transcript exists for video
  static Future<bool> hasAITranscript(String videoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('ai_transcript_$videoId');
    } catch (e) {
      return false;
    }
  }

  /// Delete AI transcript
  static Future<void> deleteAITranscript(String videoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('ai_transcript_$videoId');
      
      // Update cache list
      final cacheList = prefs.getStringList('ai_transcript_cache_list') ?? [];
      cacheList.remove(videoId);
      await prefs.setStringList('ai_transcript_cache_list', cacheList);
      
      developer.log('AI transcript deleted for video: $videoId', name: _tag);
    } catch (e) {
      developer.log('Error deleting AI transcript: $e', name: _tag, error: e);
    }
  }

  /// Get best available transcript (AI preferred, original fallback)
  static Future<Transcript?> getBestTranscript(String videoId) async {
    // Try AI transcript first
    final aiTranscript = await loadAITranscript(videoId);
    if (aiTranscript != null) {
      return aiTranscript.toTranscript();
    }
    
    // Fallback to original transcript
    return await TranscriptService.getTranscript(videoId);
  }

  /// Build transcript data for OpenAI prompt (processes all segments in the provided transcript)
  static String _buildTranscriptData(Transcript transcript) {
    final buffer = StringBuffer();
    
    for (final segment in transcript.segments) {
      final timeFormatted = _formatTime(segment.startTime);
      buffer.writeln('$timeFormatted\n${segment.text}\n');
    }
    
    return buffer.toString().trim();
  }

  /// Format time for display
  static String _formatTime(double seconds) {
    final totalSeconds = seconds.toInt();
    final minutes = totalSeconds ~/ 60;
    final remainingSeconds = totalSeconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Call OpenAI API (no retry, fail fast)
  static Future<String> _callOpenAI(String transcriptData) async {
    final prompt = '''你是一个专业的英语学习材料制作助手。请将下面YouTube的碎片化字幕转换为以单个句子为单位的结构化字幕。

**重要要求：**
1. **每个<sentence>标签只包含一个完整的句子**，不要包含多个句子
2. 将原始的碎片化字幕重新组织，但要确保每个句子独立成段
3. **保持时间戳的连续性**，尽量让相邻句子的时间戳接近连续，避免大的时间间隙
4. 为每个单句提供准确的时间戳和中文翻译
5. 提取关键词汇，帮助中文用户学习

**输出要求：**
- 每个句子必须语法完整且有意义
- 句子长度适中，便于学习理解
- 过长的句子要拆分成多个独立的句子

**输出格式（严格按照以下XML格式）：**
```xml
<sentence start_time="0:05" end_time="0:08">
    <original>Hello there and welcome to this system design mock interview.</original>
    <translation>大家好，欢迎来到这个系统设计模拟面试。</translation>
    <pronunciation></pronunciation>
    <explanation></explanation>
    <keywords>
        <keyword>
            <phrase>system design</phrase>
            <meaning>系统设计</meaning>
            <type>专业术语</type>
        </keyword>
        <keyword>
            <phrase>mock interview</phrase>
            <meaning>模拟面试</meaning>
            <type>短语搭配</type>
        </keyword>
    </keywords>
</sentence>

<sentence start_time="0:08" end_time="0:12">
    <original>Today we want to show you a really high quality answer.</original>
    <translation>今天我们想向你展示一个高质量的答案。</translation>
    <pronunciation></pronunciation>
    <explanation></explanation>
    <keywords>
        <keyword>
            <phrase>high quality</phrase>
            <meaning>高质量的</meaning>
            <type>形容词短语</type>
        </keyword>
    </keywords>
</sentence>
```

**注意：**
- 即使某些字段为空，也必须包含空标签
- 确保每个句子都是独立完整的
- 不要将多个句子合并在一个<sentence>标签中

**原始字幕数据：**
$transcriptData''';

    final requestBody = {
      'model': _model,
      'messages': [
        {
          'role': 'user',
          'content': prompt,
        }
      ],
      'temperature': _temperature,
      'max_tokens': 4000,
    };

    try {
      developer.log('Calling OpenAI API (single attempt, no retry)', name: _tag);
      developer.log('Sending transcript data preview: ${transcriptData.substring(0, transcriptData.length > 200 ? 200 : transcriptData.length)}...', name: _tag);
      
      final response = await _client.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(Duration(milliseconds: _timeout));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'];
        developer.log('OpenAI API call successful', name: _tag);
        
        // 打印OpenAI返回的完整内容用于调试
        developer.log('=== OpenAI Response Start ===', name: _tag);
        developer.log(content, name: _tag);
        developer.log('=== OpenAI Response End ===', name: _tag);
        
        return content;
      } else {
        final error = 'OpenAI API error: ${response.statusCode} - ${response.body}';
        developer.log(error, name: _tag);
        throw Exception(error);
      }
    } catch (e) {
      developer.log('OpenAI API call failed: $e', name: _tag);
      throw Exception('OpenAI API调用失败: $e');
    }
  }

  /// Parse AI response XML
  static EnhancedTranscript? _parseAIResponse(String xmlResponse, String videoId) {
    try {
      developer.log('Starting XML parsing for video: $videoId', name: _tag);
      final sentences = <Sentence>[];
      
      // Try complete format first (with all fields)
      var sentencePattern = RegExp(
        r'<sentence start_time="([^"]+)" end_time="([^"]+)">\s*<original>(.*?)</original>\s*<translation>(.*?)</translation>\s*<pronunciation>(.*?)</pronunciation>\s*<explanation>(.*?)</explanation>\s*<keywords>(.*?)</keywords>\s*</sentence>',
        dotAll: true,
      );
      
      var matches = sentencePattern.allMatches(xmlResponse);
      developer.log('Found ${matches.length} matches with complete format', name: _tag);
      
      // If no matches, try simplified format (only original and keywords)
      if (matches.isEmpty) {
        developer.log('Trying simplified format...', name: _tag);
        sentencePattern = RegExp(
          r'<sentence start_time="([^"]+)" end_time="([^"]+)">\s*<original>(.*?)</original>\s*<keywords>(.*?)</keywords>\s*</sentence>',
          dotAll: true,
        );
        matches = sentencePattern.allMatches(xmlResponse);
        developer.log('Found ${matches.length} matches with simplified format', name: _tag);
      }
      
      for (final match in matches) {
        try {
          final startTimeStr = match.group(1) ?? '';
          final endTimeStr = match.group(2) ?? '';
          final text = match.group(3) ?? '';
          
          // Determine format based on group count
          String translation = '';
          String pronunciation = '';
          String explanation = '';
          String keywordsXml = '';
          
          if (match.groupCount >= 7) {
            // Complete format
            translation = match.group(4) ?? '';
            pronunciation = match.group(5) ?? '';
            explanation = match.group(6) ?? '';
            keywordsXml = match.group(7) ?? '';
            developer.log('Using complete format', name: _tag);
          } else if (match.groupCount >= 4) {
            // Simplified format  
            keywordsXml = match.group(4) ?? '';
            developer.log('Using simplified format', name: _tag);
          }
          
          final startTime = _parseTime(startTimeStr);
          final endTime = _parseTime(endTimeStr);
          final keywords = _parseKeywords(keywordsXml);
          
          developer.log('Parsing sentence: "${text.substring(0, text.length > 50 ? 50 : text.length)}..."', name: _tag);
          developer.log('Translation: "${translation}"', name: _tag);
          developer.log('Keywords count: ${keywords.length}', name: _tag);
          
          // 智能计算endTime，避免间隙
          double calculatedEndTime = endTime;
          if (endTime <= startTime) {
            // 根据文本长度估算duration（每个字符约0.1秒，最少2秒，最多8秒）
            final textLength = text.trim().length;
            final estimatedDuration = (textLength * 0.1).clamp(2.0, 8.0);
            calculatedEndTime = startTime + estimatedDuration;
          }
          
          sentences.add(Sentence(
            text: text.trim(),
            startTime: startTime,
            endTime: calculatedEndTime,
            chineseTranslation: translation.trim(),
            pronunciation: pronunciation.trim(),
            explanation: explanation.trim(),
            keywords: keywords,
          ));
        } catch (e) {
          developer.log('Error parsing sentence: $e', name: _tag);
          continue;
        }
      }
      
      if (sentences.isNotEmpty) {
        developer.log('Successfully parsed ${sentences.length} sentences', name: _tag);
        return EnhancedTranscript(
          videoId: videoId,
          title: 'AI Enhanced Transcript',
          language: 'en',
          sentences: sentences,
          isAIGenerated: true,
          aiGeneratedAt: DateTime.now(),
        );
      }
      
      developer.log('No sentences found in XML response', name: _tag);
      return null;
    } catch (e) {
      developer.log('Error parsing AI response: $e', name: _tag, error: e);
      return null;
    }
  }

  /// Parse time string like "1:05" to seconds
  static double _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        final minutes = int.parse(parts[0]);
        final seconds = int.parse(parts[1]);
        return (minutes * 60 + seconds).toDouble();
      }
    } catch (e) {
      // Ignore parse errors
    }
    return 0.0;
  }

  /// Parse keywords XML
  static List<Keyword> _parseKeywords(String keywordsXml) {
    final keywords = <Keyword>[];
    
    final keywordPattern = RegExp(
      r'<keyword>\s*<phrase>(.*?)</phrase>\s*<meaning>(.*?)</meaning>\s*<type>(.*?)</type>\s*</keyword>',
      dotAll: true,
    );
    
    final matches = keywordPattern.allMatches(keywordsXml);
    
    for (final match in matches) {
      try {
        final phrase = match.group(1)?.trim() ?? '';
        final meaning = match.group(2)?.trim() ?? '';
        final type = match.group(3)?.trim() ?? '';
        
        if (phrase.isNotEmpty && meaning.isNotEmpty) {
          keywords.add(Keyword(
            english: phrase,
            chinese: meaning,
            type: type,
          ));
        }
      } catch (e) {
        // Ignore parse errors for individual keywords
      }
    }
    
    return keywords;
  }

  /// Get configuration summary for debugging
  static Map<String, String> getConfigSummary() {
    return {
      'OpenAI Model': _model,
      'API Configured': _isConfigured ? 'Yes' : 'No',
      'Timeout': '${_timeout}ms',
      'Temperature': '$_temperature',
      'Retry Policy': 'Disabled (fail fast)',
    };
  }
}

/// Enhanced transcript with AI-generated keywords and sentences
class EnhancedTranscript {
  final String videoId;
  final String title;
  final String language;
  final List<Sentence> sentences;
  final bool isAIGenerated;
  final DateTime aiGeneratedAt;

  EnhancedTranscript({
    required this.videoId,
    required this.title,
    required this.sentences,
    this.language = 'en',
    this.isAIGenerated = true,
    DateTime? aiGeneratedAt,
  }) : aiGeneratedAt = aiGeneratedAt ?? DateTime.now();

  /// Convert to regular transcript for compatibility
  Transcript toTranscript() {
    final segments = <TranscriptSegment>[];
    
    for (final sentence in sentences) {
      segments.add(TranscriptSegment(
        text: sentence.text,
        startTime: sentence.startTime,
        endTime: sentence.endTime,
        chineseTranslation: sentence.chineseTranslation.isNotEmpty ? sentence.chineseTranslation : null,
        keywords: sentence.keywords.map((k) => k.english).toList(),
        pronunciation: sentence.pronunciation.isNotEmpty ? sentence.pronunciation : null,
        explanation: sentence.explanation.isNotEmpty ? sentence.explanation : null,
      ));
    }
    
    return Transcript(
      segments: segments,
      videoId: videoId,
      title: title,
      language: language,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'title': title,
      'language': language,
      'sentences': sentences.map((s) => s.toJson()).toList(),
      'isAIGenerated': isAIGenerated,
      'aiGeneratedAt': aiGeneratedAt.toIso8601String(),
    };
  }

  factory EnhancedTranscript.fromJson(Map<String, dynamic> json) {
    return EnhancedTranscript(
      videoId: json['videoId'] ?? '',
      title: json['title'] ?? '',
      language: json['language'] ?? 'en',
      sentences: (json['sentences'] as List<dynamic>? ?? [])
          .map((s) => Sentence.fromJson(s))
          .toList(),
      isAIGenerated: json['isAIGenerated'] ?? true,
      aiGeneratedAt: DateTime.tryParse(json['aiGeneratedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

/// AI-enhanced sentence with keywords and translations
class Sentence {
  final String text;
  final double startTime;
  final double endTime;
  final String chineseTranslation;
  final List<Keyword> keywords;
  final String pronunciation;
  final String explanation;

  Sentence({
    required this.text,
    required this.startTime,
    required this.endTime,
    this.chineseTranslation = '',
    this.keywords = const [],
    this.pronunciation = '',
    this.explanation = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'startTime': startTime,
      'endTime': endTime,
      'chineseTranslation': chineseTranslation,
      'keywords': keywords.map((k) => k.toJson()).toList(),
      'pronunciation': pronunciation,
      'explanation': explanation,
    };
  }

  factory Sentence.fromJson(Map<String, dynamic> json) {
    return Sentence(
      text: json['text'] ?? '',
      startTime: (json['startTime'] ?? 0.0).toDouble(),
      endTime: (json['endTime'] ?? 0.0).toDouble(),
      chineseTranslation: json['chineseTranslation'] ?? '',
      keywords: (json['keywords'] as List<dynamic>? ?? [])
          .map((k) => Keyword.fromJson(k))
          .toList(),
      pronunciation: json['pronunciation'] ?? '',
      explanation: json['explanation'] ?? '',
    );
  }
}


/// Keyword model
class Keyword {
  final String english;
  final String chinese;
  final String type;

  Keyword({
    required this.english,
    required this.chinese,
    required this.type,
  });

  // Legacy support
  String get phrase => english;
  String get meaning => chinese;

  Map<String, dynamic> toJson() {
    return {
      'english': english,
      'chinese': chinese,
      'type': type,
      // Legacy support
      'phrase': english,
      'meaning': chinese,
    };
  }

  factory Keyword.fromJson(Map<String, dynamic> json) {
    return Keyword(
      english: json['english'] ?? json['phrase'] ?? '',
      chinese: json['chinese'] ?? json['meaning'] ?? '',
      type: json['type'] ?? '',
    );
  }
}