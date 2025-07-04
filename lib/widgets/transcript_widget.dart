import 'package:flutter/material.dart';
import '../models/transcript.dart';
import '../services/transcript_service.dart';

class TranscriptWidget extends StatefulWidget {
  final Transcript transcript;
  final int currentSegmentIndex;
  final Function(double) onSegmentTap;

  const TranscriptWidget({
    Key? key,
    required this.transcript,
    required this.currentSegmentIndex,
    required this.onSegmentTap,
  }) : super(key: key);

  @override
  State<TranscriptWidget> createState() => _TranscriptWidgetState();
}

class _TranscriptWidgetState extends State<TranscriptWidget> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<TranscriptSegment> _filteredSegments = [];
  bool _showTranslations = true;
  bool _showTimestamps = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredSegments = widget.transcript.segments;
  }

  @override
  void didUpdateWidget(TranscriptWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transcript != oldWidget.transcript) {
      _filteredSegments = widget.transcript.segments;
      _searchController.clear();
      _searchQuery = '';
    }
    
    // Auto-scroll to current segment
    if (widget.currentSegmentIndex != oldWidget.currentSegmentIndex &&
        widget.currentSegmentIndex >= 0 &&
        widget.currentSegmentIndex < _filteredSegments.length) {
      _scrollToCurrentSegment();
    }
  }

  void _scrollToCurrentSegment() {
    if (_scrollController.hasClients) {
      final itemHeight = 120.0; // Approximate height of each segment
      final targetOffset = widget.currentSegmentIndex * itemHeight;
      
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredSegments = widget.transcript.segments;
      } else {
        _filteredSegments = widget.transcript.searchSegments(query);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and controls section
        _buildControlsSection(),
        
        // Transcript list
        Expanded(
          child: _filteredSegments.isEmpty
              ? _buildEmptyState()
              : _buildTranscriptList(),
        ),
      ],
    );
  }

  Widget _buildControlsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[700]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '搜索字幕内容...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey[400],
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.grey[400],
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    )
                  : null,
            ),
            onChanged: _performSearch,
          ),
          
          const SizedBox(height: 12),
          
          // Toggle switches
          Row(
            children: [
              Expanded(
                child: _buildToggleSwitch(
                  label: '显示翻译',
                  value: _showTranslations,
                  onChanged: (value) {
                    setState(() {
                      _showTranslations = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildToggleSwitch(
                  label: '显示时间',
                  value: _showTimestamps,
                  onChanged: (value) {
                    setState(() {
                      _showTimestamps = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.deepOrange,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.subtitles_off,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? '没有找到匹配的字幕'
                : '暂无字幕数据',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? '尝试使用不同的关键词搜索'
                : '请加载包含字幕的视频',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _filteredSegments.length,
      itemBuilder: (context, index) {
        final segment = _filteredSegments[index];
        final isCurrentSegment = widget.currentSegmentIndex == index;
        
        return _buildTranscriptItem(segment, isCurrentSegment);
      },
    );
  }

  Widget _buildTranscriptItem(TranscriptSegment segment, bool isCurrentSegment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrentSegment
            ? Colors.deepOrange.withOpacity(0.1)
            : Colors.grey[900]?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentSegment
              ? Colors.deepOrange
              : Colors.grey[700]!,
          width: isCurrentSegment ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onSegmentTap(segment.startTime),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timestamp and controls
                if (_showTimestamps)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${TranscriptService.formatTime(segment.startTime)} - ${TranscriptService.formatTime(segment.endTime)}',
                          style: const TextStyle(
                            color: Colors.deepOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.play_arrow,
                          color: Colors.deepOrange,
                          size: 20,
                        ),
                        onPressed: () => widget.onSegmentTap(segment.startTime),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                
                if (_showTimestamps) const SizedBox(height: 8),
                
                // English text
                Text(
                  segment.text,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: isCurrentSegment ? FontWeight.w600 : FontWeight.normal,
                    height: 1.4,
                  ),
                ),
                
                // Chinese translation
                if (_showTranslations && segment.chineseTranslation != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      segment.chineseTranslation!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                        height: 1.3,
                      ),
                    ),
                  ),
                
                // Keywords
                if (segment.keywords.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: segment.keywords.map((keyword) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            keyword,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                
                // Pronunciation
                if (segment.pronunciation != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
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
                              segment.pronunciation!,
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
                  ),
                
                // Explanation
                if (segment.explanation != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
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
                              segment.explanation!,
                              style: TextStyle(
                                color: Colors.green[300],
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
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