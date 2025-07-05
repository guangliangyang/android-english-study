import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/playlist.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

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
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload playlist when returning from other screens
    print('PlaylistScreen.didChangeDependencies() called');
    _loadPlaylist();
  }

  @override
  void didUpdateWidget(PlaylistScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadPlaylist();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _loadPlaylist() {
    setState(() {
      _playlist = AuthService.playlist;
    });
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
        return item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (item.channelName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }
    
    return items;
  }

  void _onVideoTap(PlaylistItem item) {
    // 始终使用标准导航，不依赖回调函数
    Navigator.pushNamed(context, '/learning', arguments: item.videoId);
  }

  void _playNewVideo() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入YouTube视频链接')),
      );
      return;
    }

    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无效的YouTube链接')),
      );
      return;
    }

    _urlController.clear();
    
    // Show loading message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('正在加载视频并保存到播放列表...'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    Navigator.pushNamed(context, '/learning', arguments: videoId);
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
    final urlController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          '添加新视频',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: '请输入YouTube视频链接',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  _playVideoFromUrl(value.trim());
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                Navigator.of(context).pop();
                _playVideoFromUrl(url);
              }
            },
            child: const Text('播放', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _playVideoFromUrl(String url) {
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
    
    Navigator.pushNamed(context, '/learning', arguments: videoId);
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
            const Text('English Study'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${_playlist.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            if (AuthService.currentUser != null) ...[
              CircleAvatar(
                radius: 16,
                backgroundImage: AuthService.currentUser!.photoUrl != null
                    ? NetworkImage(AuthService.currentUser!.photoUrl!)
                    : null,
                child: AuthService.currentUser!.photoUrl == null
                    ? Text(AuthService.currentUser!.name.isNotEmpty 
                        ? AuthService.currentUser!.name[0].toUpperCase() 
                        : 'U')
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                AuthService.currentUser!.name,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddVideoDialog,
            tooltip: '添加新视频',
          ),
          if (_playlist.isNotEmpty)
            IconButton(
              onPressed: _clearPlaylist,
              icon: const Icon(Icons.clear_all),
              tooltip: '清空播放列表',
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'signout':
                  _signOut();
                  break;
              }
            },
            itemBuilder: (context) => [
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
          // 新视频输入区域
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '播放新视频',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '列表: ${_playlist.length} 个视频',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    // DEBUG INFO
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DEBUG: _playlist.length = ${_playlist.length}',
                            style: const TextStyle(color: Colors.red, fontSize: 10),
                          ),
                          Text(
                            'DEBUG: AuthService.playlist.length = ${AuthService.playlist.length}',
                            style: const TextStyle(color: Colors.red, fontSize: 10),
                          ),
                          Text(
                            'DEBUG: currentUser = ${AuthService.currentUser?.name ?? "null"}',
                            style: const TextStyle(color: Colors.red, fontSize: 10),
                          ),
                          Text(
                            'DEBUG: currentUser.playlist.length = ${AuthService.currentUser?.playlist.length ?? "null"}',
                            style: const TextStyle(color: Colors.red, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: '粘贴YouTube视频链接...',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                        ),
                        onSubmitted: (_) => _playNewVideo(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _playNewVideo,
                      child: const Text('播放'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 分隔线
          if (_playlist.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 1,
              color: Colors.grey[800],
            ),
          
          // 分类筛选器
          if (_playlist.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip('全部'),
                    ..._playlist.categories.map((category) => _buildCategoryChip(category)),
                  ],
                ),
              ),
            ),
          
          // 搜索栏
          if (_playlist.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '搜索视频标题或频道名...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          icon: const Icon(Icons.clear, color: Colors.grey),
                        )
                      : null,
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
      return const Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.playlist_play, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                '播放列表为空',
                style: TextStyle(color: Colors.grey, fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                '在上方输入YouTube链接开始学习',
                style: TextStyle(color: Colors.grey, fontSize: 14),
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

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
        backgroundColor: Colors.grey[800],
        selectedColor: Colors.blue.withOpacity(0.3),
        labelStyle: TextStyle(
          color: isSelected ? Colors.blue : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey[600]!,
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