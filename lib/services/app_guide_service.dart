import 'package:shared_preferences/shared_preferences.dart';

class AppGuideService {
  static const String _vocabularyGuideKey = 'vocabulary_guide_shown';
  
  static Future<bool> hasShownVocabularyGuide() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vocabularyGuideKey) ?? false;
  }
  
  static Future<void> markVocabularyGuideShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vocabularyGuideKey, true);
  }
  
  static Future<void> resetAllGuides() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_vocabularyGuideKey);
  }
}