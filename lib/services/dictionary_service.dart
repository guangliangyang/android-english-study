import 'dart:convert';
import 'package:http/http.dart' as http;

class DictionaryService {
  static const String _baseUrl = 'https://api.dictionaryapi.dev/api/v2/entries/en/';
  
  static Future<DictionaryEntry?> getDefinition(String word) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl${word.toLowerCase()}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          return DictionaryEntry.fromJson(data[0]);
        }
      }
      
      return null;
    } catch (e) {
      print('Error fetching definition: $e');
      return null;
    }
  }
}

class DictionaryEntry {
  final String word;
  final List<Phonetic> phonetics;
  final List<Meaning> meanings;

  DictionaryEntry({
    required this.word,
    required this.phonetics,
    required this.meanings,
  });

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    return DictionaryEntry(
      word: json['word'] ?? '',
      phonetics: (json['phonetics'] as List<dynamic>?)
          ?.map((p) => Phonetic.fromJson(p))
          .toList() ?? [],
      meanings: (json['meanings'] as List<dynamic>?)
          ?.map((m) => Meaning.fromJson(m))
          .toList() ?? [],
    );
  }
}

class Phonetic {
  final String text;
  final String? audio;

  Phonetic({
    required this.text,
    this.audio,
  });

  factory Phonetic.fromJson(Map<String, dynamic> json) {
    return Phonetic(
      text: json['text'] ?? '',
      audio: json['audio'],
    );
  }
}

class Meaning {
  final String partOfSpeech;
  final List<Definition> definitions;

  Meaning({
    required this.partOfSpeech,
    required this.definitions,
  });

  factory Meaning.fromJson(Map<String, dynamic> json) {
    return Meaning(
      partOfSpeech: json['partOfSpeech'] ?? '',
      definitions: (json['definitions'] as List<dynamic>?)
          ?.map((d) => Definition.fromJson(d))
          .toList() ?? [],
    );
  }
}

class Definition {
  final String definition;
  final String? example;

  Definition({
    required this.definition,
    this.example,
  });

  factory Definition.fromJson(Map<String, dynamic> json) {
    return Definition(
      definition: json['definition'] ?? '',
      example: json['example'],
    );
  }
}