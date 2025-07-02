package com.englishstudy.app.data

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.ForeignKey
import androidx.room.Index

@Entity(
    tableName = "sentences",
    foreignKeys = [ForeignKey(
        entity = TextEntry::class,
        parentColumns = arrayOf("id"),
        childColumns = arrayOf("textEntryId"),
        onDelete = ForeignKey.CASCADE
    )],
    indices = [Index(value = ["textEntryId"])]
)
data class Sentence(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    
    val textEntryId: Long, // Foreign key to TextEntry
    
    val content: String, // The sentence text
    
    val orderIndex: Int, // Order of this sentence in the text
    
    val audioFilePath: String? = null, // Path to individual sentence audio file
    
    val duration: Long = 0, // Duration in milliseconds
    
    val createdAt: Long = System.currentTimeMillis()
)