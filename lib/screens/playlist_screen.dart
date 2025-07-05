import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/playlist.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import 'youtube_learning_screen.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({Key? key}) : super(key: key);

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  late Playlist _playlist;
  String _searchQuery = '';
  String _selectedCategory = '全部';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _emptyUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
    // Check clipboard for YouTube links after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkClipboardForYouTubeLink();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Navigation now uses await pattern for reliable refresh
    print('PlaylistScreen.didChangeDependencies() called');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _emptyUrlController.dispose();
    super.dispose();
  }

  void _loadPlaylist() {
    setState(() {
      _playlist = AuthService.playlist;
    });
  }

  Future<void> _refreshPlaylist() async {
    await AuthService.refreshPlaylist();
    setState(() {
      _playlist = AuthService.playlist;
    });
  }

  Future<void> _checkClipboardForYouTubeLink() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final clipboardText = clipboardData?.text?.trim();
      
      if (clipboardText != null && clipboardText.isNotEmpty) {
        final videoId = YoutubePlayer.convertUrlToId(clipboardText);
        
        if (videoId != null && mounted) {
          // Check if this video is not already in the playlist
          if (!AuthService.isVideoInPlaylist(videoId)) {
            _showClipboardYouTubePrompt(clipboardText, videoId);
          }
        }
      }
    } catch (e) {
      // Silently handle clipboard errors (permissions, etc.)
      print('Clipboard check error: $e');
    }
  }

  void _showClipboardYouTubePrompt(String url, String videoId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.content_paste, color: Colors.blue, size: 24),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                '检测到YouTube链接',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '检测到你刚复制了一个YouTube视频链接，是否要用它来学习？',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800]?.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.link, color: Colors.grey[400], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      url.length > 50 ? '${url.substring(0, 50)}...' : url,
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '取消',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              // Clear clipboard to avoid showing the prompt again
              await Clipboard.setData(const ClipboardData(text: ''));
              // Navigate to learning screen
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => YoutubeLearningScreen(videoId: videoId),
                ),
              );
              // Refresh playlist when returning
              await _refreshPlaylist();
            },
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('是'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  List<PlaylistItem> get _filteredItems {
    var items = _playlist.items;
    
    // 按分类筛选
    if (_selectedCategory != '全部') {
      items = items.where((item) => item.category == _selectedCategory).toList();
    }
    
    // 按搜索关键词筛选
    if (_searchQuery.isNotEmpty) {
      items = items.where((item) {
        final query = _searchQuery.toLowerCase();
        return item.title.toLowerCase().contains(query) ||
               (item.channelName?.toLowerCase().contains(query) ?? false) ||
               item.category.toLowerCase().contains(query);
      }).toList();
    }
    
    return items;
  }

  void _onVideoTap(PlaylistItem item) async {
    // 使用 Navigator.push 并等待返回，然后刷新播放列表
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => YoutubeLearningScreen(videoId: item.videoId),
      ),
    );
    // 返回时刷新播放列表
    await _refreshPlaylist();
  }

  void _playVideoFromEmptyState() async {
    final url = _emptyUrlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入YouTube视频链接'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('无效的YouTube链接'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _emptyUrlController.clear();
    
    // 使用 Navigator.push 并等待返回，然后刷新播放列表
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => YoutubeLearningScreen(videoId: videoId),
      ),
    );
    // 返回时刷新播放列表
    await _refreshPlaylist();
  }

  void _signOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await AuthService.signOut();
              if (mounted) {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/auth');
              }
            },
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  void _removeVideo(String videoId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除视频'),
        content: const Text('确定要从播放列表中移除这个视频吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              AuthService.removeFromPlaylist(videoId);
              _loadPlaylist();
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('视频已移除 (剩余: ${_playlist.length})'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('移除'),
          ),
        ],
      ),
    );
  }

  void _clearPlaylist() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空播放列表'),
        content: const Text('确定要清空整个播放列表吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final count = _playlist.length;
              AuthService.clearPlaylist();
              _loadPlaylist();
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已清空播放列表 ($count 个视频)'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog(PlaylistItem item) {
    final TextEditingController categoryController = TextEditingController();
    final existingCategories = _playlist.categories;
    final predefinedCategories = ['学习', '娱乐', '新闻', '音乐', '科技', '旅行', '美食'];
    
    // 合并预定义分类和现有分类，去重
    final allCategories = <String>{...predefinedCategories, ...existingCategories}.toList()
      ..sort();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择分类'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('当前分类: ${item.category}'),
              const SizedBox(height: 16),
              const Text('选择现有分类:'),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: allCategories.length,
                  itemBuilder: (context, index) {
                    final category = allCategories[index];
                    return ListTile(
                      title: Text(category),
                      leading: Radio<String>(
                        value: category,
                        groupValue: item.category,
                        onChanged: (value) {
                          if (value != null) {
                            AuthService.updateVideoCategory(item.videoId, value);
                            _loadPlaylist();
                            Navigator.of(context).pop();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('分类已更改为: $value'),
                                duration: const Duration(seconds: 1),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                      onTap: () {
                        AuthService.updateVideoCategory(item.videoId, category);
                        _loadPlaylist();
                        Navigator.of(context).pop();
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('分类已更改为: $category'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: '或创建新分类',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    AuthService.updateVideoCategory(item.videoId, value.trim());
                    _loadPlaylist();
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final newCategory = categoryController.text.trim();
              if (newCategory.isNotEmpty) {
                AuthService.updateVideoCategory(item.videoId, newCategory);
                _loadPlaylist();
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('新分类已创建: $newCategory'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.blue,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showAddVideoDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildAddVideoBottomSheet(),
    );
  }

  Widget _buildAddVideoBottomSheet() {
    final urlController = TextEditingController();
    
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 32,
              right: 32,
              bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Icon and Title
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[800]?.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.add_circle_outline, size: 48, color: Colors.blue),
                      SizedBox(height: 12),
                      Text(
                        '添加新视频',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '输入YouTube视频链接开始学习',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // URL Input
                TextField(
                  controller: urlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '粘贴YouTube视频链接...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.link, color: Colors.grey),
                    suffixIcon: urlController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              urlController.clear();
                              setModalState(() {});
                            },
                            icon: const Icon(Icons.clear, color: Colors.grey),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[800]?.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    setModalState(() {});
                  },
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      Navigator.of(context).pop();
                      _playVideoFromUrl(value.trim());
                    }
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[600]!),
                          ),
                        ),
                        child: const Text(
                          '取消',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: urlController.text.trim().isNotEmpty
                            ? () {
                                Navigator.of(context).pop();
                                _playVideoFromUrl(urlController.text.trim());
                              }
                            : null,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('开始学习'),
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
                
                const SizedBox(height: 16),
                
                // Tips
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.blue, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '支持YouTube视频链接，自动提取字幕进行英语学习',
                          style: TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _playVideoFromUrl(String url) async {
    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('无效的YouTube链接'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('正在加载视频并保存到播放列表...'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // 使用 Navigator.push 并等待返回，然后刷新播放列表
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => YoutubeLearningScreen(videoId: videoId),
      ),
    );
    // 返回时刷新播放列表
    await _refreshPlaylist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            // Category dropdown
            DropdownButton<String>(
              value: _selectedCategory,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white, fontSize: 16),
              underline: Container(),
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_filteredItems.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: Colors.white),
                ],
              ),
              items: [
                '全部',
                ..._playlist.categories,
              ].map((category) => DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              )).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            const Spacer(),
          ],
        ),
        actions: [
          if (AuthService.currentUser != null)
            PopupMenuButton<String>(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: AuthService.currentUser!.photoUrl != null
                          ? NetworkImage(AuthService.currentUser!.photoUrl!)
                          : null,
                      child: AuthService.currentUser!.photoUrl == null
                          ? Text(
                              AuthService.currentUser!.name.isNotEmpty 
                                  ? AuthService.currentUser!.name[0].toUpperCase() 
                                  : 'U',
                              style: const TextStyle(fontSize: 10),
                            )
                          : null,
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.more_vert, size: 16),
                  ],
                ),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'clear':
                    _clearPlaylist();
                    break;
                  case 'signout':
                    _signOut();
                    break;
                }
              },
              itemBuilder: (context) => [
                if (_playlist.isNotEmpty)
                  const PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('清空播放列表'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'signout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('退出登录'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          if (_playlist.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '搜索视频标题、频道名或分类...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          icon: const Icon(Icons.clear, color: Colors.grey),
                        ),
                      IconButton(
                        onPressed: _showAddVideoDialog,
                        icon: const Icon(Icons.add, color: Colors.blue),
                        tooltip: '添加新视频',
                      ),
                    ],
                  ),
                  border: const OutlineInputBorder(),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

          // 播放列表统计信息
          if (_playlist.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '播放历史 (${_filteredItems.length}/${_playlist.length})',
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                  Text(
                    '总时长: ${_playlist.formattedTotalDuration}',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),

          // 播放列表内容
          Expanded(
            child: _buildPlaylistContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistContent() {
    if (_playlist.isEmpty) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon and Title
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[800]?.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.video_library, size: 64, color: Colors.blue),
                    SizedBox(height: 16),
                    Text(
                      '开始你的英语学习之旅',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '添加第一个YouTube视频到播放列表',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // URL Input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _emptyUrlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '粘贴YouTube视频链接...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.link, color: Colors.grey),
                    suffixIcon: _emptyUrlController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _emptyUrlController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear, color: Colors.grey),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[800]?.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      _playVideoFromEmptyState();
                    }
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Play Button
              SizedBox(
                width: double.infinity,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: _emptyUrlController.text.trim().isNotEmpty
                        ? _playVideoFromEmptyState
                        : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('开始学习'),
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
              ),
              
              const SizedBox(height: 24),
              
              // Tips
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '提示：支持YouTube视频链接，自动提取字幕进行英语学习',
                        style: TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filteredItems = _filteredItems;
    
    if (filteredItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '没有找到匹配的视频',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildPlaylistItem(item, index);
      },
    );
  }

  Widget _buildPlaylistItem(PlaylistItem item, int index) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _onVideoTap(item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 缩略图
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.thumbnail ?? 'https://img.youtube.com/vi/${item.videoId}/mqdefault.jpg',
                  width: 120,
                  height: 68,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 120,
                      height: 68,
                      color: Colors.grey[800],
                      child: const Icon(Icons.play_circle_outline, color: Colors.white),
                    );
                  },
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 视频信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    if (item.channelName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.channelName!,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        if (item.duration != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.formattedDuration,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        
                        const SizedBox(width: 8),
                        
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        
                        const Spacer(),
                        
                        Text(
                          _formatDate(item.addedAt),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 操作按钮
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                color: Colors.grey[800],
                onSelected: (value) {
                  switch (value) {
                    case 'remove':
                      _removeVideo(item.videoId);
                      break;
                    case 'change_category':
                      _showCategoryDialog(item);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'change_category',
                    child: Row(
                      children: [
                        Icon(Icons.label, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('更改分类', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('移除', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
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
    
    if (difference.inDays == 0) {
      return '今天';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else if (difference.inDays < 30) {
      return '${difference.inDays ~/ 7}周前';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}