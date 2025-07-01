package com.englishstudy.app

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.Observer
import androidx.recyclerview.widget.LinearLayoutManager
import com.englishstudy.app.adapter.TextEntryAdapter
import com.englishstudy.app.data.AppDatabase
import com.englishstudy.app.data.TextEntry
import com.englishstudy.app.databinding.ActivityMainBinding
import com.englishstudy.app.utils.AudioPlayer

class MainActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityMainBinding
    private lateinit var database: AppDatabase
    private lateinit var adapter: TextEntryAdapter
    private lateinit var audioPlayer: AudioPlayer
    private var currentSearchQuery = ""
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        database = AppDatabase.getDatabase(this)
        audioPlayer = AudioPlayer()
        
        setupRecyclerView()
        setupListeners()
        observeData()
    }
    
    private fun setupRecyclerView() {
        adapter = TextEntryAdapter(
            onItemClick = { entry ->
                val intent = Intent(this, TextReaderActivity::class.java).apply {
                    putExtra("ENTRY_ID", entry.id)
                }
                startActivity(intent)
            },
            onPlayClick = { entry ->
                // Navigate to reading activity
                val intent = Intent(this, ReadingActivity::class.java).apply {
                    putExtra("ENTRY_ID", entry.id)
                }
                startActivity(intent)
            },
            onItemLongClick = { entry ->
                showDeleteConfirmationDialog(entry)
            }
        )
        
        binding.recyclerView.layoutManager = LinearLayoutManager(this)
        binding.recyclerView.adapter = adapter
    }
    
    private fun setupListeners() {
        binding.fab.setOnClickListener {
            val intent = Intent(this, TextReaderActivity::class.java)
            startActivity(intent)
        }
        
        // Long press on FAB to clear all entries (for testing)
        binding.fab.setOnLongClickListener {
            clearAllEntries()
            true
        }
        
        // Double tap on item count to add test entry
        binding.itemCountText.setOnClickListener {
            addQuickTestEntry()
        }
        
        // Real-time search functionality
        binding.searchEditText.addTextChangedListener(object : android.text.TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: android.text.Editable?) {
                currentSearchQuery = s.toString()
                // The observeData() method will automatically handle filtering
                // based on currentSearchQuery when the LiveData updates
            }
        })
    }
    
    private fun clearAllEntries() {
        Thread {
            val allEntries = database.textEntryDao().getAllEntriesSync()
            allEntries.forEach { entry ->
                database.textEntryDao().deleteEntry(entry)
            }
            android.util.Log.d("MainActivity", "Cleared all entries")
        }.start()
    }
    
    private fun addQuickTestEntry() {
        Thread {
            val timestamp = System.currentTimeMillis()
            val testEntry = TextEntry(
                title = "Test Entry $timestamp",
                content = "This is test entry number $timestamp to verify database operations.",
                wordCount = 12,
                estimatedDuration = "1分钟"
            )
            
            try {
                val newId = database.textEntryDao().insertEntry(testEntry)
                android.util.Log.d("MainActivity", "Quick test: Inserted entry with ID: $newId")
                
                val totalCount = database.textEntryDao().getAllEntriesSync().size
                android.util.Log.d("MainActivity", "Quick test: Total entries now: $totalCount")
                
                runOnUiThread {
                    Toast.makeText(this, "Added test entry. Total: $totalCount", Toast.LENGTH_SHORT).show()
                    binding.debugText.text = "Debug: Quick test added entry. DB total: $totalCount"
                }
            } catch (e: Exception) {
                android.util.Log.e("MainActivity", "Quick test failed", e)
                runOnUiThread {
                    Toast.makeText(this, "Test failed: ${e.message}", Toast.LENGTH_SHORT).show()
                }
            }
        }.start()
    }
    
    
    
    private fun observeData() {
        database.textEntryDao().getAllEntries().observe(this, Observer { entries ->
            android.util.Log.d("MainActivity", "Received ${entries.size} entries from database")
            entries.forEach { entry ->
                android.util.Log.d("MainActivity", "Entry: ${entry.title} - ${entry.content.take(50)}")
            }
            
            // Update debug info
            val debugInfo = "Debug: LiveData updated with ${entries.size} entries. " +
                    "Titles: ${entries.take(3).map { it.title }}"
            binding.debugText.text = debugInfo
            
            // Apply current search filter if any
            if (currentSearchQuery.isBlank()) {
                // No search, show all entries
                adapter.submitList(entries)
                binding.itemCountText.text = "Items: ${entries.size}"
            } else {
                // Apply search filter
                val filteredEntries = entries.filter { entry ->
                    entry.title.contains(currentSearchQuery, ignoreCase = true) ||
                    entry.content.contains(currentSearchQuery, ignoreCase = true)
                }
                adapter.submitList(filteredEntries)
                binding.itemCountText.text = "Items: ${filteredEntries.size} (filtered)"
            }
        })
    }
    
    override fun onResume() {
        super.onResume()
        // Force refresh the data when returning to this activity
        refreshData()
    }
    
    private fun refreshData() {
        Thread {
            val allEntries = database.textEntryDao().getAllEntriesSync()
            android.util.Log.d("MainActivity", "Manual refresh found ${allEntries.size} entries")
            allEntries.forEach { entry ->
                android.util.Log.d("MainActivity", "Manual entry: ${entry.title}")
            }
        }.start()
    }
    
    private fun showDeleteConfirmationDialog(entry: TextEntry) {
        AlertDialog.Builder(this)
            .setTitle("删除确认")
            .setMessage("确定要删除 '${entry.title}' 吗？")
            .setPositiveButton("删除") { _, _ ->
                deleteEntry(entry)
            }
            .setNegativeButton("取消", null)
            .show()
    }
    
    private fun deleteEntry(entry: TextEntry) {
        Thread {
            try {
                // Delete audio file if exists
                entry.audioFilePath?.let { audioPath ->
                    val audioFile = java.io.File(audioPath)
                    if (audioFile.exists()) {
                        audioFile.delete()
                    }
                }
                
                // Delete from database
                database.textEntryDao().deleteEntry(entry)
                
                runOnUiThread {
                    Toast.makeText(this, "已删除 '${entry.title}'", Toast.LENGTH_SHORT).show()
                }
            } catch (e: Exception) {
                android.util.Log.e("MainActivity", "Error deleting entry", e)
                runOnUiThread {
                    Toast.makeText(this, "删除失败: ${e.message}", Toast.LENGTH_SHORT).show()
                }
            }
        }.start()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        audioPlayer.release()
    }
}