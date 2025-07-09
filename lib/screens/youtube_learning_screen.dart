import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/transcript.dart';
import '../services/transcript_service.dart';
import '../services/ai_transcript_service.dart';
import '../services/auth_service.dart';
import '../services/background_audio_service.dart';
import '../services/app_guide_service.dart';
import '../services/video_metadata_service.dart';
import '../widgets/word_definition_dialog.dart';

class YoutubeLearningScreen extends StatefulWidget {
  final String? videoId;
  
  const YoutubeLearningScreen({Key? key, this.videoId}) : super(key: key);

  @override
  State<YoutubeLearningScreen> createState() => _YoutubeLearningScreenState();
}

class _YoutubeLearningScreenState extends State<YoutubeLearningScreen> {
  YoutubePlayerController? _controller;
  Transcript? _transcript;
  EnhancedTranscript? _aiTranscript;
  bool _isUsingAITranscript = false;
  bool _isLoading = false;
  bool _isHeaderVisible = true;
  bool _isLoopMode = false;
  String _videoTitle = 'English Study';
  
  // 播放状态
  double _currentPosition = 0.0;
  double _videoDuration = 0.0;
  bool _isPlaying = false;
  bool _isSeekBarTracking = false;
  
  // 复读模式参数
  double _loopStartTime = 0.0;
  double _loopEndTime = 0.0;
  
  // 字幕相关
  int _currentSegmentIndex = -1;
  int _highlightedSegmentIndex = -1;
  ScrollController _transcriptScrollController = ScrollController();
  List<GlobalKey> _transcriptItemKeys = [];
  
  // 字体大小
  double _currentFontSize = 16.0;
  final List<double> _fontSizes = [14.0, 16.0, 18.0, 20.0, 24.0];
  
  
  // 后台音频服务 (默认启用)
  BackgroundAudioService? _backgroundAudioService;
  
  
  // 动画控制器（保留用于其他可能的动画）

  @override
  void initState() {
    super.initState();
    _loadSavedFontSize();
    if (widget.videoId != null) {
      _loadVideo(widget.videoId!);
    }
    _initializeBackgroundAudio();
  }

  
  Future<void> _initializeBackgroundAudio() async {
    try {
      _backgroundAudioService = await AudioService.init(
        builder: () => BackgroundAudioService.instance,
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.englishstudy.app.audio',
          androidNotificationChannelName: 'English Study Audio',
          androidNotificationOngoing: true,
          androidNotificationIcon: 'mipmap/ic_launcher',
          androidShowNotificationBadge: true,
        ),
      );
      
      // Listen to background audio position updates for transcript sync
      _backgroundAudioService?.transcriptUpdateStream.listen((positionString) {
        // 后台播放默认启用，直接同步位置
        final position = double.tryParse(positionString) ?? 0.0;
        setState(() {
          _currentPosition = position;
        });
        _forceScrollToCurrentPosition();
      });
    } catch (e) {
      // Handle initialization error silently
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _transcriptScrollController.dispose();
    _backgroundAudioService?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _loadVideo(String videoId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 停止并释放旧的控制器
      if (_controller != null) {
        _controller!.removeListener(_onPlayerStateChanged);
        _controller!.pause();
        _controller!.dispose();
        _controller = null;
      }
      
      // 重置播放状态
      _currentPosition = 0.0;
      _videoDuration = 0.0;
      _isPlaying = false;
      _isSeekBarTracking = false;
      _currentSegmentIndex = -1;
      _highlightedSegmentIndex = -1;
      _loopStartTime = 0.0;
      _loopEndTime = 0.0;
      
      // 确保UI更新显示加载状态
      setState(() {});
      
      // 短暂延迟确保旧控制器完全释放
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 创建新的控制器
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          loop: _isLoopMode,
          showLiveFullscreenButton: false,
          enableCaption: true,
          controlsVisibleAtStart: true,
          hideThumbnail: true,
        ),
      );

      _controller!.addListener(_onPlayerStateChanged);

      final transcript = await TranscriptService.getTranscript(videoId);
      
      // 检查是否有AI字幕
      final aiTranscript = await AITranscriptService.loadAITranscript(videoId);
      
      // 获取视频标题
      String videoTitle = 'English Study';
      try {
        // 首先尝试从VideoMetadataService获取实时标题
        final metadata = await VideoMetadataService.getVideoMetadata(videoId);
        if (metadata != null && metadata.title.isNotEmpty && metadata.title != 'Video $videoId') {
          videoTitle = metadata.title;
          print('Got video title from metadata: $videoTitle');
        } else {
          // 如果元数据服务失败，尝试从播放列表获取
          final playlistItem = AuthService.getPlaylistVideo(videoId);
          if (playlistItem != null && playlistItem.title.isNotEmpty) {
            videoTitle = playlistItem.title;
            print('Got video title from playlist: $videoTitle');
          } else {
            print('Failed to get video title, using default: $videoTitle');
          }
        }
      } catch (e) {
        print('Error getting video title: $e');
      }
      
      // 初始化字幕项目的GlobalKey列表
      final transcriptToUse = aiTranscript?.toTranscript() ?? transcript;
      if (transcriptToUse != null) {
        _transcriptItemKeys = List.generate(
          transcriptToUse.segments.length,
          (index) => GlobalKey(),
        );
      } else {
        _transcriptItemKeys.clear();
      }
      
      setState(() {
        _transcript = transcript;
        _aiTranscript = aiTranscript;
        _isUsingAITranscript = aiTranscript != null;
        _videoTitle = videoTitle;
        _isLoading = false;
      });

      // 首次使用时显示生词功能引导
      _showVocabularyGuideIfNeeded();

      // Setup background audio service for the new video
      if (_backgroundAudioService != null && transcript != null) {
        try {
          await _backgroundAudioService!.setupAudioSource(
            videoId,
            'English Study - $videoId',
          );
        } catch (e) {
          // Handle audio setup error silently
        }
      }

      AuthService.addRecentVideo(videoId);
      
      // Auto-save to playlist
      await AuthService.addToPlaylist(videoId);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _videoTitle = 'English Study'; // 错误时重置为默认标题
      });
      // 静默处理错误，不显示toast
    }
  }

  void _onPlayerStateChanged() {
    if (_controller == null) return;

    final position = _controller!.value.position.inSeconds.toDouble();
    final duration = _controller!.value.metaData.duration.inSeconds.toDouble();
    final isPlaying = _controller!.value.isPlaying;

    setState(() {
      _currentPosition = position;
      _videoDuration = duration;
      _isPlaying = isPlaying;
    });

    // Sync with background audio service (默认启用)
    if (_backgroundAudioService != null && _backgroundAudioService!.isAudioReady) {
      _backgroundAudioService!.syncPosition(Duration(seconds: position.toInt()));
      _backgroundAudioService!.syncPlaybackState(isPlaying);
    }

    _forceScrollToCurrentPosition();
    
    // Enable/disable wakelock based on playing state
    if (isPlaying) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
    
    // 检查视频是否播放完毕，自动重播
    if (!_isLoopMode && duration > 0 && position >= duration - 1) {
      // 视频播放完毕，自动从头开始播放
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_controller != null) {
          _controller!.seekTo(Duration.zero);
          _controller!.play();
        }
      });
    }
    
    // 检查循环模式
    if (_isLoopMode && position >= _loopEndTime) {
      _controller!.seekTo(Duration(seconds: _loopStartTime.toInt()));
    }
  }

  void _updateTranscriptHighlight() {
    final transcriptToUse = _isUsingAITranscript ? _aiTranscript?.toTranscript() : _transcript;
    if (transcriptToUse == null) return;

    int currentSegmentIndex = -1;
    for (int i = 0; i < transcriptToUse.segments.length; i++) {
      final segment = transcriptToUse.segments[i];
      final nextSegment = i + 1 < transcriptToUse.segments.length ? transcriptToUse.segments[i + 1] : null;
      
      // 当前位置在当前段落startTime和下一个段落startTime之间
      // 对于最后一条字幕，只要播放进度>=startTime就匹配
      if (_currentPosition >= segment.startTime && 
          (nextSegment == null || _currentPosition < nextSegment.startTime)) {
        currentSegmentIndex = i;
        break;
      }
    }

    // 高亮当前正在播放的段落（精确同步）
    int highlightSegmentIndex = currentSegmentIndex;

    if (highlightSegmentIndex != _highlightedSegmentIndex) {
      setState(() {
        _currentSegmentIndex = currentSegmentIndex;
        _highlightedSegmentIndex = highlightSegmentIndex;
      });
      _scrollToHighlightedSegment();
    }
  }

  void _scrollToHighlightedSegment() {
    // 由于使用滑动窗口，当前字幕总是在可视范围内
    // 确保当前字幕完整显示，上面预留一行字的空间
    if (_highlightedSegmentIndex < 0 || 
        _transcript == null || 
        _highlightedSegmentIndex >= _transcriptItemKeys.length) {
      return;
    }

    // 使用当前字幕的GlobalKey进行精确定位
    final targetKey = _transcriptItemKeys[_highlightedSegmentIndex];
    final targetContext = targetKey.currentContext;
    
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        alignment: 0.15, // 让当前字幕显示在稍微偏下的位置，上面预留空间显示前一条字幕
        duration: Duration.zero, // 去除动画效果
      );
    }
  }

  

  void _forceScrollToCurrentPosition() {
    if (_transcript == null || _controller == null) return;
    
    // 立即计算当前位置应该对应的字幕段落
    final currentPosition = _controller!.value.position.inSeconds.toDouble();
    
    int targetSegmentIndex = -1;
    final transcriptToUse = _isUsingAITranscript ? _aiTranscript?.toTranscript() : _transcript;
    if (transcriptToUse != null) {
      for (int i = 0; i < transcriptToUse.segments.length; i++) {
        final segment = transcriptToUse.segments[i];
        final nextSegment = i + 1 < transcriptToUse.segments.length ? transcriptToUse.segments[i + 1] : null;
        
        // 当前位置在当前段落startTime和下一个段落startTime之间
        // 对于最后一条字幕，只要播放进度>=startTime就匹配
        if (currentPosition >= segment.startTime && 
            (nextSegment == null || currentPosition < nextSegment.startTime)) {
          targetSegmentIndex = i;
          break;
        }
      }
    }

    if (targetSegmentIndex >= 0 && transcriptToUse != null) {
      // 高亮当前段落
      final highlightSegmentIndex = targetSegmentIndex;

      // 强制更新高亮状态
      setState(() {
        _currentSegmentIndex = targetSegmentIndex;
        _highlightedSegmentIndex = highlightSegmentIndex;
      });

      // 确保UI更新完成后再滚动
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_highlightedSegmentIndex >= 0) {
          _scrollToHighlightedSegment();
        }
      });
    }
  }

  void _toggleLoopMode() {
    setState(() {
      _isLoopMode = !_isLoopMode;
    });
    
    if (_isLoopMode) {
      // 设置循环范围：当前时间前后5秒
      _loopStartTime = (_currentPosition - 5.0).clamp(0.0, _videoDuration);
      _loopEndTime = (_currentPosition + 5.0).clamp(0.0, _videoDuration);
      
      // 切换到循环模式后重新居中字幕
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _forceScrollToCurrentPosition();
        });
      });
    } else {
      // 退出循环模式后也重新居中字幕
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _forceScrollToCurrentPosition();
        });
      });
    }
  }

  void _adjustLoopWithRewind() {
    if (!_isLoopMode) return;
    
    final duration = _loopEndTime - _loopStartTime;
    _loopStartTime = (_loopStartTime - 10.0).clamp(0.0, _videoDuration);
    _loopEndTime = (_loopStartTime + duration).clamp(0.0, _videoDuration);
    
    // 调整循环范围后强制滚动到对应的字幕位置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _forceScrollToCurrentPosition();
      });
    });
  }

  void _adjustLoopWithForward() {
    if (!_isLoopMode) return;
    
    final duration = _loopEndTime - _loopStartTime;
    _loopStartTime = (_loopStartTime + 10.0).clamp(0.0, _videoDuration);
    _loopEndTime = (_loopStartTime + duration).clamp(0.0, _videoDuration);
    
    // 调整循环范围后强制滚动到对应的字幕位置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _forceScrollToCurrentPosition();
      });
    });
  }

  Future<void> _loadSavedFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedFontSize = prefs.getDouble('transcript_font_size');
      if (savedFontSize != null && _fontSizes.contains(savedFontSize)) {
        setState(() {
          _currentFontSize = savedFontSize;
        });
      }
    } catch (e) {
      // 静默处理错误，使用默认字体大小
    }
  }

  Future<void> _saveFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('transcript_font_size', _currentFontSize);
    } catch (e) {
      // 静默处理错误
    }
  }

  void _cycleFontSize() {
    final currentIndex = _fontSizes.indexOf(_currentFontSize);
    final nextIndex = (currentIndex + 1) % _fontSizes.length;
    setState(() {
      _currentFontSize = _fontSizes[nextIndex];
    });
    
    // 保存字体大小设置
    _saveFontSize();
    
    // 字体大小变化后重新居中当前高亮的transcript
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_highlightedSegmentIndex >= 0) {
        _scrollToHighlightedSegment();
      }
    });
  }

  void _seekToTime(double seconds) {
    if (_controller != null) {
      _controller!.seekTo(Duration(seconds: seconds.toInt()));
      AuthService.incrementSegmentClicks();
      
      // 手动seek后强制滚动到对应的字幕位置
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 延迟一点让视频播放器更新位置
        Future.delayed(const Duration(milliseconds: 100), () {
          _forceScrollToCurrentPosition();
        });
      });
    }
  }

  void _seekToSegment(TranscriptSegment segment) {
    _seekToTime(segment.startTime);
    
    if (_isLoopMode) {
      _loopStartTime = segment.startTime;
      final segmentDuration = segment.endTime - segment.startTime;
      _loopEndTime = segment.startTime + segmentDuration.clamp(3.0, 10.0);
      
    }
  }

  void _onWordSelected(String word) {
    // 暂停视频播放
    if (_controller != null && _isPlaying) {
      _controller!.pause();
    }
    
    // 显示单词查询对话框
    _showWordDefinitionDialog(word);
  }

  void _showWordDefinitionDialog(String word) {
    showDialog(
      context: context,
      builder: (context) => WordDefinitionDialog(word: word),
    );
  }

  Widget _buildCustomContextMenu(BuildContext context, EditableTextState editableTextState, String fullText) {
    final TextEditingValue value = editableTextState.textEditingValue;
    final List<ContextMenuButtonItem> buttonItems = <ContextMenuButtonItem>[];

    // 获取选中的文本
    final String selectedText = value.selection.textInside(value.text);
    
    // 添加默认的复制按钮（如果有选中文本）
    if (selectedText.isNotEmpty) {
      buttonItems.add(
        ContextMenuButtonItem(
          onPressed: () {
            ContextMenuController.removeAny();
            editableTextState.copySelection(SelectionChangedCause.toolbar);
          },
          type: ContextMenuButtonType.copy,
        ),
      );
    }

    // 添加全选按钮
    buttonItems.add(
      ContextMenuButtonItem(
        onPressed: () {
          ContextMenuController.removeAny();
          editableTextState.selectAll(SelectionChangedCause.toolbar);
        },
        type: ContextMenuButtonType.selectAll,
      ),
    );

    // 添加生词查询按钮（如果有选中文本）
    if (selectedText.isNotEmpty && selectedText.trim().split(' ').length <= 3) {
      buttonItems.add(
        ContextMenuButtonItem(
          onPressed: () {
            ContextMenuController.removeAny();
            // 清理选中的文本（去除标点符号）
            final cleanWord = selectedText.replaceAll(RegExp(r'[^\w\s]'), '').trim();
            if (cleanWord.isNotEmpty) {
              _onWordSelected(cleanWord);
            }
          },
          type: ContextMenuButtonType.custom,
          label: '查询生词',
        ),
      );
    }

    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: buttonItems,
    );
  }

  void _showVocabularyTip() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: const Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.amber),
            SizedBox(width: 8),
            Text('生词功能说明', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📚 如何使用生词功能：',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Text('1. ', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    '双击选择字幕中的单词',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text('2. ', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    '在弹出菜单中点击"查询生词"',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text('3. ', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    '查看音标、释义和例句',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text('4. ', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    '点击收藏按钮添加到生词本',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.volume_up, color: Colors.blue, size: 16),
                SizedBox(width: 4),
                Text(
                  '支持播放单词发音',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.book, color: Colors.amber, size: 16),
                SizedBox(width: 4),
                Text(
                  '从主菜单进入生词本查看收藏',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Future<void> _showVocabularyGuideIfNeeded() async {
    final hasShown = await AppGuideService.hasShownVocabularyGuide();
    if (!hasShown && mounted) {
      // 延迟显示，让页面加载完成
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        await AppGuideService.markVocabularyGuideShown();
        _showVocabularyWelcomeDialog();
      }
    }
  }

  void _showVocabularyWelcomeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.amber),
            SizedBox(width: 8),
            Text('新功能：生词查询', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎉 欢迎使用生词查询功能！',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              '现在你可以：',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.touch_app, color: Colors.blue, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '双击选择单词，在菜单中选择"查询生词"',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.bookmark_add, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '收藏生词到生词本',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.volume_up, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '播放单词发音',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '试试双击下面字幕中的单词吧！',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showVocabularyTip();
            },
            child: const Text('查看详细说明'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('开始使用', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _toggleHeaderVisibility() {
    setState(() {
      _isHeaderVisible = !_isHeaderVisible;
    });
    
    // 布局变化后重新居中当前高亮的transcript
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_highlightedSegmentIndex >= 0) {
        _scrollToHighlightedSegment();
      }
    });
  }

  String _formatTime(double seconds) {
    final totalSeconds = seconds.toInt();
    final minutes = totalSeconds ~/ 60;
    final remainingSeconds = totalSeconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildTranscriptWidget() {
    final transcriptToUse = _isUsingAITranscript ? _aiTranscript?.toTranscript() : _transcript;
    
    if (transcriptToUse == null) {
      return const Center(
        child: Text(
          'Paste a YouTube video URL above and tap "Play Video" to start learning English!',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    // 计算滑动窗口范围：当前字幕的前1条到后5条
    final currentIndex = _currentSegmentIndex >= 0 ? _currentSegmentIndex : 0;
    final startIndex = (currentIndex - 1).clamp(0, transcriptToUse.segments.length - 1);
    final endIndex = (currentIndex + 5).clamp(0, transcriptToUse.segments.length - 1);
    
    // 计算实际显示的字幕数量
    final visibleSegments = <TranscriptSegment>[];
    final segmentIndices = <int>[];
    
    for (int i = startIndex; i <= endIndex; i++) {
      visibleSegments.add(transcriptToUse.segments[i]);
      segmentIndices.add(i);
    }

    return Column(
      children: [
        // 字幕列表 - 只显示滑动窗口内的字幕
        Expanded(
          child: ListView.builder(
            controller: _transcriptScrollController,
            padding: const EdgeInsets.all(16),
            itemCount: visibleSegments.length,
            itemBuilder: (context, index) {
              final segment = visibleSegments[index];
              final originalIndex = segmentIndices[index];
              final isHighlighted = originalIndex == _highlightedSegmentIndex;
              
              // 确保有足够的GlobalKey
              if (originalIndex >= _transcriptItemKeys.length) {
                while (_transcriptItemKeys.length <= originalIndex) {
                  _transcriptItemKeys.add(GlobalKey());
                }
              }
              
              return GestureDetector(
                onTap: () => _seekToSegment(segment),
                child: Container(
                  key: _transcriptItemKeys[originalIndex], // 使用原始索引的GlobalKey
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isHighlighted 
                        ? Colors.green.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isHighlighted 
                        ? Border.all(color: Colors.green, width: 2)
                        : null,
                  ),
                  child: _isUsingAITranscript 
                      ? _buildAITranscriptItem(segment, isHighlighted, originalIndex)
                      : _buildOriginalTranscriptItem(segment, isHighlighted),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOriginalTranscriptItem(TranscriptSegment segment, bool isHighlighted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '[${_formatTime(segment.startTime)}]',
          style: TextStyle(
            color: Colors.blue,
            fontSize: _currentFontSize * 0.8,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          segment.text,
          style: TextStyle(
            fontSize: _currentFontSize,
            color: isHighlighted ? Colors.green : Colors.white,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          ),
          contextMenuBuilder: (context, editableTextState) {
            return _buildCustomContextMenu(context, editableTextState, segment.text);
          },
        ),
      ],
    );
  }

  Widget _buildAITranscriptItem(TranscriptSegment segment, bool isHighlighted, int index) {
    // 查找对应的AI增强句子
    Sentence? aiSentence;
    if (_aiTranscript != null) {
      for (final sentence in _aiTranscript!.sentences) {
        if (sentence.startTime <= segment.startTime && sentence.endTime >= segment.endTime) {
          aiSentence = sentence;
          break;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 时间戳
        Text(
          '[${_formatTime(segment.startTime)}]',
          style: TextStyle(
            color: Colors.blue,
            fontSize: _currentFontSize * 0.8,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        
        // 英文文本
        SelectableText(
          segment.text,
          style: TextStyle(
            fontSize: _currentFontSize,
            color: isHighlighted ? Colors.green : Colors.white,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          ),
          contextMenuBuilder: (context, editableTextState) {
            return _buildCustomContextMenu(context, editableTextState, segment.text);
          },
        ),
        
        // AI增强内容
        if (aiSentence != null) ...[
          // 中文翻译
          if (aiSentence.chineseTranslation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              aiSentence.chineseTranslation,
              style: TextStyle(
                fontSize: _currentFontSize * 0.9,
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          
          // 关键词
          if (aiSentence.keywords.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: aiSentence.keywords.map((keyword) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${keyword.english} - ${keyword.chinese}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          
          // 发音指导
          if (aiSentence.pronunciation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.record_voice_over,
                    size: 16,
                    color: Colors.purple[300],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      aiSentence.pronunciation,
                      style: TextStyle(
                        color: Colors.purple[300],
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // 语法解释
          if (aiSentence.explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: Colors.green[300],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      aiSentence.explanation,
                      style: TextStyle(
                        color: Colors.green[300],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  void _toggleTranscriptMode() {
    setState(() {
      _isUsingAITranscript = !_isUsingAITranscript;
      
      // 重新初始化GlobalKey列表
      final transcriptToUse = _isUsingAITranscript ? _aiTranscript?.toTranscript() : _transcript;
      if (transcriptToUse != null) {
        _transcriptItemKeys = List.generate(
          transcriptToUse.segments.length,
          (index) => GlobalKey(),
        );
      }
      
      // 重置高亮状态
      _currentSegmentIndex = -1;
      _highlightedSegmentIndex = -1;
    });
    
    // 确保ListView重建后再更新高亮位置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _forceScrollToCurrentPosition();
    });
  }

  Widget _buildKeywordOverlay() {
    // 只有在使用AI字幕模式且有当前段落时才显示
    if (!_isUsingAITranscript || _aiTranscript == null || _currentSegmentIndex < 0) {
      return const SizedBox.shrink();
    }

    if (_currentSegmentIndex >= _aiTranscript!.sentences.length) {
      return const SizedBox.shrink();
    }

    final currentSentence = _aiTranscript!.sentences[_currentSegmentIndex];
    final keywords = currentSentence.keywords;

    if (keywords.isEmpty) {
      return const SizedBox.shrink();
    }

    // 限制显示的关键词数量（最多4个）
    final displayKeywords = keywords.take(4).toList();

    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: displayKeywords.map((keyword) => _buildKeywordCard(keyword)).toList(),
        ),
      ),
    );
  }

  Widget _buildKeywordCard(dynamic keyword) {
    final english = keyword.english ?? '';
    final chinese = keyword.chinese ?? '';
    final type = keyword.type ?? '';

    if (english.isEmpty) {
      return const SizedBox.shrink();
    }

    // 根据词性选择颜色
    Color typeColor;
    switch (type.toLowerCase()) {
      case 'noun':
      case 'n':
        typeColor = Colors.blue;
        break;
      case 'verb':
      case 'v':
        typeColor = Colors.green;
        break;
      case 'adjective':
      case 'adj':
        typeColor = Colors.orange;
        break;
      case 'adverb':
      case 'adv':
        typeColor = Colors.purple;
        break;
      default:
        typeColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: typeColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 英文词汇
          Text(
            english,
            style: TextStyle(
              color: Colors.white,
              fontSize: (_currentFontSize * 0.8).clamp(12.0, 18.0),
              fontWeight: FontWeight.bold,
            ),
          ),
          if (chinese.isNotEmpty) ...[
            const SizedBox(height: 2),
            // 中文翻译
            Text(
              chinese,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: (_currentFontSize * 0.7).clamp(10.0, 14.0),
              ),
            ),
          ],
          if (type.isNotEmpty) ...[
            const SizedBox(height: 2),
            // 词性标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                type,
                style: TextStyle(
                  color: typeColor,
                  fontSize: (_currentFontSize * 0.6).clamp(8.0, 12.0),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _videoTitle.isNotEmpty ? _videoTitle : 'English Study',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // YouTube Player - 使用Visibility控制显示但保持播放
            if (_controller != null)
              Visibility(
                visible: _isHeaderVisible,
                maintainState: true,
                maintainAnimation: true,
                maintainSize: false,
                child: Container(
                  color: Colors.black,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          YoutubePlayer(
                            controller: _controller!,
                            showVideoProgressIndicator: true,
                            progressIndicatorColor: Colors.red,
                          ),
                          // AI字幕关键词叠加层
                          _buildKeywordOverlay(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            
            // Transcript Section
            Expanded(
              child: Container(
                color: Colors.grey[900],
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildTranscriptWidget(),
              ),
            ),
            
            // Video Controls - 固定在最底部
            Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildVideoControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoControls() {
    return 
        // Control Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: _toggleHeaderVisibility,
              icon: Icon(
                _isHeaderVisible ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.white,
              ),
              tooltip: _isHeaderVisible ? '隐藏视频区域' : '显示视频区域',
            ),
            IconButton(
              onPressed: _cycleFontSize,
              icon: const Icon(Icons.text_fields, color: Colors.white),
              tooltip: '字体大小',
            ),
            IconButton(
              onPressed: _controller != null ? (_isLoopMode ? _adjustLoopWithRewind : () {
                final newTime = (_currentPosition - 10.0).clamp(0.0, _videoDuration);
                _seekToTime(newTime);
              }) : null,
              icon: Icon(
                Icons.replay_10, 
                color: _controller != null ? Colors.white : Colors.grey,
              ),
              tooltip: '后退10秒',
            ),
            IconButton(
              onPressed: _controller != null ? () {
                if (_isPlaying) {
                  _controller!.pause();
                } else {
                  _controller!.play();
                }
              } : null,
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: _controller != null ? Colors.white : Colors.grey,
                size: 32,
              ),
              tooltip: '播放/暂停',
            ),
            IconButton(
              onPressed: _controller != null ? (_isLoopMode ? _adjustLoopWithForward : () {
                final newTime = (_currentPosition + 10.0).clamp(0.0, _videoDuration);
                _seekToTime(newTime);
              }) : null,
              icon: Icon(
                Icons.forward_10, 
                color: _controller != null ? Colors.white : Colors.grey,
              ),
              tooltip: '前进10秒',
            ),
            IconButton(
              onPressed: _toggleLoopMode,
              icon: Icon(
                _isLoopMode ? Icons.repeat : Icons.format_list_bulleted,
                color: _isLoopMode ? Colors.green : Colors.white,
              ),
              tooltip: _isLoopMode ? '复读模式' : '顺序模式',
            ),
            // AI字幕切换按钮
            if (_transcript != null && _aiTranscript != null)
              IconButton(
                onPressed: _toggleTranscriptMode,
                icon: Icon(
                  _isUsingAITranscript ? Icons.auto_fix_high : Icons.subtitles,
                  color: _isUsingAITranscript ? Colors.green : Colors.white,
                ),
                tooltip: _isUsingAITranscript ? 'AI字幕模式' : '原始字幕模式',
              ),
          ],
        );
  }
}