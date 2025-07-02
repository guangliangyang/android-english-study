package com.englishstudy.app.data

import androidx.room.*
import androidx.lifecycle.LiveData

@Dao
interface TextEntryDao {
    @Query("SELECT * FROM text_entries ORDER BY createdAt DESC")
    fun getAllEntries(): LiveData<List<TextEntry>>
    
    @Query("SELECT * FROM text_entries ORDER BY createdAt DESC")
    fun getAllEntriesSync(): List<TextEntry>

    @Query("SELECT * FROM text_entries WHERE title LIKE '%' || :query || '%' OR content LIKE '%' || :query || '%' ORDER BY createdAt DESC")
    fun searchEntries(query: String): LiveData<List<TextEntry>>

    @Query("SELECT * FROM text_entries WHERE id = :entryId")
    fun getEntryById(entryId: Long): TextEntry?

    @Insert
    fun insertEntry(entry: TextEntry): Long

    @Update
    fun updateEntry(entry: TextEntry): Int

    @Delete
    fun deleteEntry(entry: TextEntry): Int
}