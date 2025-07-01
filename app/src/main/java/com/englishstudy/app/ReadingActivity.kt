package com.englishstudy.app

import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import com.englishstudy.app.adapter.SentenceAdapter
import com.englishstudy.app.data.AppDatabase
import com.englishstudy.app.data.TextEntry
import com.englishstudy.app.data.Sentence
import com.englishstudy.app.databinding.ActivityReadingBinding
import com.englishstudy.app.utils.AudioPlayer

class ReadingActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityReadingBinding
    private lateinit var database: AppDatabase
    private lateinit var audioPlayer: AudioPlayer
    
    private var currentEntry: TextEntry? = null
    private var sentences: List<Sentence> = emptyList()
    private var currentSentenceIndex = 0
    private var readingMode = ReadingMode.SEQUENTIAL
    private var isPlaying = false
    private lateinit var sentenceAdapter: SentenceAdapter
    
    enum class ReadingMode {
        SEQUENTIAL, POINT_READ, REPEAT
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityReadingBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        database = AppDatabase.getDatabase(this)
        audioPlayer = AudioPlayer()
        
        val entryId = intent.getLongExtra("ENTRY_ID", -1)
        
        setupListeners()
        loadEntry(entryId)
    }
    
    private fun setupListeners() {
        binding.toolbar.setNavigationOnClickListener {
            finish()
        }
        
        // Reading mode buttons
        binding.sequentialButton.setOnClickListener {
            setReadingMode(ReadingMode.SEQUENTIAL)
        }
        
        binding.pointReadButton.setOnClickListener {
            setReadingMode(ReadingMode.POINT_READ)
        }
        
        binding.repeatButton.setOnClickListener {
            setReadingMode(ReadingMode.REPEAT)
        }
        
        // Navigation buttons
        binding.previousPhaseButton.setOnClickListener {
            previousSentence()
        }
        
        binding.nextPhaseButton.setOnClickListener {
            nextSentence()
        }
        
        binding.playPauseButton.setOnClickListener {
            togglePlayPause()
        }
        
        // Font size button
        binding.fontSizeButton.setOnClickListener {
            adjustFontSize()
        }
        
        // RecyclerView will be setup after loading entry
    }
    
    private fun loadEntry(entryId: Long) {
        Thread {
            currentEntry = database.textEntryDao().getEntryById(entryId)
            sentences = database.sentenceDao().getSentencesByTextEntryIdSync(entryId)
            
            runOnUiThread {
                currentEntry?.let { entry ->
                    binding.titleText.text = entry.title
                    
                    android.util.Log.d("ReadingActivity", "Loaded entry: ${entry.title}")
                    android.util.Log.d("ReadingActivity", "Found ${sentences.size} sentences in database")
                    
                    if (sentences.isNotEmpty()) {
                        setupRecyclerView()
                        updateProgress()
                    } else {
                        Toast.makeText(this, "No audio found. Please generate audio first.", Toast.LENGTH_SHORT).show()
                        finish()
                    }
                } ?: run {
                    Toast.makeText(this, "Entry not found", Toast.LENGTH_SHORT).show()
                    finish()
                }
            }
        }.start()
    }
    
    
    private fun setupRecyclerView() {
        if (sentences.isNotEmpty()) {
            val sentenceTexts = sentences.map { it.content }
            sentenceAdapter = SentenceAdapter(sentenceTexts) { position ->
                currentSentenceIndex = position
                updateProgress()
                if (readingMode == ReadingMode.POINT_READ || !isPlaying) {
                    playCurrentSentence()
                }
            }
            binding.sentencesRecyclerView.adapter = sentenceAdapter
            binding.sentencesRecyclerView.layoutManager = LinearLayoutManager(this)
        }
    }
    
    private fun updateProgress() {
        if (sentences.isNotEmpty() && currentSentenceIndex < sentences.size) {
            binding.progressText.text = "${currentSentenceIndex + 1} / ${sentences.size}"
            
            // Update navigation button states
            binding.previousPhaseButton.alpha = if (currentSentenceIndex > 0) 1.0f else 0.5f
            binding.nextPhaseButton.alpha = if (currentSentenceIndex < sentences.size - 1) 1.0f else 0.5f
            
            // Update sentence highlighting
            if (::sentenceAdapter.isInitialized) {
                sentenceAdapter.setCurrentPlayingIndex(if (isPlaying) currentSentenceIndex else -1)
            }
        }
    }
    
    private fun setReadingMode(mode: ReadingMode) {
        readingMode = mode
        
        // Update button states
        binding.sequentialButton.isSelected = mode == ReadingMode.SEQUENTIAL
        binding.pointReadButton.isSelected = mode == ReadingMode.POINT_READ
        binding.repeatButton.isSelected = mode == ReadingMode.REPEAT
        
        when (mode) {
            ReadingMode.SEQUENTIAL -> {
                Toast.makeText(this, "Sequential mode: Auto play all phases", Toast.LENGTH_SHORT).show()
            }
            ReadingMode.POINT_READ -> {
                Toast.makeText(this, "Point reading: Tap text to play", Toast.LENGTH_SHORT).show()
            }
            ReadingMode.REPEAT -> {
                Toast.makeText(this, "Repeat mode: Loop current phase", Toast.LENGTH_SHORT).show()
            }
        }
    }
    
    private fun previousSentence() {
        if (currentSentenceIndex > 0) {
            currentSentenceIndex--
            updateProgress()
            
            if (readingMode == ReadingMode.SEQUENTIAL && isPlaying) {
                playCurrentSentence()
            }
        }
    }
    
    private fun nextSentence() {
        if (currentSentenceIndex < sentences.size - 1) {
            currentSentenceIndex++
            updateProgress()
            
            if (readingMode == ReadingMode.SEQUENTIAL && isPlaying) {
                playCurrentSentence()
            }
        } else if (readingMode == ReadingMode.SEQUENTIAL && isPlaying) {
            // Restart from beginning in sequential mode
            currentSentenceIndex = 0
            updateProgress()
            playCurrentSentence()
        }
    }
    
    private fun playCurrentSentence() {
        if (sentences.isNotEmpty() && currentSentenceIndex < sentences.size) {
            val currentSentence = sentences[currentSentenceIndex]
            
            currentSentence.audioFilePath?.let { audioPath ->
                audioPlayer.playAudio(audioPath)
                isPlaying = true
                binding.playPauseButton.setImageResource(android.R.drawable.ic_media_pause)
                updateProgress()
                
                when (readingMode) {
                    ReadingMode.SEQUENTIAL -> {
                        Toast.makeText(this, "Playing sentence ${currentSentenceIndex + 1}", Toast.LENGTH_SHORT).show()
                    }
                    ReadingMode.POINT_READ -> {
                        Toast.makeText(this, "Point reading sentence ${currentSentenceIndex + 1}", Toast.LENGTH_SHORT).show()
                    }
                    ReadingMode.REPEAT -> {
                        Toast.makeText(this, "Repeating sentence ${currentSentenceIndex + 1}", Toast.LENGTH_SHORT).show()
                    }
                }
            } ?: run {
                Toast.makeText(this, "No audio available for sentence ${currentSentenceIndex + 1}", Toast.LENGTH_SHORT).show()
            }
        }
    }
    
    private fun togglePlayPause() {
        if (isPlaying) {
            // Pause playback
            audioPlayer.pauseAudio()
            isPlaying = false
            binding.playPauseButton.setImageResource(android.R.drawable.ic_media_play)
            updateProgress()
        } else {
            // Resume or start playback
            if (audioPlayer.isPlaying) {
                audioPlayer.resumeAudio()
            } else {
                playCurrentSentence()
            }
            isPlaying = true
            binding.playPauseButton.setImageResource(android.R.drawable.ic_media_pause)
            updateProgress()
        }
    }
    
    private fun adjustFontSize() {
        // Find all TextViews in the RecyclerView and adjust their size
        val currentSize = 16f // Default size
        val newSize = when {
            currentSize < 16 -> 18f
            currentSize < 18 -> 20f
            currentSize < 20 -> 14f
            else -> 16f
        }
        
        // Update adapter to refresh with new font size
        if (::sentenceAdapter.isInitialized) {
            sentenceAdapter.notifyDataSetChanged()
        }
        Toast.makeText(this, "Font size: ${newSize.toInt()}sp", Toast.LENGTH_SHORT).show()
    }
    
    
    override fun onDestroy() {
        super.onDestroy()
        audioPlayer.release()
    }
}