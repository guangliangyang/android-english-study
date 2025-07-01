package com.englishstudy.app

import android.os.Bundle
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.englishstudy.app.data.AppDatabase
import com.englishstudy.app.data.TextEntry
import com.englishstudy.app.data.Sentence
import com.englishstudy.app.databinding.ActivityTextReaderBinding
import com.englishstudy.app.tts.TTSService
import com.englishstudy.app.utils.AudioPlayer
import com.englishstudy.app.utils.TextSplitter
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

class TextReaderActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityTextReaderBinding
    private lateinit var database: AppDatabase
    private lateinit var ttsService: TTSService
    private lateinit var audioPlayer: AudioPlayer
    
    private var currentEntry: TextEntry? = null
    private var entryId: Long = -1
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityTextReaderBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        database = AppDatabase.getDatabase(this)
        ttsService = TTSService(this)
        audioPlayer = AudioPlayer()
        
        entryId = intent.getLongExtra("ENTRY_ID", -1)
        
        setupListeners()
        setupSpeedControl()
        
        android.util.Log.d("TextReader", "=== ACTIVITY CREATED ===")
        android.util.Log.d("TextReader", "entryId from intent: $entryId")
        
        if (entryId != -1L) {
            android.util.Log.d("TextReader", "Loading existing entry with ID: $entryId")
            loadEntry()
        } else {
            // This is a new entry, ensure currentEntry is null
            currentEntry = null
            android.util.Log.d("TextReader", "Starting with NEW entry (currentEntry = null, entryId = -1)")
        }
    }
    
    private fun setupListeners() {
        binding.toolbar.setNavigationOnClickListener {
            finish()
        }
        
        binding.saveButton.setOnClickListener {
            saveAndFinish()
        }
        
        binding.generateButton.setOnClickListener {
            generateAudio()
        }
        
        binding.playButton.setOnClickListener {
            playAudio()
        }
    }
    
    private fun setupSpeedControl() {
        binding.speedSeekBar.setOnSeekBarChangeListener(object : android.widget.SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: android.widget.SeekBar?, progress: Int, fromUser: Boolean) {
                val speed = (progress + 5) / 10.0f // Range from 0.5x to 2.5x
                binding.speedText.text = String.format("%.1fx", speed)
                if (fromUser) {
                    audioPlayer.setPlaybackSpeed(speed)
                }
            }
            
            override fun onStartTrackingTouch(seekBar: android.widget.SeekBar?) {}
            override fun onStopTrackingTouch(seekBar: android.widget.SeekBar?) {}
        })
    }
    
    private fun loadEntry() {
        currentEntry = database.textEntryDao().getEntryById(entryId)
        currentEntry?.let { entry ->
            binding.titleEditText.setText(entry.title)
            binding.textEditText.setText(entry.content)
            binding.playButton.isEnabled = !entry.audioFilePath.isNullOrEmpty()
        }
    }
    
    private fun saveAndFinish() {
        val title = binding.titleEditText.text.toString().trim()
        val text = binding.textEditText.text.toString().trim()
        
        if (title.isEmpty() || text.isEmpty()) {
            Toast.makeText(this, "Please enter both title and text", Toast.LENGTH_SHORT).show()
            return
        }
        
        val wordCount = text.split("\\s+".toRegex()).size
        val estimatedDuration = estimateDuration(wordCount)
        
        val entry = if (currentEntry != null) {
            // Updating existing entry
            currentEntry!!.copy(
                title = title,
                content = text,
                wordCount = wordCount,
                estimatedDuration = estimatedDuration
            )
        } else {
            // Creating completely new entry
            TextEntry(
                title = title,
                content = text,
                audioFilePath = null, // New entry has no audio initially
                wordCount = wordCount,
                estimatedDuration = estimatedDuration
            )
        }
        
        try {
            android.util.Log.d("TextReader", "=== SAVE OPERATION START ===")
            android.util.Log.d("TextReader", "currentEntry is null: ${currentEntry == null}")
            android.util.Log.d("TextReader", "entryId value: $entryId")
            android.util.Log.d("TextReader", "Title: '$title', Content length: ${text.length}")
            android.util.Log.d("TextReader", "Entry to save - ID: ${entry.id}, Title: ${entry.title}")
            
            if (currentEntry != null && entryId != -1L) {
                // We have an existing entry to update
                val updatedRows = database.textEntryDao().updateEntry(entry)
                android.util.Log.d("TextReader", "UPDATED existing entry ID: ${currentEntry!!.id}, rows affected: $updatedRows")
            } else {
                // Always create new entry if entryId is -1 (came from + button)
                val newId = database.textEntryDao().insertEntry(entry)
                entryId = newId
                android.util.Log.d("TextReader", "INSERTED NEW entry with ID: $newId")
            }
            
            // Verify the save by checking total count
            val totalCount = database.textEntryDao().getAllEntriesSync().size
            android.util.Log.d("TextReader", "Total entries in database after save: $totalCount")
            
            currentEntry = entry
            
            // Show detailed save info in toast
            val saveType = if (currentEntry != null && entryId != -1L) "UPDATED" else "NEW"
            Toast.makeText(this@TextReaderActivity, "$saveType entry saved! Total: $totalCount", Toast.LENGTH_LONG).show()
            
            // Finish activity to return to main list
            finish()
        } catch (e: Exception) {
            android.util.Log.e("TextReader", "Error saving entry", e)
            Toast.makeText(this@TextReaderActivity, "Error saving: ${e.message}", Toast.LENGTH_SHORT).show()
        }
    }
    
    private fun generateAudio() {
        val title = binding.titleEditText.text.toString().trim()
        val text = binding.textEditText.text.toString().trim()
        
        if (title.isEmpty() || text.isEmpty()) {
            Toast.makeText(this, "Please enter both title and text", Toast.LENGTH_SHORT).show()
            return
        }
        
        binding.generateButton.isEnabled = false
        binding.progressBar.visibility = View.VISIBLE
        
        Thread {
            try {
                // First save or update the text entry
                val wordCount = text.split("\\s+".toRegex()).size
                val estimatedDuration = estimateDuration(wordCount)
                
                val entry = if (currentEntry != null) {
                    currentEntry!!.copy(
                        title = title,
                        content = text,
                        wordCount = wordCount,
                        estimatedDuration = estimatedDuration
                    )
                } else {
                    TextEntry(
                        title = title,
                        content = text,
                        wordCount = wordCount,
                        estimatedDuration = estimatedDuration
                    )
                }
                
                val textEntryId = if (currentEntry != null) {
                    database.textEntryDao().updateEntry(entry)
                    entry.id
                } else {
                    val newId = database.textEntryDao().insertEntry(entry)
                    entryId = newId
                    newId
                }
                
                currentEntry = entry.copy(id = textEntryId)
                
                // Split text into sentences
                val sentences = TextSplitter.splitAndClean(text)
                
                android.util.Log.d("TextReader", "=== SENTENCE SPLITTING DEBUG ===")
                android.util.Log.d("TextReader", "Original text: '$text'")
                android.util.Log.d("TextReader", "Split into ${sentences.size} sentences:")
                sentences.forEachIndexed { index, sentence ->
                    android.util.Log.d("TextReader", "Sentence $index: '$sentence'")
                }
                
                runOnUiThread {
                    Toast.makeText(this@TextReaderActivity, "Found ${sentences.size} sentences. Generating audio...", Toast.LENGTH_SHORT).show()
                }
                
                // Generate audio for each sentence
                val fileName = "entry_${textEntryId}"
                val audioFiles = ttsService.generateSentenceAudio(
                    sentences = sentences,
                    baseFileName = fileName
                ) { current, total, message ->
                    runOnUiThread {
                        binding.progressBar.progress = (current * 100) / total
                        Toast.makeText(this@TextReaderActivity, "$current/$total: $message", Toast.LENGTH_SHORT).show()
                    }
                }
                
                // Save sentences to database
                val sentenceEntities = sentences.mapIndexed { index, sentenceText ->
                    Sentence(
                        textEntryId = textEntryId,
                        content = sentenceText,
                        orderIndex = index,
                        audioFilePath = audioFiles[index]
                    )
                }
                
                // Clear existing sentences for this entry and insert new ones
                database.sentenceDao().deleteSentencesByTextEntryId(textEntryId)
                database.sentenceDao().insertSentences(sentenceEntities)
                
                runOnUiThread {
                    binding.playButton.isEnabled = true
                    Toast.makeText(this@TextReaderActivity, "Audio generated for all sentences!", Toast.LENGTH_SHORT).show()
                    binding.generateButton.isEnabled = true
                    binding.progressBar.visibility = View.GONE
                }
                
            } catch (e: Exception) {
                android.util.Log.e("TextReader", "Error generating sentence audio", e)
                runOnUiThread {
                    Toast.makeText(this@TextReaderActivity, "Error: ${e.message}", Toast.LENGTH_SHORT).show()
                    binding.generateButton.isEnabled = true
                    binding.progressBar.visibility = View.GONE
                }
            }
        }.start()
    }
    
    private fun playAudio() {
        currentEntry?.let { entry ->
            Thread {
                // Get the first sentence's audio to play as a preview
                val sentences = database.sentenceDao().getSentencesByTextEntryIdSync(entry.id)
                val firstSentence = sentences.firstOrNull()
                
                runOnUiThread {
                    firstSentence?.audioFilePath?.let { audioPath ->
                        val speed = (binding.speedSeekBar.progress + 5) / 10.0f
                        audioPlayer.playAudio(audioPath, speed)
                        Toast.makeText(this@TextReaderActivity, "Playing first sentence preview...", Toast.LENGTH_SHORT).show()
                    } ?: run {
                        Toast.makeText(this@TextReaderActivity, "No audio available. Please generate audio first.", Toast.LENGTH_SHORT).show()
                    }
                }
            }.start()
        }
    }
    
    private fun estimateDuration(wordCount: Int): String {
        val wordsPerMinute = 150
        val totalMinutes = wordCount / wordsPerMinute
        val minutes = if (totalMinutes < 1) 1 else totalMinutes
        val seconds = ((wordCount % wordsPerMinute) * 60) / wordsPerMinute
        
        return if (minutes > 0) {
            "${minutes}分${seconds}秒"
        } else {
            "${seconds}秒"
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        audioPlayer.release()
        ttsService.close()
    }
}