import 'dart:developer' as developer;

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration validator and helper
class EnvironmentConfig {
  static const String _tag = 'EnvironmentConfig';

  /// Check if running in production mode
  static bool get isProduction => dotenv.env['ENVIRONMENT'] == 'production';

  /// Check if debug mode is enabled
  static bool get isDebugMode => dotenv.env['DEBUG_MODE'] == 'true';

  /// Get current AI provider
  static String get aiProvider => dotenv.env['AI_PROVIDER'] ?? _detectAIProvider();

  /// Auto-detect AI provider based on model name
  static String _detectAIProvider() {
    // Check if GEMINI_MODEL is set
    final geminiModel = dotenv.env['GEMINI_MODEL'] ?? '';
    if (geminiModel.isNotEmpty) {
      return 'gemini';
    }
    
    // Check if OPENAI_MODEL suggests Gemini
    final openaiModel = dotenv.env['OPENAI_MODEL'] ?? 'gpt-3.5-turbo';
    if (openaiModel.startsWith('gemini')) {
      return 'gemini';
    }
    
    return 'openai';
  }

  /// Validate all required environment variables
  static void validateConfiguration() {
    final provider = aiProvider;
    final required = <String>[];
    
    // Add required keys based on provider
    if (provider == 'gemini') {
      required.add('GEMINI_API_KEY');
    } else {
      required.add('OPENAI_API_KEY');
    }
    
    final missing = <String>[];

    for (final key in required) {
      final value = dotenv.env[key] ?? '';
      if (value.isEmpty) {
        missing.add(key);
      }
    }

    if (missing.isNotEmpty) {
      final error = 'Missing required environment variables: ${missing.join(', ')}';
      developer.log(error, name: _tag, level: 1000); // Error level
      throw Exception(error);
    }

    // Validate API key format based on provider
    if (provider == 'gemini') {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (!apiKey.startsWith('AIza')) {
        final error = 'Invalid Gemini API key format. Key should start with "AIza"';
        developer.log(error, name: _tag, level: 1000);
        throw Exception(error);
      }
    } else {
      final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
      if (!apiKey.startsWith('sk-')) {
        final error = 'Invalid OpenAI API key format. Key should start with "sk-"';
        developer.log(error, name: _tag, level: 1000);
        throw Exception(error);
      }
    }

    developer.log('Environment configuration validated successfully for provider: $provider', name: _tag);
  }

  /// Validate configuration and return warnings instead of throwing
  static List<String> validateConfigurationSafe() {
    final warnings = <String>[];

    try {
      validateConfiguration();
    } catch (e) {
      warnings.add(e.toString());
    }

    // Additional warnings for optional configurations
    final optionalChecks = {
      'YOUTUBE_API_KEY': 'YouTube API key not configured (using internal API)',
      'AI_TRANSCRIPT_TIMEOUT': 'AI transcript timeout not configured (using default: 30000ms)',
      'AI_TRANSCRIPT_MAX_RETRIES': 'AI transcript max retries not configured (using default: 3)',
      'AI_PROVIDER': 'AI provider not configured (auto-detecting based on model)',
    };

    for (final entry in optionalChecks.entries) {
      final value = dotenv.env[entry.key] ?? '';
      if (value.isEmpty) {
        warnings.add(entry.value);
      }
    }

    return warnings;
  }

  /// Get configuration summary for debugging
  static Map<String, String> getConfigSummary() {
    final provider = aiProvider;
    return {
      'Environment': dotenv.env['ENVIRONMENT'] ?? 'development',
      'Debug Mode': isDebugMode ? 'Enabled' : 'Disabled',
      'AI Provider': provider,
      'OpenAI API': _isApiKeyConfigured('OPENAI_API_KEY') ? 'Configured' : 'Not Configured',
      'Gemini API': _isApiKeyConfigured('GEMINI_API_KEY') ? 'Configured' : 'Not Configured',
      'OpenAI Model': dotenv.env['OPENAI_MODEL'] ?? 'gpt-3.5-turbo',
      'Gemini Model': dotenv.env['GEMINI_MODEL'] ?? 'Not Set',
      'YouTube API': _isApiKeyConfigured('YOUTUBE_API_KEY') ? 'Configured' : 'Not Configured',
      'AI Timeout': '${dotenv.env['AI_TRANSCRIPT_TIMEOUT'] ?? '30000'}ms',
      'AI Max Retries': dotenv.env['AI_TRANSCRIPT_MAX_RETRIES'] ?? '3',
      'AI Temperature': dotenv.env['AI_TRANSCRIPT_TEMPERATURE'] ?? '0.1',
    };
  }

  /// Get configuration status for UI display
  static Map<String, bool> getConfigStatus() {
    final provider = aiProvider;
    return {
      'openai_configured': _isApiKeyConfigured('OPENAI_API_KEY'),
      'gemini_configured': _isApiKeyConfigured('GEMINI_API_KEY'),
      'youtube_configured': _isApiKeyConfigured('YOUTUBE_API_KEY'),
      'environment_loaded': dotenv.isEveryDefined(['ENVIRONMENT']),
      'ai_provider_ready': provider == 'gemini' 
          ? _isApiKeyConfigured('GEMINI_API_KEY') 
          : _isApiKeyConfigured('OPENAI_API_KEY'),
    };
  }

  /// Check if API key is properly configured
  static bool _isApiKeyConfigured(String keyName) {
    final value = dotenv.env[keyName] ?? '';
    return value.isNotEmpty && !value.contains('your_') && !value.contains('_here');
  }

  /// Print configuration summary to console
  static void printConfigSummary() {
    developer.log('=== Environment Configuration Summary ===', name: _tag);
    
    final summary = getConfigSummary();
    for (final entry in summary.entries) {
      developer.log('${entry.key}: ${entry.value}', name: _tag);
    }

    final warnings = validateConfigurationSafe();
    if (warnings.isNotEmpty) {
      developer.log('=== Configuration Warnings ===', name: _tag);
      for (final warning in warnings) {
        developer.log('⚠️  $warning', name: _tag);
      }
    }

    developer.log('==========================================', name: _tag);
  }

  /// Get setup instructions for missing configuration
  static String getSetupInstructions() {
    final warnings = validateConfigurationSafe();
    if (warnings.isEmpty) {
      return 'All configuration is properly set up!';
    }

    final buffer = StringBuffer();
    buffer.writeln('Environment Setup Required:');
    buffer.writeln('');
    
    final provider = aiProvider;
    
    if (provider == 'gemini' && !_isApiKeyConfigured('GEMINI_API_KEY')) {
      buffer.writeln('1. Get Gemini API Key:');
      buffer.writeln('   • Visit https://ai.google.dev/');
      buffer.writeln('   • Create a new API key');
      buffer.writeln('   • Copy the key (starts with "AIza")');
      buffer.writeln('');
      buffer.writeln('2. Configure .env file:');
      buffer.writeln('   • Copy .env.example to .env');
      buffer.writeln('   • Set GEMINI_API_KEY value with your actual key');
      buffer.writeln('   • Set AI_PROVIDER=gemini or OPENAI_MODEL=gemini-2.5-pro');
      buffer.writeln('');
    } else if (provider == 'openai' && !_isApiKeyConfigured('OPENAI_API_KEY')) {
      buffer.writeln('1. Get OpenAI API Key:');
      buffer.writeln('   • Visit https://platform.openai.com/api-keys');
      buffer.writeln('   • Create a new API key');
      buffer.writeln('   • Copy the key (starts with "sk-")');
      buffer.writeln('');
      buffer.writeln('2. Configure .env file:');
      buffer.writeln('   • Copy .env.example to .env');
      buffer.writeln('   • Replace OPENAI_API_KEY value with your actual key');
      buffer.writeln('');
    }

    buffer.writeln('3. Restart the application after configuration');

    return buffer.toString();
  }

  /// Check if environment is properly configured for AI features
  static bool get isAIReady {
    final provider = aiProvider;
    return provider == 'gemini' 
        ? _isApiKeyConfigured('GEMINI_API_KEY') 
        : _isApiKeyConfigured('OPENAI_API_KEY');
  }

  /// Check if YouTube API is configured
  static bool get isYouTubeAPIReady => _isApiKeyConfigured('YOUTUBE_API_KEY');

  /// Get environment variable with default value
  static String getEnvVar(String key, String defaultValue) {
    return dotenv.env[key] ?? defaultValue;
  }

  /// Get environment variable as int with default value
  static int getEnvInt(String key, int defaultValue) {
    final value = dotenv.env[key];
    return int.tryParse(value ?? '') ?? defaultValue;
  }

  /// Get environment variable as double with default value
  static double getEnvDouble(String key, double defaultValue) {
    final value = dotenv.env[key];
    return double.tryParse(value ?? '') ?? defaultValue;
  }

  /// Get environment variable as bool with default value
  static bool getEnvBool(String key, bool defaultValue) {
    final value = dotenv.env[key]?.toLowerCase();
    if (value == 'true' || value == '1') return true;
    if (value == 'false' || value == '0') return false;
    return defaultValue;
  }
}