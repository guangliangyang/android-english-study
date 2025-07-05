import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/dictionary_service.dart';
import '../services/vocabulary_service.dart';

class WordDefinitionDialog extends StatefulWidget {
  final String word;

  const WordDefinitionDialog({Key? key, required this.word}) : super(key: key);

  @override
  State<WordDefinitionDialog> createState() => _WordDefinitionDialogState();
}

class _WordDefinitionDialogState extends State<WordDefinitionDialog> {
  DictionaryEntry? _entry;
  bool _isLoading = true;
  bool _isBookmarked = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadDefinition();
    _checkBookmarkStatus();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadDefinition() async {
    final entry = await DictionaryService.getDefinition(widget.word);
    setState(() {
      _entry = entry;
      _isLoading = false;
    });
  }

  Future<void> _checkBookmarkStatus() async {
    final bookmarked = await VocabularyService.isBookmarked(widget.word);
    setState(() {
      _isBookmarked = bookmarked;
    });
  }

  Future<void> _toggleBookmark() async {
    if (_entry == null) return;

    if (_isBookmarked) {
      await VocabularyService.removeBookmark(widget.word);
    } else {
      await VocabularyService.addBookmark(_entry!);
    }
    
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isBookmarked ? '已添加到生词本' : '已从生词本移除'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _playAudio(String? audioUrl) async {
    if (audioUrl == null || audioUrl.isEmpty) return;
    
    try {
      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[800],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.word.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleBookmark,
                    icon: Icon(
                      _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: _isBookmarked ? Colors.amber : Colors.white,
                    ),
                    tooltip: _isBookmarked ? '从生词本移除' : '添加到生词本',
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _entry == null
                      ? const Center(
                          child: Text(
                            '未找到该单词的定义',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : _buildDefinitionContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefinitionContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phonetics
          if (_entry!.phonetics.isNotEmpty) ...[
            const Text(
              '音标',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._entry!.phonetics.map((phonetic) => _buildPhoneticItem(phonetic)),
            const SizedBox(height: 16),
          ],
          
          // Meanings
          const Text(
            '释义',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._entry!.meanings.map((meaning) => _buildMeaningItem(meaning)),
        ],
      ),
    );
  }

  Widget _buildPhoneticItem(Phonetic phonetic) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              phonetic.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'monospace',
              ),
            ),
          ),
          if (phonetic.audio != null && phonetic.audio!.isNotEmpty)
            IconButton(
              onPressed: () => _playAudio(phonetic.audio),
              icon: const Icon(Icons.volume_up, color: Colors.blue),
              tooltip: '播放发音',
            ),
        ],
      ),
    );
  }

  Widget _buildMeaningItem(Meaning meaning) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Part of Speech
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[700],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              meaning.partOfSpeech,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Definitions
          ...meaning.definitions.asMap().entries.map((entry) {
            final index = entry.key;
            final definition = entry.value;
            return _buildDefinitionItem(index + 1, definition);
          }),
        ],
      ),
    );
  }

  Widget _buildDefinitionItem(int index, Definition definition) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$index. ',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              Expanded(
                child: Text(
                  definition.definition,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (definition.example != null && definition.example!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Text(
                '例句: ${definition.example}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}