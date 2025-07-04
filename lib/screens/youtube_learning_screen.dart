import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/transcript.dart';
import '../services/transcript_service.dart';
import '../services/auth_service.dart';

class YoutubeLearningScreen extends StatefulWidget {
  const YoutubeLearningScreen({Key? key}) : super(key: key);

  @override
  State<YoutubeLearningScreen> createState() => _YoutubeLearningScreenState();
}

class _YoutubeLearningScreenState extends State<YoutubeLearningScreen> {
  YoutubePlayerController? _controller;
  TextEditingController _urlController = TextEditingController();
  Transcript? _transcript;
  bool _isLoading = false;
  bool _isHeaderVisible = true;
  bool _isLoopMode = false;
  
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
  
  // 动画控制器（保留用于其他可能的动画）

  @override
  void initState() {
    super.initState();
    _initializeWithSampleVideo();
  }

  void _initializeWithSampleVideo() {
    const sampleVideoId = '8YkkvVe_Z8w'; // 设置一个默认视频
    _urlController.text = 'https://m.youtube.com/watch?v=$sampleVideoId';
    _loadVideo(sampleVideoId);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _urlController.dispose();
    _transcriptScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadVideo(String videoId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      _controller?.dispose();
      
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          loop: _isLoopMode,
          showLiveFullscreenButton: false,
        ),
      );

      _controller!.addListener(_onPlayerStateChanged);

      final transcript = await TranscriptService.getTranscript(videoId);
      
      // 初始化字幕项目的GlobalKey列表
      if (transcript != null) {
        _transcriptItemKeys = List.generate(
          transcript.segments.length,
          (index) => GlobalKey(),
        );
      }
      
      setState(() {
        _transcript = transcript;
        _isLoading = false;
      });

      AuthService.addRecentVideo(videoId);
    } catch (e) {
      setState(() {
        _isLoading = false;
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

    _updateTranscriptHighlight();
    
    // 检查循环模式
    if (_isLoopMode && position >= _loopEndTime) {
      _controller!.seekTo(Duration(seconds: _loopStartTime.toInt()));
    }
  }

  void _updateTranscriptHighlight() {
    if (_transcript == null) return;

    int currentSegmentIndex = -1;
    for (int i = 0; i < _transcript!.segments.length; i++) {
      final segment = _transcript!.segments[i];
      if (_currentPosition >= segment.startTime && 
          _currentPosition < segment.endTime) {
        currentSegmentIndex = i;
        break;
      }
    }

    // 高亮下一个段落（提前显示）
    int highlightSegmentIndex = currentSegmentIndex >= 0 && 
        currentSegmentIndex + 1 < _transcript!.segments.length
        ? currentSegmentIndex + 1
        : currentSegmentIndex;

    if (highlightSegmentIndex != _highlightedSegmentIndex) {
      setState(() {
        _currentSegmentIndex = currentSegmentIndex;
        _highlightedSegmentIndex = highlightSegmentIndex;
      });
      _scrollToHighlightedSegment();
    }
  }

  void _scrollToHighlightedSegment() {
    if (_highlightedSegmentIndex < 0 || 
        _transcript == null || 
        _highlightedSegmentIndex >= _transcriptItemKeys.length) return;

    // 使用GlobalKey进行精确定位
    final targetKey = _transcriptItemKeys[_highlightedSegmentIndex];
    final targetContext = targetKey.currentContext;
    
    if (targetContext != null) {
      try {
        // 使用Scrollable.ensureVisible实现居中对齐
        Scrollable.ensureVisible(
          targetContext,
          alignment: 0.5, // 0.5 表示居中
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } catch (e) {
        // 如果ensureVisible失败，稍微延迟后使用备用方法
        Future.delayed(const Duration(milliseconds: 100), () {
          _fallbackScrollToCenter();
        });
      }
    } else {
      // 如果context不可用，稍微延迟后重试或使用备用方法
      Future.delayed(const Duration(milliseconds: 100), () {
        final retryContext = targetKey.currentContext;
        if (retryContext != null) {
          try {
            Scrollable.ensureVisible(
              retryContext,
              alignment: 0.5,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } catch (e) {
            _fallbackScrollToCenter();
          }
        } else {
          _fallbackScrollToCenter();
        }
      });
    }
  }
  
  void _fallbackScrollToCenter() {
    if (_highlightedSegmentIndex < 0 || _transcript == null) return;
    
    // 改进的高度估算，考虑字体大小
    final estimatedTimeTextHeight = _currentFontSize * 0.8 * 1.2; // 加上行高
    final estimatedMainTextHeight = _currentFontSize * 1.2; // 加上行高
    final estimatedItemHeight = 12.0 + // margin bottom
                               12.0 + // padding all (top)
                               estimatedTimeTextHeight +
                               4.0 + // SizedBox height
                               estimatedMainTextHeight +
                               12.0; // padding all (bottom)
    
    // 获取viewport高度
    final viewportHeight = _transcriptScrollController.position.viewportDimension;
    
    // 计算目标偏移量使项目居中
    final targetOffset = (_highlightedSegmentIndex * estimatedItemHeight) - 
                        (viewportHeight / 2) + 
                        (estimatedItemHeight / 2);
    
    // 确保偏移量在有效范围内
    final maxOffset = _transcriptScrollController.position.maxScrollExtent;
    final clampedOffset = targetOffset.clamp(0.0, maxOffset);
    
    _transcriptScrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _toggleLoopMode() {
    setState(() {
      _isLoopMode = !_isLoopMode;
    });
    
    if (_isLoopMode) {
      // 设置循环范围：当前时间前后5秒
      _loopStartTime = (_currentPosition - 5.0).clamp(0.0, _videoDuration);
      _loopEndTime = (_currentPosition + 5.0).clamp(0.0, _videoDuration);
      
    } else {
    }
  }

  void _adjustLoopWithRewind() {
    if (!_isLoopMode) return;
    
    final duration = _loopEndTime - _loopStartTime;
    _loopStartTime = (_loopStartTime - 10.0).clamp(0.0, _videoDuration);
    _loopEndTime = (_loopStartTime + duration).clamp(0.0, _videoDuration);
    
  }

  void _adjustLoopWithForward() {
    if (!_isLoopMode) return;
    
    final duration = _loopEndTime - _loopStartTime;
    _loopStartTime = (_loopStartTime + 10.0).clamp(0.0, _videoDuration);
    _loopEndTime = (_loopStartTime + duration).clamp(0.0, _videoDuration);
    
  }

  void _cycleFontSize() {
    final currentIndex = _fontSizes.indexOf(_currentFontSize);
    final nextIndex = (currentIndex + 1) % _fontSizes.length;
    setState(() {
      _currentFontSize = _fontSizes[nextIndex];
    });
    
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

  void _onPlayVideo() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      return;
    }

    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId == null) {
      return;
    }

    _loadVideo(videoId);
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
    if (_transcript == null) {
      return const Center(
        child: Text(
          'Paste a YouTube video URL above and tap "Play Video" to start learning English!',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      controller: _transcriptScrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _transcript!.segments.length,
      itemBuilder: (context, index) {
        final segment = _transcript!.segments[index];
        final isHighlighted = index == _highlightedSegmentIndex;
        
        // 确保有足够的GlobalKey
        if (index >= _transcriptItemKeys.length) {
          _transcriptItemKeys.add(GlobalKey());
        }
        
        return GestureDetector(
          onTap: () => _seekToSegment(segment),
          child: Container(
            key: _transcriptItemKeys[index], // 添加GlobalKey
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
            child: Column(
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
                Text(
                  segment.text,
                  style: TextStyle(
                    fontSize: _currentFontSize,
                    color: isHighlighted ? Colors.green : Colors.white,
                    fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section - 使用Visibility确保稳定的widget树
            Container(
              color: Colors.black,
              child: Column(
                children: [
                  // 控制面板部分 - 使用Visibility而不是高度动画
                  Visibility(
                    visible: _isHeaderVisible,
                    maintainState: true,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'YouTube English Learning',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // URL Input
                          TextField(
                            controller: _urlController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Paste YouTube video URL here',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.blue),
                              ),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          
                          // Control Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _onPlayVideo,
                                  child: const Text('Play Video'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _urlController.clear(),
                                  child: const Text('Clear'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  
                  // YouTube Player - 独立的稳定容器，始终保持在widget树中
                  if (_controller != null)
                    Visibility(
                      visible: _isHeaderVisible,
                      maintainState: true,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: YoutubePlayer(
                            controller: _controller!,
                            showVideoProgressIndicator: true,
                            progressIndicatorColor: Colors.red,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Transcript Section - 根据header状态动态调整大小
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
              onPressed: _isLoopMode ? _adjustLoopWithRewind : () {
                if (_controller != null) {
                  final newTime = (_currentPosition - 10.0).clamp(0.0, _videoDuration);
                  _seekToTime(newTime);
                }
              },
              icon: const Icon(Icons.replay_10, color: Colors.white),
              tooltip: '后退10秒',
            ),
            IconButton(
              onPressed: () {
                if (_controller != null) {
                  if (_isPlaying) {
                    _controller!.pause();
                  } else {
                    _controller!.play();
                  }
                }
              },
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
              tooltip: '播放/暂停',
            ),
            IconButton(
              onPressed: _isLoopMode ? _adjustLoopWithForward : () {
                if (_controller != null) {
                  final newTime = (_currentPosition + 10.0).clamp(0.0, _videoDuration);
                  _seekToTime(newTime);
                }
              },
              icon: const Icon(Icons.forward_10, color: Colors.white),
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
          ],
        );
  }
}