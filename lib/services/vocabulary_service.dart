import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dictionary_service.dart';

class VocabularyService {
  static const String _bookmarksKey = 'vocabulary_bookmarks';
  
  static Future<List<VocabularyItem>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = prefs.getStringList(_bookmarksKey) ?? [];
    
    return bookmarksJson
        .map((json) => VocabularyItem.fromJson(jsonDecode(json)))
        .toList()
        ..sort((a, b) => b.bookmarkedAt.compareTo(a.bookmarkedAt)); // 按收藏时间倒序
  }
  
  static Future<bool> addBookmark(DictionaryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getBookmarks();
    
    // 检查是否已存在
    if (bookmarks.any((item) => item.word.toLowerCase() == entry.word.toLowerCase())) {
      return false;
    }
    
    // 添加新项
    final newItem = VocabularyItem(
      word: entry.word,
      phonetics: entry.phonetics,
      meanings: entry.meanings,
      bookmarkedAt: DateTime.now(),
    );
    
    bookmarks.add(newItem);
    
    // 保存到本地存储
    final bookmarksJson = bookmarks
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    
    return await prefs.setStringList(_bookmarksKey, bookmarksJson);
  }
  
  static Future<bool> removeBookmark(String word) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getBookmarks();
    
    bookmarks.removeWhere((item) => item.word.toLowerCase() == word.toLowerCase());
    
    final bookmarksJson = bookmarks
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    
    return await prefs.setStringList(_bookmarksKey, bookmarksJson);
  }
  
  static Future<bool> isBookmarked(String word) async {
    final bookmarks = await getBookmarks();
    return bookmarks.any((item) => item.word.toLowerCase() == word.toLowerCase());
  }
  
  static Future<bool> clearAllBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(_bookmarksKey);
  }
}

class VocabularyItem {
  final String word;
  final List<Phonetic> phonetics;
  final List<Meaning> meanings;
  final DateTime bookmarkedAt;

  VocabularyItem({
    required this.word,
    required this.phonetics,
    required this.meanings,
    required this.bookmarkedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'phonetics': phonetics.map((p) => {
        'text': p.text,
        'audio': p.audio,
      }).toList(),
      'meanings': meanings.map((m) => {
        'partOfSpeech': m.partOfSpeech,
        'definitions': m.definitions.map((d) => {
          'definition': d.definition,
          'example': d.example,
        }).toList(),
      }).toList(),
      'bookmarkedAt': bookmarkedAt.toIso8601String(),
    };
  }

  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      word: json['word'] ?? '',
      phonetics: (json['phonetics'] as List<dynamic>?)
          ?.map((p) => Phonetic(
                text: p['text'] ?? '',
                audio: p['audio'],
              ))
          .toList() ?? [],
      meanings: (json['meanings'] as List<dynamic>?)
          ?.map((m) => Meaning(
                partOfSpeech: m['partOfSpeech'] ?? '',
                definitions: (m['definitions'] as List<dynamic>?)
                    ?.map((d) => Definition(
                          definition: d['definition'] ?? '',
                          example: d['example'],
                        ))
                    .toList() ?? [],
              ))
          .toList() ?? [],
      bookmarkedAt: DateTime.parse(json['bookmarkedAt']),
    );
  }
}