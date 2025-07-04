class TranscriptSegment {
  final String text;
  final double startTime;
  final double endTime;
  final String? chineseTranslation;
  final String? pronunciation;
  final List<String> keywords;
  final String? explanation;

  TranscriptSegment({
    required this.text,
    required this.startTime,
    required this.endTime,
    this.chineseTranslation,
    this.pronunciation,
    this.keywords = const [],
    this.explanation,
  });

  factory TranscriptSegment.fromXml(dynamic xmlElement) {
    final text = xmlElement.attributes['text'] ?? '';
    final start = double.tryParse(xmlElement.attributes['start'] ?? '0') ?? 0.0;
    final duration = double.tryParse(xmlElement.attributes['dur'] ?? '0') ?? 0.0;
    
    return TranscriptSegment(
      text: text,
      startTime: start,
      endTime: start + duration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'startTime': startTime,
      'endTime': endTime,
      'chineseTranslation': chineseTranslation,
      'pronunciation': pronunciation,
      'keywords': keywords,
      'explanation': explanation,
    };
  }

  factory TranscriptSegment.fromJson(Map<String, dynamic> json) {
    return TranscriptSegment(
      text: json['text'] ?? '',
      startTime: (json['startTime'] ?? 0.0).toDouble(),
      endTime: (json['endTime'] ?? 0.0).toDouble(),
      chineseTranslation: json['chineseTranslation'],
      pronunciation: json['pronunciation'],
      keywords: List<String>.from(json['keywords'] ?? []),
      explanation: json['explanation'],
    );
  }

  TranscriptSegment copyWith({
    String? text,
    double? startTime,
    double? endTime,
    String? chineseTranslation,
    String? pronunciation,
    List<String>? keywords,
    String? explanation,
  }) {
    return TranscriptSegment(
      text: text ?? this.text,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      chineseTranslation: chineseTranslation ?? this.chineseTranslation,
      pronunciation: pronunciation ?? this.pronunciation,
      keywords: keywords ?? this.keywords,
      explanation: explanation ?? this.explanation,
    );
  }

  @override
  String toString() {
    return 'TranscriptSegment(text: $text, startTime: $startTime, endTime: $endTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TranscriptSegment &&
        other.text == text &&
        other.startTime == startTime &&
        other.endTime == endTime;
  }

  @override
  int get hashCode => text.hashCode ^ startTime.hashCode ^ endTime.hashCode;
}

class Transcript {
  final List<TranscriptSegment> segments;
  final String videoId;
  final String title;
  final String language;
  final DateTime createdAt;

  Transcript({
    required this.segments,
    required this.videoId,
    required this.title,
    this.language = 'en',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Transcript.fromXmlString(String xmlString, String videoId, String title) {
    // This would parse the XML transcript from YouTube
    // For now, return empty transcript
    return Transcript(
      segments: [],
      videoId: videoId,
      title: title,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'segments': segments.map((s) => s.toJson()).toList(),
      'videoId': videoId,
      'title': title,
      'language': language,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Transcript.fromJson(Map<String, dynamic> json) {
    return Transcript(
      segments: (json['segments'] as List<dynamic>? ?? [])
          .map((s) => TranscriptSegment.fromJson(s))
          .toList(),
      videoId: json['videoId'] ?? '',
      title: json['title'] ?? '',
      language: json['language'] ?? 'en',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  TranscriptSegment? getSegmentAtTime(double time) {
    for (final segment in segments) {
      if (time >= segment.startTime && time <= segment.endTime) {
        return segment;
      }
    }
    return null;
  }

  int getSegmentIndexAtTime(double time) {
    for (int i = 0; i < segments.length; i++) {
      if (time >= segments[i].startTime && time <= segments[i].endTime) {
        return i;
      }
    }
    return -1;
  }

  List<TranscriptSegment> searchSegments(String query) {
    final lowerQuery = query.toLowerCase();
    return segments.where((segment) {
      return segment.text.toLowerCase().contains(lowerQuery) ||
          (segment.chineseTranslation?.toLowerCase().contains(lowerQuery) ?? false) ||
          segment.keywords.any((keyword) => keyword.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  double get duration {
    if (segments.isEmpty) return 0.0;
    return segments.last.endTime;
  }

  @override
  String toString() {
    return 'Transcript(videoId: $videoId, title: $title, segments: ${segments.length})';
  }
}