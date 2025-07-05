import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/vocabulary_service.dart';
import '../widgets/word_definition_dialog.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({Key? key}) : super(key: key);

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  List<VocabularyItem> _bookmarks = [];
  bool _isLoading = true;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    setState(() {
      _isLoading = true;
    });
    
    final bookmarks = await VocabularyService.getBookmarks();
    
    setState(() {
      _bookmarks = bookmarks;
      _isLoading = false;
    });
  }

  Future<void> _removeBookmark(String word) async {
    final success = await VocabularyService.removeBookmark(word);
    if (success) {
      await _loadBookmarks();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已从生词本移除'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _playAudio(String? audioUrl) async {
    if (audioUrl == null || audioUrl.isEmpty) return;
    
    try {
      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  void _showWordDetails(VocabularyItem item) {
    showDialog(
      context: context,
      builder: (context) => WordDefinitionDialog(word: item.word),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        title: const Text('生词本'),
        actions: [
          IconButton(
            onPressed: _loadBookmarks,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
          if (_bookmarks.isNotEmpty)
            IconButton(
              onPressed: _showClearAllDialog,
              icon: const Icon(Icons.clear_all),
              tooltip: '清空生词本',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookmarks.isEmpty
              ? _buildEmptyState()
              : _buildBookmarksList(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            '生词本为空',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '在播放页面选择生词即可添加到生词本',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bookmarks.length,
      itemBuilder: (context, index) {
        final item = _bookmarks[index];
        return _buildBookmarkCard(item);
      },
    );
  }

  Widget _buildBookmarkCard(VocabularyItem item) {
    final firstPhonetic = item.phonetics.isNotEmpty ? item.phonetics.first : null;
    final firstMeaning = item.meanings.isNotEmpty ? item.meanings.first : null;
    final firstDefinition = firstMeaning?.definitions.isNotEmpty == true 
        ? firstMeaning!.definitions.first 
        : null;

    return Card(
      color: Colors.grey[800],
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showWordDetails(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Word and actions
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.word.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (firstPhonetic?.audio != null && firstPhonetic!.audio!.isNotEmpty)
                    IconButton(
                      onPressed: () => _playAudio(firstPhonetic.audio),
                      icon: const Icon(Icons.volume_up, color: Colors.blue),
                      tooltip: '播放发音',
                    ),
                  IconButton(
                    onPressed: () => _removeBookmark(item.word),
                    icon: const Icon(Icons.bookmark_remove, color: Colors.red),
                    tooltip: '移除',
                  ),
                ],
              ),
              
              // Phonetic
              if (firstPhonetic != null && firstPhonetic.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    firstPhonetic.text,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              
              // Part of speech and first definition
              if (firstMeaning != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[700],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        firstMeaning.partOfSpeech,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (firstDefinition != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    firstDefinition.definition,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
              
              // Bookmark date
              const SizedBox(height: 8),
              Text(
                '收藏于 ${_formatDate(item.bookmarkedAt)}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: const Text(
          '清空生词本',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '确定要清空所有生词吗？此操作不可恢复。',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await VocabularyService.clearAllBookmarks();
              if (success) {
                await _loadBookmarks();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('生词本已清空'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}