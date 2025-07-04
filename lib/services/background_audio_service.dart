import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class BackgroundAudioService extends BaseAudioHandler {
  static BackgroundAudioService? _instance;
  static BackgroundAudioService get instance => _instance ??= BackgroundAudioService._();
  
  BackgroundAudioService._();
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  final StreamController<String> _transcriptUpdateController = StreamController<String>.broadcast();
  
  String? _currentVideoId;
  bool _isInitialized = false;
  
  // Stream for transcript updates
  Stream<String> get transcriptUpdateStream => _transcriptUpdateController.stream;
  
  // Initialize the audio service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Listen to audio player state changes
    _audioPlayer.playbackEventStream.listen((event) {
      _broadcastState();
    });
    
    // Listen to position changes for transcript sync
    _audioPlayer.positionStream.listen((position) {
      _transcriptUpdateController.add(position.inSeconds.toString());
    });
    
    _isInitialized = true;
  }
  
  // Set up audio source for YouTube video
  Future<void> setupAudioSource(String videoId, String title) async {
    if (!_isInitialized) await initialize();
    
    _currentVideoId = videoId;
    
    // Create media item
    final mediaItem = MediaItem(
      id: videoId,
      title: title,
      artist: 'English Study',
      duration: Duration.zero,
      artUri: Uri.parse('https://img.youtube.com/vi/$videoId/maxresdefault.jpg'),
    );
    
    // Update media item
    this.mediaItem.add(mediaItem);
    
    // For YouTube audio, we'll use a workaround since direct YouTube audio URLs
    // are not easily accessible. We'll use the YouTube player's audio in background mode.
    // This is a simplified approach - in production, you might want to use
    // youtube_explode_dart for extracting audio URLs.
    
    // Set up a silent audio source as placeholder
    // In a real implementation, you'd extract the actual YouTube audio URL
    await _audioPlayer.setUrl('https://www.soundjay.com/misc/sounds/bell-ringing-05.wav');
    
    _broadcastState();
  }
  
  // Sync with YouTube player position
  Future<void> syncPosition(Duration position) async {
    if (_audioPlayer.duration != null) {
      await _audioPlayer.seek(position);
    }
  }
  
  // Sync with YouTube player state
  Future<void> syncPlaybackState(bool isPlaying) async {
    if (isPlaying) {
      await play();
    } else {
      await pause();
    }
  }
  
  @override
  Future<void> play() async {
    await _audioPlayer.play();
    _broadcastState();
  }
  
  @override
  Future<void> pause() async {
    await _audioPlayer.pause();
    _broadcastState();
  }
  
  @override
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
    _broadcastState();
  }
  
  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
    _broadcastState();
  }
  
  @override
  Future<void> skipToNext() async {
    // Could implement skip to next transcript segment
  }
  
  @override
  Future<void> skipToPrevious() async {
    // Could implement skip to previous transcript segment  
  }
  
  // Broadcast current state
  void _broadcastState() {
    final playing = _audioPlayer.playing;
    final processingState = _audioPlayer.processingState;
    
    PlaybackState state;
    switch (processingState) {
      case ProcessingState.idle:
        state = PlaybackState(
          controls: [MediaControl.play],
          systemActions: {MediaAction.seek},
          androidCompactActionIndices: [0],
          processingState: AudioProcessingState.idle,
          playing: false,
        );
        break;
      case ProcessingState.loading:
        state = PlaybackState(
          controls: [MediaControl.pause],
          systemActions: {MediaAction.seek},
          androidCompactActionIndices: [0],
          processingState: AudioProcessingState.loading,
          playing: false,
        );
        break;
      case ProcessingState.buffering:
        state = PlaybackState(
          controls: [MediaControl.pause],
          systemActions: {MediaAction.seek},
          androidCompactActionIndices: [0],
          processingState: AudioProcessingState.buffering,
          playing: false,
        );
        break;
      case ProcessingState.ready:
        state = PlaybackState(
          controls: playing ? [MediaControl.pause] : [MediaControl.play],
          systemActions: {MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward},
          androidCompactActionIndices: [0],
          processingState: AudioProcessingState.ready,
          playing: playing,
          updatePosition: _audioPlayer.position,
        );
        break;
      case ProcessingState.completed:
        state = PlaybackState(
          controls: [MediaControl.play],
          systemActions: {MediaAction.seek},
          androidCompactActionIndices: [0],
          processingState: AudioProcessingState.completed,
          playing: false,
        );
        break;
    }
    
    playbackState.add(state);
  }
  
  // Get current position
  Duration get currentPosition => _audioPlayer.position;
  
  // Get current playing state
  bool get isPlaying => _audioPlayer.playing;
  
  // Dispose resources
  void dispose() {
    _audioPlayer.dispose();
    _transcriptUpdateController.close();
  }
}