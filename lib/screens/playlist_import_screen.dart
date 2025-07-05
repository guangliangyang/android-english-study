import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/youtube_playlist_service.dart';
import '../services/auth_service.dart';
import '../models/playlist.dart';

class PlaylistImportScreen extends StatefulWidget {
  final String? initialUrl;
  
  const PlaylistImportScreen({Key? key, this.initialUrl}) : super(key: key);

  @override
  State<PlaylistImportScreen> createState() => _PlaylistImportScreenState();
}

class _PlaylistImportScreenState extends State<PlaylistImportScreen> {
  final TextEditingController _urlController = TextEditingController();
  PlaylistInfo? _playlistInfo;
  List<PlaylistItem>? _playlistVideos;
  bool _isAnalyzing = false;
  bool _isImporting = false;
  bool _isLoadingVideos = false;
  int _importedCount = 0;
  int _skippedCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialUrl != null) {
      _urlController.text = widget.initialUrl!;
      _analyzeUrl();
    } else {
      _checkClipboardOnStart();
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _checkClipboardOnStart() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text?.trim();
      
      if (text != null && text.isNotEmpty && YouTubePlaylistService.isPlaylistUrl(text)) {
        setState(() {
          _urlController.text = text;
        });
        _analyzeUrl();
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
          _urlController.text = text;
        });
        _analyzeUrl();
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

  void _analyzeUrl() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _playlistInfo = null;
        _playlistVideos = null;
      });
      return;
    }

    if (!YouTubePlaylistService.isPlaylistUrl(url)) {
      setState(() {
        _playlistInfo = null;
        _playlistVideos = null;
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _playlistInfo = null;
      _playlistVideos = null;
    });

    _fetchPlaylistInfo(url);
  }

  Future<void> _fetchPlaylistInfo(String url) async {
    try {
      final playlistId = YouTubePlaylistService.extractPlaylistId(url);
      if (playlistId == null) {
        if (mounted) {
          setState(() {
            _isAnalyzing = false;
          });
        }
        return;
      }

      final playlistInfo = await YouTubePlaylistService.getPlaylistInfo(playlistId);
      
      if (mounted) {
        setState(() {
          _playlistInfo = playlistInfo;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('获取播放列表信息失败: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _loadPlaylistVideos() async {
    if (_playlistInfo == null) return;

    setState(() {
      _isLoadingVideos = true;
    });

    try {
      final videos = await YouTubePlaylistService.getPlaylistVideos(_playlistInfo!);
      
      if (mounted) {
        setState(() {
          _playlistVideos = videos;
          _isLoadingVideos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingVideos = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('获取视频列表失败: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _importPlaylist() async {
    if (_playlistVideos == null || _playlistVideos!.isEmpty) return;
    
    setState(() {
      _isImporting = true;
      _importedCount = 0;
      _skippedCount = 0;
    });

    try {
      for (final video in _playlistVideos!) {
        // 检查是否已存在
        if (AuthService.isVideoInPlaylist(video.videoId)) {
          _skippedCount++;
          continue;
        }

        // 添加到播放列表
        await AuthService.addToPlaylist(
          video.videoId,
          title: video.title,
          thumbnail: video.thumbnail,
          duration: video.duration,
          channelName: video.channelName,
          category: video.category, // 使用播放列表名称作为分类
        );
        
        _importedCount++;
        
        // 更新UI显示进度
        if (mounted) {
          setState(() {});
        }
        
        // 添加小延迟避免过快
        await Future.delayed(const Duration(milliseconds: 50));
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
    final total = _playlistVideos!.length;
    
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
              '播放列表：${_playlistInfo!.title}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              '总视频数：$total',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            Text(
              '成功导入：$_importedCount',
              style: const TextStyle(color: Colors.green, fontSize: 14),
            ),
            if (_skippedCount > 0)
              Text(
                '跳过重复：$_skippedCount',
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
        title: const Text('导入YouTube播放列表'),
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
            // 输入框
            const Text(
              '播放列表链接：',
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
                    controller: _urlController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: '粘贴YouTube播放列表链接...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    onChanged: (value) {
                      // 实时分析
                      _analyzeUrl();
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
                          '支持：youtube.com/playlist?list=...',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        TextButton.icon(
                          onPressed: _pasteFromClipboard,
                          icon: const Icon(Icons.content_paste, size: 16),
                          label: const Text('粘贴'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.purple,
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
            
            // 分析结果
            if (_isAnalyzing)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '正在分析播放列表...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else if (_playlistInfo != null)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            '播放列表识别成功',
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
                        '标题：${_playlistInfo!.title}',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      if (_playlistInfo!.creator != null)
                        Text(
                          '创建者：${_playlistInfo!.creator}',
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        '视频数量：${_playlistInfo!.videoIds.length}',
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      if (_playlistVideos == null && !_isLoadingVideos)
                        ElevatedButton.icon(
                          onPressed: _loadPlaylistVideos,
                          icon: const Icon(Icons.preview),
                          label: const Text('预览视频列表'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      
                      if (_isLoadingVideos)
                        const Column(
                          children: [
                            LinearProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '正在获取视频信息...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      
                      if (_playlistVideos != null)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                  itemCount: _playlistVideos!.length,
                                  itemBuilder: (context, index) {
                                    final video = _playlistVideos![index];
                                    final isInPlaylist = AuthService.isVideoInPlaylist(video.videoId);
                                    
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
                                              video.thumbnail ?? 'https://img.youtube.com/vi/${video.videoId}/mqdefault.jpg',
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
                                                if (isInPlaylist)
                                                  const Text(
                                                    '已在播放列表中',
                                                    style: TextStyle(
                                                      color: Colors.orange,
                                                      fontSize: 12,
                                                    ),
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
                    ],
                  ),
                ),
              )
            else if (_urlController.text.isNotEmpty)
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
                        '无法识别播放列表链接，请确保输入的是有效的YouTube播放列表URL',
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
                onPressed: _playlistVideos == null || _isImporting 
                    ? null 
                    : _importPlaylist,
                icon: _isImporting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          value: _playlistVideos != null && _playlistVideos!.isNotEmpty 
                              ? (_importedCount + _skippedCount) / _playlistVideos!.length 
                              : null,
                        ),
                      )
                    : const Icon(Icons.download),
                label: Text(_isImporting 
                    ? '导入中... ($_importedCount/${_playlistVideos?.length ?? 0})' 
                    : '导入播放列表'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
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