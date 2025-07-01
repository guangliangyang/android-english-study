package com.englishstudy.app.data

import androidx.lifecycle.LiveData
import androidx.room.*

@Dao
interface SentenceDao {
    
    @Query("SELECT * FROM sentences WHERE textEntryId = :textEntryId ORDER BY orderIndex ASC")
    fun getSentencesByTextEntryId(textEntryId: Long): LiveData<List<Sentence>>
    
    @Query("SELECT * FROM sentences WHERE textEntryId = :textEntryId ORDER BY orderIndex ASC")
    fun getSentencesByTextEntryIdSync(textEntryId: Long): List<Sentence>
    
    @Query("SELECT * FROM sentences WHERE id = :sentenceId")
    fun getSentenceById(sentenceId: Long): Sentence?
    
    @Insert
    fun insertSentence(sentence: Sentence): Long
    
    @Insert
    fun insertSentences(sentences: List<Sentence>): List<Long>
    
    @Update
    fun updateSentence(sentence: Sentence)
    
    @Delete
    fun deleteSentence(sentence: Sentence)
    
    @Query("DELETE FROM sentences WHERE textEntryId = :textEntryId")
    fun deleteSentencesByTextEntryId(textEntryId: Long)
    
    @Query("SELECT COUNT(*) FROM sentences WHERE textEntryId = :textEntryId")
    fun getSentenceCountForTextEntry(textEntryId: Long): Int
    
    @Query("SELECT * FROM sentences WHERE textEntryId = :textEntryId AND audioFilePath IS NULL ORDER BY orderIndex ASC")
    fun getSentencesWithoutAudio(textEntryId: Long): List<Sentence>
}