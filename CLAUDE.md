# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter application called "English Study" (英语学习应用) that helps users learn English through YouTube videos with interactive transcripts. The app is designed for Chinese speakers learning English, providing real-time transcript synchronization, vocabulary lookup with Chinese translations, and various learning features.

### Core Learning Features
- **YouTube Video Integration**: Play any YouTube video for English learning
- **Real-time Transcript Sync**: Synchronized subtitles with video playback, current segment highlighted
- **AI Enhanced Transcripts**: AI-generated transcripts with Chinese translations, keywords, pronunciation, and explanations
- **Click-to-Jump**: Click on transcript segments to jump to specific video timestamps
- **Loop Mode (复读模式)**: Repeat specific segments for intensive practice
- **Vocabulary Lookup (生词查询)**: Double-click words to see definitions, pronunciation, and Chinese translations
- **Background Audio**: Continue learning with screen off for listening practice
- **Font Size Control**: Adjustable transcript font size for comfortable reading
- **Transcript Mode Toggle**: Switch between original and AI-enhanced transcripts seamlessly

### Key Architecture Components

- **Frontend**: Flutter mobile application with dark theme
- **Services**: Multiple service classes for different functionalities
- **Models**: Data models for transcripts, playlists, and user data
- **Widgets**: Custom UI components for video controls and transcripts
- **Screens**: Main UI screens for different app sections

## Essential Development Commands

### Build & Run
```bash
# Install dependencies
flutter pub get

# Run the app (development)
flutter run

# Build for Android
flutter build apk

# Build for iOS
flutter build ios

# Run setup script (configures environment)
./setup.sh
```

### Code Quality
```bash
# Static analysis
flutter analyze

# Format code
flutter format .

# Run tests
flutter test
```

## Project Structure

```
lib/
├── main.dart                    # App entry point with routing
├── models/                      # Data models
│   ├── transcript.dart         # Transcript and segment models
│   ├── playlist.dart           # Playlist data structures
│   └── user.dart               # User preferences and data
├── services/                    # Business logic services
│   ├── auth_service.dart       # Authentication & user management
│   ├── transcript_service.dart # YouTube transcript fetching
│   ├── ai_transcript_service.dart # AI-enhanced transcripts with OpenAI
│   ├── background_audio_service.dart # Background audio playback
│   ├── dictionary_service.dart # Word definitions and lookup
│   ├── video_metadata_service.dart # Video title and metadata
│   ├── vocabulary_service.dart # Vocabulary management
│   └── environment_config.dart # Environment variable management
├── screens/                     # UI screens
│   ├── youtube_learning_screen.dart # Main learning interface
│   ├── playlist_screen.dart    # Video playlist management
│   ├── vocabulary_screen.dart  # Saved vocabulary viewer
│   └── auth_screen.dart        # Authentication flow
└── widgets/                     # Reusable UI components
    ├── transcript_widget.dart  # Transcript display
    ├── video_controls_widget.dart # Video playback controls
    └── word_definition_dialog.dart # Vocabulary popup
```

## Key Technical Details

### Video Player Integration
- Uses `youtube_player_flutter` package for YouTube video playback
- Implements custom transcript synchronization with video position
- Supports background audio playback via `audio_service`

### Transcript Processing
- Fetches transcripts using YouTube's internal InnerTube API
- Parses XML format transcripts (srv3 format)
- Implements intelligent text cleaning and HTML entity decoding
- Supports real-time transcript highlighting during playback

### AI Transcript Enhancement
- Uses OpenAI API to enhance original transcripts with Chinese translations
- Extracts keywords with definitions for vocabulary learning
- Provides pronunciation guides and grammar explanations
- Implements two-tier caching: original transcripts → AI enhanced transcripts
- Secure API key management via environment variables
- **Fail-fast design**: No retry mechanism, immediate error reporting for quick debugging
- **Current Limitation**: Processing limited to first 20 transcript segments for performance optimization

### State Management
- Uses provider pattern for app-wide state management
- Implements shared preferences for user settings persistence
- Manages complex video playback states and transcript synchronization

### Authentication
- Converted from Google Sign-In to single-user application
- Maintains user preferences and learning progress locally
- Supports playlist management and vocabulary collection

## Configuration Requirements

### API Keys
- OpenAI API key required for AI transcript generation (configured in .env file)
- YouTube Data API key required in `lib/services/transcript_service.dart`
- Replace placeholder `YOUR_YOUTUBE_API_KEY` with actual key

### Platform Configuration
- **Android**: Min SDK 21, Target SDK 33
- **iOS**: Target iOS 11.0+
- Permissions configured for network access and background audio

## Development Notes

### Linting Configuration
- Uses `flutter_lints` with additional custom rules in `analysis_options.yaml`
- Enforces strict null safety and type checking
- Excludes generated files from analysis

### Testing
- Uses `flutter_test` framework
- Run tests with `flutter test`
- No specific test runner script configured

### Background Services
- Implements `AudioService` for background audio playback
- Supports transcript synchronization during background playback
- Handles wake lock for continuous playback

## Common Development Patterns

### Service Layer
Services follow a consistent pattern:
- Static methods for main functionality
- Proper error handling with null returns
- Logging with developer.log for debugging

### UI Components
- Consistent Material Design dark theme
- Responsive layout supporting different screen sizes
- Custom context menus for vocabulary lookup

### State Updates
- Uses setState for local component state
- Implements proper dispose patterns for controllers
- Careful handling of async operations in UI lifecycle

## App Usage Patterns & User Workflows

### Primary User Flow
1. **Video Selection**: Users paste YouTube URLs or select from playlist
2. **Learning Session**: Watch video with synchronized transcript
3. **Vocabulary Learning**: Double-click words for definitions and save to vocabulary book
4. **Review**: Practice with loop mode and background audio

### Common Development Scenarios

#### Adding New Learning Features
- New features typically involve transcript interaction or video control
- Follow the pattern in `youtube_learning_screen.dart` for UI state management
- Use services for business logic, widgets for reusable components

#### Transcript Processing Issues
- Most issues are in `transcript_service.dart` with YouTube API changes
- XML parsing logic handles different transcript formats
- Error handling returns null, UI shows fallback message

#### Video Player Integration
- YouTube player state changes trigger transcript updates
- Background audio service syncs with video position
- Careful controller disposal needed to prevent memory leaks

#### Vocabulary System
- Word selection uses custom context menus
- Dictionary service provides definitions and pronunciation
- Vocabulary service manages saved words and study progress

### Key User Experience Considerations
- **Chinese Users**: All UI text and error messages support Chinese
- **Learning Focus**: Minimize distractions, maximize content visibility
- **Mobile Optimization**: Touch-friendly controls, swipe gestures
- **Offline Capability**: Background audio works without active video
- **Study Habits**: Support for repeated viewing and note-taking

### Common Debugging Areas
- **Transcript Sync**: Check video position updates and segment highlighting
- **API Issues**: YouTube transcript fetching may fail due to API changes
- **Audio Service**: Background playback sync with video position
- **State Management**: Complex interaction between video player and transcript UI