package com.englishstudy.app.tts

import android.content.Context
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import java.io.File
import java.util.*

class TTSService(private val context: Context) {
    
    private var textToSpeech: TextToSpeech? = null
    private var isInitialized = false
    
    init {
        textToSpeech = TextToSpeech(context) { status ->
            if (status == TextToSpeech.SUCCESS) {
                textToSpeech?.language = Locale.US
                isInitialized = true
            }
        }
    }
    
    fun generateSpeech(
        text: String,
        outputFileName: String,
        onProgress: (String) -> Unit = {}
    ): String? {
        if (!isInitialized || textToSpeech == null) {
            onProgress("TTS not initialized")
            return null
        }
        
        try {
            onProgress("Preparing text for synthesis...")
            
            val audioDir = File(context.filesDir, "audio")
            if (!audioDir.exists()) {
                audioDir.mkdirs()
            }
            
            val outputFile = File(audioDir, "$outputFileName.wav")
            
            textToSpeech?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String?) {
                    onProgress("Synthesizing speech...")
                }
                
                override fun onDone(utteranceId: String?) {
                    onProgress("Audio generation completed!")
                }
                
                @Deprecated("Deprecated in API level 21", ReplaceWith("onError(utteranceId, errorCode)"))
                override fun onError(utteranceId: String?) {
                    onProgress("Error generating audio")
                }
            })
            
            val result = textToSpeech?.synthesizeToFile(text, null, outputFile, outputFileName)
            
            return if (result == TextToSpeech.SUCCESS) {
                outputFile.absolutePath
            } else {
                onProgress("Failed to generate audio")
                null
            }
        } catch (e: Exception) {
            e.printStackTrace()
            onProgress("Error: ${e.message}")
            return null
        }
    }
    
    /**
     * Generate audio for multiple sentences
     * @param sentences List of sentence texts
     * @param baseFileName Base name for audio files (will append sentence index)
     * @param onProgress Progress callback with (currentIndex, totalCount, message)
     * @return List of generated audio file paths
     */
    fun generateSentenceAudio(
        sentences: List<String>,
        baseFileName: String,
        onProgress: (Int, Int, String) -> Unit = { _, _, _ -> }
    ): List<String?> {
        if (!isInitialized || textToSpeech == null) {
            onProgress(0, sentences.size, "TTS not initialized")
            return sentences.map { null }
        }
        
        val audioFiles = mutableListOf<String?>()
        
        sentences.forEachIndexed { index, sentence ->
            onProgress(index + 1, sentences.size, "Generating audio for sentence ${index + 1}...")
            
            val fileName = "${baseFileName}_sentence_${index + 1}"
            val audioPath = generateSpeech(
                text = sentence,
                outputFileName = fileName,
                onProgress = { msg -> onProgress(index + 1, sentences.size, msg) }
            )
            
            audioFiles.add(audioPath)
            
            // Small delay between generations to avoid overwhelming the TTS engine
            try {
                Thread.sleep(500)
            } catch (e: InterruptedException) {
                Thread.currentThread().interrupt()
                return audioFiles
            }
        }
        
        onProgress(sentences.size, sentences.size, "All sentence audio generation completed!")
        return audioFiles
    }
    
    fun close() {
        textToSpeech?.stop()
        textToSpeech?.shutdown()
    }
}