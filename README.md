# English Study Android App

An Android application for English language learning that converts text to high-quality speech using Google Cloud Text-to-Speech API.

## Features

- **Text Input**: Upload or type English text for study
- **Professional TTS**: Uses Google Cloud Text-to-Speech API for high-quality audio generation
- **Text-Audio Pairs**: Saves text and corresponding audio files as study pairs
- **Playback Controls**: Adjustable playback speed (0.5x to 2.5x)
- **Search Functionality**: Search through saved text entries
- **Modern UI**: Material Design 3 interface inspired by reading apps

## Requirements

- Android 7.0 (API level 24) or higher
- Google Cloud Text-to-Speech API credentials
- Internet connection for audio generation

## Setup

1. **Google Cloud Setup**:
   - Create a Google Cloud Project
   - Enable the Text-to-Speech API
   - Create service account credentials
   - Download the JSON credentials file

2. **Android Setup**:
   - Place the credentials JSON file in the app's assets folder
   - Set the `GOOGLE_APPLICATION_CREDENTIALS` environment variable

3. **Build**:
   ```bash
   ./gradlew assembleDebug
   ```

## Architecture

- **MVVM Pattern**: Uses ViewModel and LiveData for UI state management
- **Room Database**: Local storage for text entries and metadata
- **Kotlin Coroutines**: Asynchronous operations for TTS and database
- **Material Design 3**: Modern UI components and theming

## Key Components

- `TTSService`: Handles Google Cloud Text-to-Speech integration
- `AudioPlayer`: Manages audio playback with speed control
- `TextEntry`: Data model for text-audio pairs
- `AppDatabase`: Room database for local storage

## Usage

1. Open the app and tap the "+" button to add new text
2. Enter a title and paste/type your English text
3. Tap "Generate Audio" to create the speech file
4. Use playback controls to listen at different speeds
5. All entries are saved locally for future study

## API Usage

The app uses Google Cloud Text-to-Speech with the following configuration:
- Voice: `en-US-Studio-O` (high-quality female voice)
- Format: MP3
- Language: English (US)

## Permissions

- `INTERNET`: Required for Google Cloud API calls
- `RECORD_AUDIO`: For potential future voice features
- `WRITE_EXTERNAL_STORAGE`: For audio file storage