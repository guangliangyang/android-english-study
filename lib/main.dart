import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/auth_screen.dart';
import 'screens/youtube_learning_screen.dart';
import 'screens/playlist_screen.dart';
import 'screens/vocabulary_screen.dart';
import 'services/auth_service.dart';
import 'services/environment_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print('Environment variables loaded successfully');
    
    // Print configuration summary for debugging
    EnvironmentConfig.printConfigSummary();
    
    // Validate configuration (non-blocking for development)
    final warnings = EnvironmentConfig.validateConfigurationSafe();
    if (warnings.isNotEmpty && EnvironmentConfig.isProduction) {
      // In production, we want to ensure proper configuration
      throw Exception('Production environment requires proper configuration');
    }
    
  } catch (e) {
    print('Warning: Could not load .env file: $e');
    print('Please copy .env.example to .env and configure your API keys');
    print('');
    print(EnvironmentConfig.getSetupInstructions());
  }
  
  runApp(const EnglishStudyApp());
}

class EnglishStudyApp extends StatelessWidget {
  const EnglishStudyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English Study',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
      ),
      routes: {
        '/': (context) => const SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/playlist': (context) => const PlaylistScreen(),
        '/learning': (context) {
          final videoId = ModalRoute.of(context)?.settings.arguments as String?;
          return YoutubeLearningScreen(videoId: videoId);
        },
        '/vocabulary': (context) => const VocabularyScreen(),
      },
      initialRoute: '/',
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final result = await AuthService.initialize();
    
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      // Always navigate to playlist since it's a single-user app
      Navigator.pushReplacementNamed(context, '/playlist');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepOrange,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school,
              size: 100,
              color: Colors.white,
            ),
            SizedBox(height: 24),
            Text(
              'English Study',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'YouTube 英语学习助手',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}