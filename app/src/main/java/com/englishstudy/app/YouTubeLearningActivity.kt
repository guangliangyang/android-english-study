package com.englishstudy.app

import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.englishstudy.app.databinding.ActivityYoutubeLearningBinding
import com.englishstudy.app.model.Transcript
import com.englishstudy.app.service.TranscriptService
import com.pierfrancescosoffritti.androidyoutubeplayer.core.player.YouTubePlayer
import com.pierfrancescosoffritti.androidyoutubeplayer.core.player.listeners.AbstractYouTubePlayerListener
import com.pierfrancescosoffritti.androidyoutubeplayer.core.player.listeners.YouTubePlayerCallback
import kotlinx.coroutines.launch
import java.util.regex.Pattern
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.text.style.BackgroundColorSpan
import androidx.core.content.ContextCompat

class YouTubeLearningActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityYoutubeLearningBinding
    private var youTubePlayer: YouTubePlayer? = null
    private var currentVideoId: String? = null
    private var currentTranscript: Transcript? = null
    private val transcriptService = TranscriptService()
    private var currentPlayTime: Float = 0f
    private var highlightedSegmentIndex = -1
    
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
            
            override fun onCurrentSecond(youTubePlayer: YouTubePlayer, second: Float) {
                currentPlayTime = second
                updateTranscriptHighlight()
            }
        })
    }
    
    private fun setupUI() {
        // 设置默认调试URL
        binding.urlEditText.setText("https://m.youtube.com/watch?v=8YkkvVe_Z8w")
        
        binding.playButton.setOnClickListener {
            val url = binding.urlEditText.text.toString().trim()
            if (url.isNotEmpty()) {
                val videoId = extractVideoId(url)
                if (videoId != null) {
                    currentVideoId = videoId
                    youTubePlayer?.loadVideo(videoId, 0f)
                    Toast.makeText(this, "Playing video: $videoId", Toast.LENGTH_SHORT).show()
                    loadTranscript(videoId)
                } else {
                    Toast.makeText(this, "Invalid YouTube URL", Toast.LENGTH_SHORT).show()
                }
            } else {
                Toast.makeText(this, "Please enter a YouTube URL", Toast.LENGTH_SHORT).show()
            }
        }
        
        binding.clearButton.setOnClickListener {
            binding.urlEditText.text?.clear()
            clearTranscript()
        }
        
    }
    
    private fun loadTranscript(videoId: String) {
        lifecycleScope.launch {
            try {
                binding.transcriptText.text = "Loading transcript..."
                
                val transcript = transcriptService.getTranscript(videoId)
                
                if (transcript != null) {
                    currentTranscript = transcript
                    displayTranscript(transcript)
                    Toast.makeText(this@YouTubeLearningActivity, "Transcript loaded successfully!", Toast.LENGTH_SHORT).show()
                } else {
                    binding.transcriptText.text = "No transcript available for this video"
                    Toast.makeText(this@YouTubeLearningActivity, "No transcript found for this video", Toast.LENGTH_LONG).show()
                }
            } catch (e: Exception) {
                binding.transcriptText.text = "Error loading transcript: ${e.message}"
                Toast.makeText(this@YouTubeLearningActivity, "Error: ${e.message}", Toast.LENGTH_LONG).show()
            }
        }
    }
    
    
    private fun displayTranscript(transcript: Transcript) {
        val spannableBuilder = SpannableStringBuilder()
        
        for ((index, segment) in transcript.segments.withIndex()) {
            val timeFormatted = formatTime(segment.startTime)
            val segmentText = "[$timeFormatted] ${segment.text}\n\n"
            spannableBuilder.append(segmentText)
        }
        
        binding.transcriptText.text = spannableBuilder.toString().trim()
        updateTranscriptHighlight()
    }
    
    private fun formatTime(seconds: Float): String {
        val totalSeconds = seconds.toInt()
        val minutes = totalSeconds / 60
        val remainingSeconds = totalSeconds % 60
        return String.format("%d:%02d", minutes, remainingSeconds)
    }
    
    private fun updateTranscriptHighlight() {
        val transcript = currentTranscript ?: return
        
        // 找到当前播放时间对应的段落
        var currentSegmentIndex = -1
        for ((index, segment) in transcript.segments.withIndex()) {
            if (currentPlayTime >= segment.startTime && currentPlayTime < segment.startTime + segment.duration) {
                currentSegmentIndex = index
                break
            }
        }
        
        // 如果高亮的段落没有变化，不需要更新
        if (currentSegmentIndex == highlightedSegmentIndex) return
        
        highlightedSegmentIndex = currentSegmentIndex
        
        // 重新构建带高亮的文本
        val spannableBuilder = SpannableStringBuilder()
        
        for ((index, segment) in transcript.segments.withIndex()) {
            val timeFormatted = formatTime(segment.startTime)
            val segmentText = "[$timeFormatted] ${segment.text}\n\n"
            val startPos = spannableBuilder.length
            spannableBuilder.append(segmentText)
            val endPos = spannableBuilder.length
            
            // 如果是当前播放的段落，添加高亮背景
            if (index == currentSegmentIndex) {
                val highlightColor = ContextCompat.getColor(this, android.R.color.holo_orange_light)
                spannableBuilder.setSpan(
                    BackgroundColorSpan(highlightColor),
                    startPos,
                    endPos - 2, // 减去最后的换行符
                    Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
                )
            }
        }
        
        binding.transcriptText.text = spannableBuilder
        
        // 自动滚动到高亮的句子，使其在屏幕中间
        if (currentSegmentIndex >= 0) {
            scrollToHighlightedSegment(currentSegmentIndex, transcript.segments.size)
        }
    }
    
    private fun scrollToHighlightedSegment(currentSegmentIndex: Int, totalSegments: Int) {
        // 计算每个segment在文本中的大概位置
        val transcriptText = binding.transcriptText
        val scrollView = binding.transcriptScrollView
        
        // 估算当前segment在文本中的相对位置 (0.0 到 1.0)
        val segmentPosition = currentSegmentIndex.toFloat() / totalSegments.toFloat()
        
        // 获取TextView的总高度
        transcriptText.post {
            val textHeight = transcriptText.height
            val scrollViewHeight = scrollView.height
            
            // 计算目标位置：让当前segment显示在屏幕中间
            val targetY = (textHeight * segmentPosition - scrollViewHeight / 2).toInt()
            
            // 确保不会滚动到超出范围的位置
            val maxScrollY = maxOf(0, textHeight - scrollViewHeight)
            val scrollY = targetY.coerceIn(0, maxScrollY)
            
            // 平滑滚动到目标位置
            scrollView.smoothScrollTo(0, scrollY)
        }
    }
    
    private fun clearTranscript() {
        currentTranscript = null
        currentVideoId = null
        currentPlayTime = 0f
        highlightedSegmentIndex = -1
        binding.transcriptText.text = "Paste a YouTube video URL above and tap 'Play Video' to start learning English with YouTube videos!"
    }
    
    private fun extractVideoId(url: String): String? {
        val patterns = listOf(
            "(?:https?://)?(?:www\\.)?(?:youtube\\.com/watch\\?v=|youtu\\.be/)([\\w-]+)",
            "(?:https?://)?(?:m\\.)?youtube\\.com/watch\\?v=([\\w-]+)",
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