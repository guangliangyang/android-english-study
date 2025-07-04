import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoControlsWidget extends StatefulWidget {
  final YoutubePlayerController controller;
  final bool isLoopMode;
  final VoidCallback onToggleLoop;
  final VoidCallback onToggleVisibility;

  const VideoControlsWidget({
    Key? key,
    required this.controller,
    required this.isLoopMode,
    required this.onToggleLoop,
    required this.onToggleVisibility,
  }) : super(key: key);

  @override
  State<VideoControlsWidget> createState() => _VideoControlsWidgetState();
}

class _VideoControlsWidgetState extends State<VideoControlsWidget> {
  double _currentPosition = 0.0;
  double _totalDuration = 0.0;
  bool _isPlaying = false;
  bool _isDragging = false;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onPlayerStateChanged);
    _updatePlayerState();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPlayerStateChanged);
    super.dispose();
  }

  void _onPlayerStateChanged() {
    if (widget.controller.value.isReady && !_isDragging) {
      setState(() {
        _currentPosition = widget.controller.value.position.inSeconds.toDouble();
        _totalDuration = widget.controller.value.metaData.duration.inSeconds.toDouble();
        _isPlaying = widget.controller.value.isPlaying;
      });
    }
  }

  void _updatePlayerState() {
    if (widget.controller.value.isReady) {
      setState(() {
        _currentPosition = widget.controller.value.position.inSeconds.toDouble();
        _totalDuration = widget.controller.value.metaData.duration.inSeconds.toDouble();
        _isPlaying = widget.controller.value.isPlaying;
      });
    }
  }

  void _seekToPosition(double position) {
    widget.controller.seekTo(Duration(seconds: position.toInt()));
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      widget.controller.pause();
    } else {
      widget.controller.play();
    }
  }

  void _skipSeconds(int seconds) {
    final newPosition = _currentPosition + seconds;
    final clampedPosition = newPosition.clamp(0.0, _totalDuration);
    _seekToPosition(clampedPosition);
  }

  void _setPlaybackSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    widget.controller.setPlaybackRate(speed);
  }

  String _formatTime(double seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withOpacity(0.9),
        border: Border(
          top: BorderSide(
            color: Colors.grey[700]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          _buildProgressBar(),
          
          const SizedBox(height: 16),
          
          // Main controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: Icons.replay_10,
                onPressed: () => _skipSeconds(-10),
                tooltip: '后退10秒',
              ),
              _buildControlButton(
                icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                onPressed: _togglePlayPause,
                tooltip: _isPlaying ? '暂停' : '播放',
                size: 40,
              ),
              _buildControlButton(
                icon: Icons.forward_10,
                onPressed: () => _skipSeconds(10),
                tooltip: '前进10秒',
              ),
              _buildControlButton(
                icon: widget.isLoopMode ? Icons.loop : Icons.loop,
                onPressed: widget.onToggleLoop,
                tooltip: widget.isLoopMode ? '关闭循环' : '开启循环',
                isActive: widget.isLoopMode,
              ),
              _buildControlButton(
                icon: Icons.speed,
                onPressed: _showSpeedDialog,
                tooltip: '播放速度',
              ),
              _buildControlButton(
                icon: Icons.visibility_off,
                onPressed: widget.onToggleVisibility,
                tooltip: '隐藏/显示视频',
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Additional controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '速度: ${_playbackSpeed}x',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              if (widget.isLoopMode)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '循环播放',
                    style: TextStyle(
                      color: Colors.deepOrange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        // Time indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatTime(_currentPosition),
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
            Text(
              _formatTime(_totalDuration),
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Progress slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.deepOrange,
            inactiveTrackColor: Colors.grey[700],
            thumbColor: Colors.deepOrange,
            overlayColor: Colors.deepOrange.withOpacity(0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: _totalDuration > 0 ? _currentPosition.clamp(0.0, _totalDuration) : 0.0,
            max: _totalDuration > 0 ? _totalDuration : 1.0,
            onChanged: (value) {
              setState(() {
                _currentPosition = value;
                _isDragging = true;
              });
            },
            onChangeEnd: (value) {
              _seekToPosition(value);
              setState(() {
                _isDragging = false;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    double size = 24,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive
              ? Colors.deepOrange.withOpacity(0.2)
              : Colors.grey[800]?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? Colors.deepOrange : Colors.grey[600]!,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(24),
            child: Center(
              child: Icon(
                icon,
                size: size,
                color: isActive ? Colors.deepOrange : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSpeedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('播放速度'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSpeedOption(0.5, '0.5x'),
            _buildSpeedOption(0.75, '0.75x'),
            _buildSpeedOption(1.0, '1.0x (正常)'),
            _buildSpeedOption(1.25, '1.25x'),
            _buildSpeedOption(1.5, '1.5x'),
            _buildSpeedOption(2.0, '2.0x'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedOption(double speed, String label) {
    final isSelected = _playbackSpeed == speed;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _setPlaybackSpeed(speed);
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.deepOrange.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.deepOrange : Colors.grey[600]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? Colors.deepOrange : Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.deepOrange : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}