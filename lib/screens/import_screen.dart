import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../services/sharing_service.dart';
import '../services/auth_service.dart';
import '../services/video_metadata_service.dart';
import '../models/playlist.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({Key? key}) : super(key: key);

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final TextEditingController _textController = TextEditingController();
  ShareParseResult? _parseResult;
  bool _isImporting = false;
  bool _isAnalyzing = false;
  List<String> _importedVideoIds = [];
  List<String> _skippedVideoIds = [];

  @override
  void initState() {
    super.initState();
    _checkClipboardOnStart();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _checkClipboardOnStart() async {
    try {
      final result = await SharingService.detectShareContent();
      if (result != null && mounted) {
        setState(() {
          _parseResult = result;
          _textController.text = SharingService.generateShareText(result.categoryName, []);
        });
      }
    } catch (e) {
      // 忽略剪贴板检测失败
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text ?? '';
      
      if (text.isNotEmpty) {
        setState(() {
          _textController.text = text;
        });
        _analyzeText();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('无法访问剪贴板'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _analyzeText() {
    if (_textController.text.trim().isEmpty) {
      setState(() {
        _parseResult = null;
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    // 模拟分析延迟
    Future.delayed(const Duration(milliseconds: 300), () {
      final result = SharingService.parseShareText(_textController.text);
      
      if (mounted) {
        setState(() {
          _parseResult = result;
          _isAnalyzing = false;
        });
      }
    });
  }

  Future<void> _importVideos() async {
    if (_parseResult == null) return;
    
    setState(() {
      _isImporting = true;
      _importedVideoIds.clear();
      _skippedVideoIds.clear();
    });

    try {
      for (final videoItem in _parseResult!.validVideos) {
        final videoId = videoItem.videoId!;
        
        // 检查是否已存在
        if (AuthService.isVideoInPlaylist(videoId)) {
          _skippedVideoIds.add(videoId);
          continue;
        }

        // 获取视频元数据
        final metadata = await VideoMetadataService.getVideoMetadataMap(videoId);
        
        // 添加到播放列表，使用视频自己的分类
        await AuthService.addToPlaylist(
          videoId,
          title: metadata['title'] ?? videoItem.title,
          thumbnail: metadata['thumbnail'],
          duration: metadata['duration'],
          channelName: metadata['channelName'],
          category: videoItem.category,
        );
        _importedVideoIds.add(videoId);
      }
      
      if (mounted) {
        _showImportResult();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  void _showImportResult() {
    final totalVideos = _parseResult!.validVideos.length;
    final imported = _importedVideoIds.length;
    final skipped = _skippedVideoIds.length;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Text(
              '导入完成',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '分类：${_parseResult!.categoryName}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              '总视频数：$totalVideos',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            Text(
              '成功导入：$imported',
              style: const TextStyle(color: Colors.green, fontSize: 14),
            ),
            if (skipped > 0)
              Text(
                '跳过重复：$skipped',
                style: const TextStyle(color: Colors.orange, fontSize: 14),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // 返回播放列表
            },
            child: const Text('查看播放列表'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('导入学习资源'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 说明文字
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.download, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '导入学习资源',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '粘贴朋友分享的学习资源文本，系统将自动识别并添加到你的播放列表中。',
                    style: TextStyle(color: Colors.green, fontSize: 14),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 输入框
            const Text(
              '分享内容：',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[600]!),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: '在此粘贴分享的文本内容...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    maxLines: 8,
                    minLines: 6,
                    onChanged: (value) {
                      // 实时分析
                      _analyzeText();
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '支持识别LearnMate App分享的内容',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        TextButton.icon(
                          onPressed: _pasteFromClipboard,
                          icon: const Icon(Icons.content_paste, size: 16),
                          label: const Text('粘贴'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 解析结果
            if (_isAnalyzing)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              )
            else if (_parseResult != null)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            '识别成功',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Text(
                        '分类：${_parseResult!.categoryName}',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        '视频数量：${_parseResult!.validVideos.length}',
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      const Text(
                        '视频列表：',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Expanded(
                        child: ListView.builder(
                          itemCount: _parseResult!.validVideos.length,
                          itemBuilder: (context, index) {
                            final video = _parseResult!.validVideos[index];
                            final isInPlaylist = AuthService.isVideoInPlaylist(video.videoId!);
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isInPlaylist 
                                    ? Colors.orange.withOpacity(0.1) 
                                    : Colors.grey[800],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isInPlaylist 
                                      ? Colors.orange.withOpacity(0.5) 
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      'https://img.youtube.com/vi/${video.videoId}/mqdefault.jpg',
                                      width: 60,
                                      height: 34,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 60,
                                          height: 34,
                                          color: Colors.grey[700],
                                          child: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          video.title,
                                          style: TextStyle(
                                            color: isInPlaylist ? Colors.orange : Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(0.7),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                video.category,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                            if (isInPlaylist) ...[
                                              const SizedBox(width: 8),
                                              const Text(
                                                '已存在',
                                                style: TextStyle(
                                                  color: Colors.orange,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_textController.text.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '无法识别分享内容，请确保粘贴的是完整的LearnMate App分享文本',
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // 导入按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _parseResult == null || _isImporting 
                    ? null 
                    : _importVideos,
                icon: _isImporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.download),
                label: Text(_isImporting ? '导入中...' : '导入到播放列表'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
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