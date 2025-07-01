package com.englishstudy.app.data

import androidx.room.*
import androidx.lifecycle.LiveData

@Dao
interface TextEntryDao {
    @Query("SELECT * FROM text_entries ORDER BY createdAt DESC")
    fun getAllEntries(): LiveData<List<TextEntry>>
    
    @Query("SELECT * FROM text_entries ORDER BY createdAt DESC")
    fun getAllEntriesSync(): List<TextEntry>

    @Query("SELECT * FROM text_entries WHERE title LIKE '%' || :searchQuery || '%' OR content LIKE '%' || :searchQuery || '%' ORDER BY createdAt DESC")
    fun searchEntries(searchQuery: String): LiveData<List<TextEntry>>

    @Query("SELECT * FROM text_entries WHERE id = :id")
    fun getEntryById(id: Long): TextEntry?

    @Insert
    fun insertEntry(entry: TextEntry): Long

    @Update
    fun updateEntry(entry: TextEntry): Int

    @Delete
    fun deleteEntry(entry: TextEntry): Int
}