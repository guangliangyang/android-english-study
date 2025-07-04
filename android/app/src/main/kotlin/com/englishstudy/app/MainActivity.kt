package com.englishstudy.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.os.Bundle

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.englishstudy.app/youtube"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openYouTubeVideo" -> {
                    val videoId = call.argument<String>("videoId")
                    if (videoId != null) {
                        openYouTubeVideo(videoId)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Video ID is required", null)
                    }
                }
                "shareVideo" -> {
                    val videoUrl = call.argument<String>("videoUrl")
                    val title = call.argument<String>("title")
                    if (videoUrl != null) {
                        shareVideo(videoUrl, title)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Video URL is required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Handle incoming YouTube URLs
        handleIncomingIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIncomingIntent(intent)
    }

    private fun handleIncomingIntent(intent: Intent) {
        if (intent.action == Intent.ACTION_VIEW) {
            val data = intent.data
            if (data != null && (data.host == "www.youtube.com" || data.host == "youtu.be")) {
                val videoId = extractVideoId(data)
                if (videoId != null) {
                    // Send the video ID to Flutter
                    flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                        MethodChannel(messenger, CHANNEL).invokeMethod("receiveVideoId", videoId)
                    }
                }
            }
        }
    }

    private fun extractVideoId(uri: Uri): String? {
        return when {
            uri.host == "youtu.be" -> {
                uri.path?.substring(1) // Remove the leading "/"
            }
            uri.host == "www.youtube.com" -> {
                uri.getQueryParameter("v")
            }
            else -> null
        }
    }

    private fun openYouTubeVideo(videoId: String) {
        try {
            // Try to open in YouTube app
            val youtubeIntent = Intent(Intent.ACTION_VIEW, Uri.parse("vnd.youtube:$videoId"))
            youtubeIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(youtubeIntent)
        } catch (e: Exception) {
            // Fall back to web browser
            val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse("https://www.youtube.com/watch?v=$videoId"))
            browserIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(browserIntent)
        }
    }

    private fun shareVideo(videoUrl: String, title: String?) {
        val shareIntent = Intent().apply {
            action = Intent.ACTION_SEND
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, videoUrl)
            if (title != null) {
                putExtra(Intent.EXTRA_SUBJECT, title)
            }
        }
        
        val chooserIntent = Intent.createChooser(shareIntent, "Share Video")
        chooserIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(chooserIntent)
    }
}