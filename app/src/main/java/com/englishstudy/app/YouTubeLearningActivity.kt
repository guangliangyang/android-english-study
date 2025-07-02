package com.englishstudy.app

import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.englishstudy.app.databinding.ActivityYoutubeLearningBinding
import com.pierfrancescosoffritti.androidyoutubeplayer.core.player.YouTubePlayer
import com.pierfrancescosoffritti.androidyoutubeplayer.core.player.listeners.AbstractYouTubePlayerListener
import java.util.regex.Pattern

class YouTubeLearningActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityYoutubeLearningBinding
    private var youTubePlayer: YouTubePlayer? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityYoutubeLearningBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        setupYouTubePlayer()
        setupUI()
    }
    
    private fun setupYouTubePlayer() {
        lifecycle.addObserver(binding.youtubePlayerView)
        
        binding.youtubePlayerView.addYouTubePlayerListener(object : AbstractYouTubePlayerListener() {
            override fun onReady(youTubePlayer: YouTubePlayer) {
                this@YouTubeLearningActivity.youTubePlayer = youTubePlayer
            }
        })
    }
    
    private fun setupUI() {
        binding.playButton.setOnClickListener {
            val url = binding.urlEditText.text.toString().trim()
            if (url.isNotEmpty()) {
                val videoId = extractVideoId(url)
                if (videoId != null) {
                    youTubePlayer?.loadVideo(videoId, 0f)
                } else {
                    Toast.makeText(this, "Invalid YouTube URL", Toast.LENGTH_SHORT).show()
                }
            } else {
                Toast.makeText(this, "Please enter a YouTube URL", Toast.LENGTH_SHORT).show()
            }
        }
        
        binding.clearButton.setOnClickListener {
            binding.urlEditText.text?.clear()
        }
    }
    
    private fun extractVideoId(url: String): String? {
        val patterns = listOf(
            "(?:https?://)?(?:www\\.)?(?:youtube\\.com/watch\\?v=|youtu\\.be/)([\\w-]+)",
            "(?:https?://)?(?:www\\.)?youtube\\.com/embed/([\\w-]+)",
            "(?:https?://)?(?:www\\.)?youtube\\.com/v/([\\w-]+)"
        )
        
        for (patternString in patterns) {
            val pattern = Pattern.compile(patternString)
            val matcher = pattern.matcher(url)
            if (matcher.find()) {
                return matcher.group(1)
            }
        }
        return null
    }
    
    override fun onDestroy() {
        super.onDestroy()
        binding.youtubePlayerView.release()
    }
}