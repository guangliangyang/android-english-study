package com.englishstudy.app.utils

import android.media.MediaPlayer
import java.io.File

class AudioPlayer {
    private var mediaPlayer: MediaPlayer? = null
    private var _isPlaying = false
    val isPlaying: Boolean get() = _isPlaying
    
    private var _playbackSpeed = 1.0f
    val playbackSpeed: Float get() = _playbackSpeed
    
    fun playAudio(audioFilePath: String, speed: Float = 1.0f) {
        try {
            stopAudio()
            
            val file = File(audioFilePath)
            if (!file.exists()) {
                return
            }
            
            mediaPlayer = MediaPlayer().apply {
                setDataSource(audioFilePath)
                prepare()
                
                // Set playback speed (requires API 23+)
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                    val params = playbackParams
                    params.speed = speed
                    playbackParams = params
                }
                
                setOnCompletionListener {
                    _isPlaying = false
                }
                
                setOnErrorListener { _, _, _ ->
                    _isPlaying = false
                    true
                }
                
                start()
                _isPlaying = true
                _playbackSpeed = speed
            }
        } catch (e: Exception) {
            e.printStackTrace()
            _isPlaying = false
        }
    }
    
    fun pauseAudio() {
        mediaPlayer?.let { player ->
            if (player.isPlaying) {
                player.pause()
                _isPlaying = false
            }
        }
    }
    
    fun resumeAudio() {
        mediaPlayer?.let { player ->
            if (!player.isPlaying) {
                player.start()
                _isPlaying = true
            }
        }
    }
    
    fun stopAudio() {
        mediaPlayer?.let { player ->
            if (player.isPlaying) {
                player.stop()
            }
            player.release()
            mediaPlayer = null
            _isPlaying = false
        }
    }
    
    fun setPlaybackSpeed(speed: Float) {
        mediaPlayer?.let { player ->
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                try {
                    val params = player.playbackParams
                    params.speed = speed
                    player.playbackParams = params
                    _playbackSpeed = speed
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
    }
    
    fun release() {
        stopAudio()
    }
}