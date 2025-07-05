import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final User? user = await AuthService.signInWithGoogle();
      if (user != null && mounted) {
        Navigator.pushReplacementNamed(context, '/playlist');
      } else {
        _showErrorDialog('登录失败', '请检查网络连接后重试');
      }
    } catch (e) {
      _showErrorDialog('登录错误', '发生未知错误，请稍后重试');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A1A),
              Color(0xFF2D2D2D),
              Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildContent(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 
                      MediaQuery.of(context).padding.top - 
                      MediaQuery.of(context).padding.bottom - 48, // padding
        ),
        child: IntrinsicHeight(
          child: Column(
            children: [
              const SizedBox(height: 20), // 顶部间距
              
              // Logo and title section
              _buildHeader(),
              const SizedBox(height: 30), // 减少间距
              
              // Features section
              _buildFeaturesList(),
              
              const SizedBox(height: 30), // 确保按钮和特性之间有固定间距
              
              // Sign in button - 确保总是可见
              _buildSignInButton(),
              const SizedBox(height: 16),
              
              // Footer
              _buildFooter(),
              const SizedBox(height: 20), // 底部间距
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100, // 缩小Logo
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.deepOrange,
                Colors.deepOrangeAccent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.deepOrange.withOpacity(0.3),
                blurRadius: 15, // 减少阴影
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.school,
            size: 50, // 缩小图标
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20), // 减少间距
        const Text(
          'English Study',
          style: TextStyle(
            fontSize: 28, // 稍微缩小标题
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6), // 减少间距
        Text(
          'YouTube 英语学习助手',
          style: TextStyle(
            fontSize: 15, // 稍微缩小副标题
            color: Colors.grey[300],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      {
        'icon': Icons.play_circle_fill,
        'title': 'YouTube 视频播放',
        'subtitle': '支持任意 YouTube 视频学习',
      },
      {
        'icon': Icons.subtitles,
        'title': '智能字幕同步',
        'subtitle': '实时字幕显示与点击跳转',
      },
      {
        'icon': Icons.translate,
        'title': '中英文对照',
        'subtitle': '即时翻译帮助理解',
      },
      {
        'icon': Icons.loop,
        'title': '循环播放',
        'subtitle': '重复练习巩固学习',
      },
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0), // 减少间距
          child: Container(
            padding: const EdgeInsets.all(12), // 减少内边距
            decoration: BoxDecoration(
              color: Colors.grey[900]?.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[700]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, // 缩小图标容器
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: Colors.deepOrange,
                    size: 20, // 缩小图标
                  ),
                ),
                const SizedBox(width: 12), // 减少间距
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature['title'] as String,
                        style: const TextStyle(
                          fontSize: 15, // 稍微缩小字体
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2), // 减少间距
                      Text(
                        feature['subtitle'] as String,
                        style: TextStyle(
                          fontSize: 13, // 缩小字体
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSignInButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.deepOrange,
            Colors.deepOrangeAccent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleGoogleSignIn,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Image.asset(
                    'assets/images/google_logo.png',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.login,
                        color: Colors.white,
                        size: 24,
                      );
                    },
                  ),
                const SizedBox(width: 12),
                Text(
                  _isLoading ? '登录中...' : '使用 Google 账号登录',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          '登录即表示您同意我们的服务条款和隐私政策',
          style: TextStyle(
            fontSize: 11, // 缩小字体
            color: Colors.grey[500],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8), // 减少间距
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                _showInfoDialog('服务条款', '这里是服务条款的详细内容...');
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 减少按钮内边距
                minimumSize: Size.zero,
              ),
              child: Text(
                '服务条款',
                style: TextStyle(
                  fontSize: 11, // 缩小字体
                  color: Colors.grey[400],
                ),
              ),
            ),
            Text(
              ' | ',
              style: TextStyle(
                fontSize: 11, // 缩小字体
                color: Colors.grey[500],
              ),
            ),
            TextButton(
              onPressed: () {
                _showInfoDialog('隐私政策', '这里是隐私政策的详细内容...');
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 减少按钮内边距
                minimumSize: Size.zero,
              ),
              child: Text(
                '隐私政策',
                style: TextStyle(
                  fontSize: 11, // 缩小字体
                  color: Colors.grey[400],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}