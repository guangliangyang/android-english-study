package com.englishstudy.app.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "text_entries")
data class TextEntry(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val title: String,
    val content: String,
    val audioFilePath: String? = null,
    val wordCount: Int,
    val estimatedDuration: String? = null,
    val createdAt: Long = System.currentTimeMillis()
)