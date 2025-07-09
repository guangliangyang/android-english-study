# English Study - YouTube English Learning App

A Flutter application for learning English through YouTube videos with interactive transcripts, real-time synchronization, and comprehensive learning features.

## Features

### 🎥 Video Learning
- **YouTube Integration**: Load and play any YouTube video
- **Transcript Sync**: Real-time transcript synchronization with video playback
- **Click-to-Seek**: Click on any transcript segment to jump to that time
- **Loop Mode**: Repeat videos for intensive learning
- **Swipe Controls**: Hide/show video player with swipe gestures

### 📱 User Experience
- **Dark Theme**: Eye-friendly dark theme optimized for learning
- **Google Sign-In**: Secure authentication with Google accounts
- **Progress Tracking**: Keep track of learning progress and statistics
- **Responsive Design**: Works on phones and tablets

### 🎯 Learning Features
- **Chinese Translations**: Built-in Chinese translations for better comprehension
- **Keyword Highlighting**: Important words and phrases highlighted
- **Search Functionality**: Search through transcript content
- **Pronunciation Guide**: IPA pronunciation for difficult words
- **Speed Control**: Adjustable playback speed (0.5x to 2.0x)

### 📊 Analytics & Progress
- **Study Time Tracking**: Monitor daily and total study time
- **Video Progress**: Resume videos from where you left off
- **Learning Statistics**: Comprehensive learning analytics
- **Streak Tracking**: Maintain learning streaks

## Screenshots

*Add screenshots here when available*

## Installation

### Prerequisites
- Flutter SDK 3.2.0 or higher
- Dart SDK 2.18.0 or higher
- Android Studio or VS Code
- OpenAI API Key (for AI transcript generation)

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/android-english-study.git
   cd android-english-study
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables**
   ```bash
   # Copy the environment template
   cp .env.example .env
   ```
   
   Edit the `.env` file and add your API keys:
   ```env
   # Required: OpenAI API Key for AI transcript generation
   OPENAI_API_KEY=sk-your_actual_openai_api_key_here
   
   # Optional: YouTube API Key (currently using internal API)
   YOUTUBE_API_KEY=your_youtube_api_key_here
   ```

4. **Get OpenAI API Key**
   - Visit [OpenAI API Keys](https://platform.openai.com/api-keys)
   - Create a new API key
   - Copy the key (starts with "sk-")
   - Paste it in your `.env` file

5. **Run the app**
   ```bash
   flutter run
   ```

### Environment Configuration

The app uses environment variables for secure API key management. The following variables are supported:

#### Required Variables
- `OPENAI_API_KEY`: Your OpenAI API key for AI transcript generation

#### Optional Variables
- `YOUTUBE_API_KEY`: YouTube Data API key (fallback option)
- `OPENAI_MODEL`: AI model to use (default: gpt-3.5-turbo)
- `AI_TRANSCRIPT_TIMEOUT`: API timeout in milliseconds (default: 30000)
- `AI_TRANSCRIPT_TEMPERATURE`: AI response creativity (default: 0.1)
- `ENVIRONMENT`: Application environment (development/production)

#### Security Notes
- Never commit your `.env` file to version control
- The `.env` file is already included in `.gitignore`
- Use `.env.example` as a template for new environments
- Keep your API keys secure and rotate them regularly

## Project Structure

```
lib/
├── models/
│   ├── transcript.dart      # Transcript data models
│   └── user.dart           # User and preferences models
├── services/
│   ├── auth_service.dart   # Authentication service
│   └── transcript_service.dart # Transcript fetching service
├── screens/
│   ├── auth_screen.dart    # Login/authentication screen
│   └── youtube_learning_screen.dart # Main learning screen
├── widgets/
│   ├── transcript_widget.dart # Transcript display widget
│   └── video_controls_widget.dart # Video controls widget
└── main.dart              # App entry point
```

## Configuration

### Android Configuration
- **Target SDK**: 33
- **Min SDK**: 21
- **Permissions**: Internet, Network State, Wake Lock
- **Deep Links**: YouTube URL handling

### iOS Configuration
- **Target iOS**: 11.0+
- **Permissions**: Network access
- **Background Modes**: Audio playback
- **URL Schemes**: YouTube URL handling

## API Keys Setup

### YouTube Data API
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Enable YouTube Data API v3
3. Create credentials (API Key)
4. Replace in `lib/services/transcript_service.dart`:
   ```dart
   static const String _apiKey = 'YOUR_YOUTUBE_API_KEY';
   ```

### Google Sign-In
1. Follow [Google Sign-In setup guide](https://developers.google.com/identity/sign-in/android/start-integrating)
2. Download configuration files
3. Place `google-services.json` in `android/app/`
4. Place `GoogleService-Info.plist` in `ios/Runner/`

## Dependencies

### Core Dependencies
- `flutter`: Flutter framework
- `youtube_player_flutter`: YouTube video player
- `google_sign_in`: Google authentication
- `http`: HTTP requests
- `xml`: XML parsing for transcripts

### UI Dependencies
- `cupertino_icons`: iOS-style icons
- `provider`: State management
- `url_launcher`: URL handling

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Flutter team for the amazing framework
- YouTube for providing the video platform
- Google for authentication and API services
- All contributors and testers

## Support

For support, email support@englishstudyapp.com or create an issue on GitHub.

## Roadmap

- [ ] Offline transcript storage
- [ ] Voice recognition for pronunciation practice
- [ ] Custom vocabulary lists
- [ ] Social features (sharing progress)
- [ ] Advanced analytics dashboard
- [ ] Multi-language support
- [ ] Tablet-optimized UI
- [ ] Widget support for quick access
- [ ] Develop a backend service and now plan the backend product. 1. The backend provides user registration, login, and recharge. It is recommended to use WeChat joint login. 2. The backend needs to store video categories, video names, videos, video subtitles, and video subtitle explanations. It is recommended to use s3+ xml storage. 3. Use aws lambda to provide access services. 4. Need to register a domain name

---

Made with ❤️ for English learners worldwide