package com.englishstudy.app

import android.animation.ValueAnimator
import android.os.Bundle
import android.util.Log
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.animation.DecelerateInterpolator
import android.widget.SeekBar
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import com.englishstudy.app.databinding.ActivityYoutubeLearningBinding
import com.englishstudy.app.model.Transcript
import com.englishstudy.app.service.TranscriptService
import com.pierfrancescosoffritti.androidyoutubeplayer.core.player.PlayerConstants
import com.pierfrancescosoffritti.androidyoutubeplayer.core.player.YouTubePlayer
import com.pierfrancescosoffritti.androidyoutubeplayer.core.player.listeners.AbstractYouTubePlayerListener
import kotlinx.coroutines.launch
import java.util.regex.Pattern
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.text.style.BackgroundColorSpan

class YouTubeLearningActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityYoutubeLearningBinding
    private var youTubePlayer: YouTubePlayer? = null
    private var currentVideoId: String? = null
    private var currentTranscript: Transcript? = null
    private val transcriptService = TranscriptService()
    private var currentPlayTime: Float = 0f
    private var highlightedSegmentIndex = -1
    private var videoDuration: Float = 0f
    private var isPlaying: Boolean = false
    private var isSeekBarTracking: Boolean = false
    private var isLoopMode: Boolean = false
    private var loopStartTime: Float = 0f
    private var loopEndTime: Float = 0f
    private var currentFontSize: Float = 16f
    private val fontSizes = arrayOf(14f, 16f, 18f, 20f, 24f)
    private var isHeaderVisible: Boolean = true
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityYoutubeLearningBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        setupYouTubePlayer()
        setupUI()
        setupGestureDetector()
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
                updateProgressBar()
                
                // 检查循环模式
                if (isLoopMode && currentPlayTime >= loopEndTime) {
                    youTubePlayer.seekTo(loopStartTime)
                }
            }
            
            override fun onVideoDuration(youTubePlayer: YouTubePlayer, duration: Float) {
                videoDuration = duration
                binding.totalTimeText.text = formatTime(duration)
                binding.videoProgressBar.max = duration.toInt()
            }
            
            override fun onStateChange(youTubePlayer: YouTubePlayer, state: PlayerConstants.PlayerState) {
                when (state) {
                    PlayerConstants.PlayerState.PLAYING -> {
                        isPlaying = true
                        binding.playPauseButton.setImageResource(R.drawable.ic_pause)
                    }
                    PlayerConstants.PlayerState.PAUSED -> {
                        isPlaying = false
                        binding.playPauseButton.setImageResource(R.drawable.ic_play_arrow)
                    }
                    else -> {
                        // Handle other states if needed
                    }
                }
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
        
        // 设置视频控制按钮
        setupVideoControls()
    }
    
    private fun setupVideoControls() {
        // 循环/顺序播放模式按钮
        binding.loopModeButton.setOnClickListener {
            toggleLoopMode()
        }
        
        // 播放/暂停按钮
        binding.playPauseButton.setOnClickListener {
            youTubePlayer?.let { player ->
                if (isPlaying) {
                    player.pause()
                } else {
                    player.play()
                }
            }
        }
        
        // 后退10秒按钮
        binding.rewindButton.setOnClickListener {
            if (isLoopMode) {
                // 复读模式下：调整循环起始点
                adjustLoopWithRewind()
            } else {
                // 普通模式下：正常后退
                youTubePlayer?.let { player ->
                    val newTime = maxOf(0f, currentPlayTime - 10f)
                    player.seekTo(newTime)
                }
            }
        }
        
        // 前进10秒按钮
        binding.forwardButton.setOnClickListener {
            if (isLoopMode) {
                // 复读模式下：调整循环结束点
                adjustLoopWithForward()
            } else {
                // 普通模式下：正常前进
                youTubePlayer?.let { player ->
                    val newTime = minOf(videoDuration, currentPlayTime + 10f)
                    player.seekTo(newTime)
                }
            }
        }
        
        // 字体大小按钮
        binding.fontSizeButton.setOnClickListener {
            cycleFontSize()
        }
        
        // 进度条控制
        binding.videoProgressBar.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                if (fromUser) {
                    binding.currentTimeText.text = formatTime(progress.toFloat())
                }
            }
            
            override fun onStartTrackingTouch(seekBar: SeekBar?) {
                isSeekBarTracking = true
            }
            
            override fun onStopTrackingTouch(seekBar: SeekBar?) {
                isSeekBarTracking = false
                seekBar?.let { bar ->
                    val seekTime = bar.progress.toFloat()
                    youTubePlayer?.seekTo(seekTime)
                    
                    // 在复读模式下调整循环范围
                    adjustLoopWithSeek(seekTime)
                }
            }
        })
    }
    
    private fun updateProgressBar() {
        if (!isSeekBarTracking) {
            binding.videoProgressBar.progress = currentPlayTime.toInt()
            binding.currentTimeText.text = formatTime(currentPlayTime)
        }
    }
    
    private fun toggleLoopMode() {
        isLoopMode = !isLoopMode
        
        if (isLoopMode) {
            // 设置循环范围：当前时间前后5秒（总共10秒）
            loopStartTime = maxOf(0f, currentPlayTime - 5f)
            loopEndTime = minOf(videoDuration, currentPlayTime + 5f)
            binding.loopModeButton.setImageResource(R.drawable.ic_repeat)
            val duration = loopEndTime - loopStartTime
            Toast.makeText(this, "复读模式: ${formatTime(loopStartTime)} - ${formatTime(loopEndTime)} (${String.format("%.1f", duration)}秒)", Toast.LENGTH_SHORT).show()
        } else {
            binding.loopModeButton.setImageResource(R.drawable.ic_sequential)
            Toast.makeText(this, "顺序播放模式", Toast.LENGTH_SHORT).show()
        }
    }
    
    private fun cycleFontSize() {
        val currentIndex = fontSizes.indexOf(currentFontSize)
        val nextIndex = (currentIndex + 1) % fontSizes.size
        currentFontSize = fontSizes[nextIndex]
        
        // 更新transcript字体大小
        binding.transcriptText.textSize = currentFontSize
        Toast.makeText(this, "字体大小: ${currentFontSize.toInt()}sp", Toast.LENGTH_SHORT).show()
    }
    
    private fun updateLoopRange(newStartTime: Float, newEndTime: Float) {
        // 边界检查：确保在视频范围内
        loopStartTime = maxOf(0f, newStartTime)
        loopEndTime = minOf(videoDuration, newEndTime)
        
        // 确保起始时间不大于结束时间
        if (loopStartTime >= loopEndTime) {
            loopEndTime = minOf(videoDuration, loopStartTime + 1f)
        }
        
        val duration = loopEndTime - loopStartTime
        Toast.makeText(this, "复读范围: ${formatTime(loopStartTime)} - ${formatTime(loopEndTime)} (${String.format("%.1f", duration)}秒)", Toast.LENGTH_SHORT).show()
    }
    
    private fun adjustLoopWithSeek(seekTime: Float) {
        if (!isLoopMode) return
        
        // 如果拖拽到循环范围外，扩展循环范围
        if (seekTime < loopStartTime || seekTime > loopEndTime) {
            val currentDuration = loopEndTime - loopStartTime
            val halfDuration = currentDuration / 2f
            
            updateLoopRange(seekTime - halfDuration, seekTime + halfDuration)
        }
    }
    
    private fun adjustLoopWithRewind() {
        if (!isLoopMode) return
        
        // 后退按钮：整个复读区间向前移动10秒，长度保持不变
        val currentDuration = loopEndTime - loopStartTime
        val newStartTime = loopStartTime - 10f
        val newEndTime = newStartTime + currentDuration
        updateLoopRange(newStartTime, newEndTime)
    }
    
    private fun adjustLoopWithForward() {
        if (!isLoopMode) return
        
        // 前进按钮：整个复读区间向后移动10秒，长度保持不变
        val currentDuration = loopEndTime - loopStartTime
        val newStartTime = loopStartTime + 10f
        val newEndTime = newStartTime + currentDuration
        updateLoopRange(newStartTime, newEndTime)
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
        binding.transcriptText.textSize = currentFontSize
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
        videoDuration = 0f
        isPlaying = false
        isSeekBarTracking = false
        isLoopMode = false
        loopStartTime = 0f
        loopEndTime = 0f
        
        // 重置UI状态
        binding.transcriptText.text = "Paste a YouTube video URL above and tap 'Play Video' to start learning English with YouTube videos!"
        binding.transcriptText.textSize = currentFontSize
        binding.videoProgressBar.progress = 0
        binding.currentTimeText.text = "0:00"
        binding.totalTimeText.text = "0:00"
        binding.playPauseButton.setImageResource(R.drawable.ic_play_arrow)
        binding.loopModeButton.setImageResource(R.drawable.ic_sequential)
        
        // 重置header显示状态
        if (!isHeaderVisible) {
            animateHeaderVisibility(true)
        }
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
    
    private fun setupGestureDetector() {
        // 使用简单的滑动检测
        var startY = 0f
        var isSwipeDetected = false
        
        binding.transcriptScrollView.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    startY = event.y
                    isSwipeDetected = false
                }
                MotionEvent.ACTION_MOVE -> {
                    val diffY = event.y - startY
                    if (!isSwipeDetected && Math.abs(diffY) > 150) {
                        isSwipeDetected = true
                        if (diffY < 0) {
                            // 向上滑动 - 隐藏header
                            if (isHeaderVisible) {
                                animateHeaderVisibility(false)
                            }
                        } else {
                            // 向下滑动 - 显示header  
                            if (!isHeaderVisible) {
                                animateHeaderVisibility(true)
                            }
                        }
                    }
                }
            }
            false // 返回false以便ScrollView能正常处理滚动
        }
    }
    
    private fun animateHeaderVisibility(show: Boolean) {
        if (show == isHeaderVisible) return
        
        val headerSection = binding.headerSection
        val startHeight = if (show) 0 else headerSection.height
        val endHeight = if (show) headerSection.measuredHeight else 0
        
        // 如果要显示，先设置visibility为VISIBLE
        if (show) {
            headerSection.visibility = View.VISIBLE
            // 需要测量header的高度
            headerSection.measure(
                View.MeasureSpec.makeMeasureSpec(binding.root.width, View.MeasureSpec.EXACTLY),
                View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED)
            )
        }
        
        val animator = ValueAnimator.ofInt(startHeight, if (show) headerSection.measuredHeight else 0)
        animator.duration = 300
        animator.interpolator = DecelerateInterpolator()
        
        animator.addUpdateListener { animation ->
            val animatedValue = animation.animatedValue as Int
            val layoutParams = headerSection.layoutParams
            layoutParams.height = animatedValue
            headerSection.layoutParams = layoutParams
        }
        
        animator.addListener(object : android.animation.Animator.AnimatorListener {
            override fun onAnimationStart(animation: android.animation.Animator) {}
            override fun onAnimationRepeat(animation: android.animation.Animator) {}
            override fun onAnimationCancel(animation: android.animation.Animator) {}
            override fun onAnimationEnd(animation: android.animation.Animator) {
                if (!show) {
                    headerSection.visibility = View.GONE
                }
                // 恢复原始高度设置
                val layoutParams = headerSection.layoutParams
                layoutParams.height = ViewGroup.LayoutParams.WRAP_CONTENT
                headerSection.layoutParams = layoutParams
            }
        })
        
        isHeaderVisible = show
        animator.start()
        
        Toast.makeText(this, if (show) "显示控制面板" else "隐藏控制面板", Toast.LENGTH_SHORT).show()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        binding.youtubePlayerView.release()
    }
}