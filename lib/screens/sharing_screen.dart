import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/playlist.dart';
import '../services/sharing_service.dart';
import '../services/auth_service.dart';

class SharingScreen extends StatefulWidget {
  const SharingScreen({Key? key}) : super(key: key);

  @override
  State<SharingScreen> createState() => _SharingScreenState();
}

class _SharingScreenState extends State<SharingScreen> {
  late Playlist _playlist;
  String? _selectedCategory;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  void _loadPlaylist() {
    setState(() {
      _playlist = AuthService.playlist;
    });
  }

  List<PlaylistItem> _getVideosByCategory(String category) {
    if (category == '全部') {
      return _playlist.items;
    }
    return _playlist.getVideosByCategory(category);
  }

  Future<void> _generateAndShare() async {
    if (_selectedCategory == null) return;
    
    setState(() {
      _isGenerating = true;
    });
    
    try {
      final videos = _getVideosByCategory(_selectedCategory!);
      final shareText = SharingService.generateShareText(_selectedCategory!, videos);
      
      // 复制到剪贴板
      await SharingService.shareToSystem(shareText);
      
      if (mounted) {
        // 显示预览对话框
        _showSharePreview(shareText);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('分享内容生成失败'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _showSharePreview(String shareText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.share, color: Colors.blue, size: 24),
            SizedBox(width: 8),
            Text(
              '分享预览',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '分享内容已复制到剪贴板，可直接粘贴到任何应用中分享：',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800]?.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[600]!),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      shareText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '关闭',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              // 再次复制到剪贴板
              await Clipboard.setData(ClipboardData(text: shareText));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('已复制到剪贴板！可在任何应用中分享'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('复制'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['全部', ..._playlist.categories.where((cat) => cat != '全部')];
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('分享学习资源'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _playlist.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '播放列表为空',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '请先添加一些视频再分享',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 说明文字
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '学习资源分享',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '选择要分享的分类，系统将生成包含视频列表的文本，可通过任何社交应用分享给朋友。',
                          style: TextStyle(color: Colors.blue, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 分类选择
                  const Text(
                    '选择要分享的分类：',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final videos = _getVideosByCategory(category);
                        final isSelected = _selectedCategory == category;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey[900],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Radio<String>(
                              value: category,
                              groupValue: _selectedCategory,
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                              },
                              activeColor: Colors.blue,
                            ),
                            title: Text(
                              category,
                              style: TextStyle(
                                color: isSelected ? Colors.blue : Colors.white,
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              '${videos.length} 个视频',
                              style: TextStyle(
                                color: isSelected ? Colors.blue.withOpacity(0.8) : Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            trailing: Icon(
                              Icons.video_library,
                              color: isSelected ? Colors.blue : Colors.grey,
                            ),
                            onTap: () {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 分享按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _selectedCategory == null || _isGenerating
                          ? null
                          : _generateAndShare,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.share),
                      label: Text(_isGenerating ? '生成中...' : '生成分享内容'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}