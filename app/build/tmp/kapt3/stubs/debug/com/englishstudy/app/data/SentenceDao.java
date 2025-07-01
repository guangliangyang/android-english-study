package com.englishstudy.app.data;

import java.lang.System;

@androidx.room.Dao()
@kotlin.Metadata(mv = {1, 6, 0}, k = 1, d1 = {"\u00002\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\t\n\u0002\b\u0003\n\u0002\u0010\b\n\u0000\n\u0002\u0018\u0002\n\u0002\u0010 \n\u0002\b\u0007\bg\u0018\u00002\u00020\u0001J\u0010\u0010\u0002\u001a\u00020\u00032\u0006\u0010\u0004\u001a\u00020\u0005H\'J\u0010\u0010\u0006\u001a\u00020\u00032\u0006\u0010\u0007\u001a\u00020\bH\'J\u0012\u0010\t\u001a\u0004\u0018\u00010\u00052\u0006\u0010\n\u001a\u00020\bH\'J\u0010\u0010\u000b\u001a\u00020\f2\u0006\u0010\u0007\u001a\u00020\bH\'J\u001c\u0010\r\u001a\u000e\u0012\n\u0012\b\u0012\u0004\u0012\u00020\u00050\u000f0\u000e2\u0006\u0010\u0007\u001a\u00020\bH\'J\u0016\u0010\u0010\u001a\b\u0012\u0004\u0012\u00020\u00050\u000f2\u0006\u0010\u0007\u001a\u00020\bH\'J\u0016\u0010\u0011\u001a\b\u0012\u0004\u0012\u00020\u00050\u000f2\u0006\u0010\u0007\u001a\u00020\bH\'J\u0010\u0010\u0012\u001a\u00020\b2\u0006\u0010\u0004\u001a\u00020\u0005H\'J\u001c\u0010\u0013\u001a\b\u0012\u0004\u0012\u00020\b0\u000f2\f\u0010\u0014\u001a\b\u0012\u0004\u0012\u00020\u00050\u000fH\'J\u0010\u0010\u0015\u001a\u00020\u00032\u0006\u0010\u0004\u001a\u00020\u0005H\'\u00a8\u0006\u0016"}, d2 = {"Lcom/englishstudy/app/data/SentenceDao;", "", "deleteSentence", "", "sentence", "Lcom/englishstudy/app/data/Sentence;", "deleteSentencesByTextEntryId", "textEntryId", "", "getSentenceById", "sentenceId", "getSentenceCountForTextEntry", "", "getSentencesByTextEntryId", "Landroidx/lifecycle/LiveData;", "", "getSentencesByTextEntryIdSync", "getSentencesWithoutAudio", "insertSentence", "insertSentences", "sentences", "updateSentence", "app_debug"})
public abstract interface SentenceDao {
    
    @org.jetbrains.annotations.NotNull()
    @androidx.room.Query(value = "SELECT * FROM sentences WHERE textEntryId = :textEntryId ORDER BY orderIndex ASC")
    public abstract androidx.lifecycle.LiveData<java.util.List<com.englishstudy.app.data.Sentence>> getSentencesByTextEntryId(long textEntryId);
    
    @org.jetbrains.annotations.NotNull()
    @androidx.room.Query(value = "SELECT * FROM sentences WHERE textEntryId = :textEntryId ORDER BY orderIndex ASC")
    public abstract java.util.List<com.englishstudy.app.data.Sentence> getSentencesByTextEntryIdSync(long textEntryId);
    
    @org.jetbrains.annotations.Nullable()
    @androidx.room.Query(value = "SELECT * FROM sentences WHERE id = :sentenceId")
    public abstract com.englishstudy.app.data.Sentence getSentenceById(long sentenceId);
    
    @androidx.room.Insert()
    public abstract long insertSentence(@org.jetbrains.annotations.NotNull()
    com.englishstudy.app.data.Sentence sentence);
    
    @org.jetbrains.annotations.NotNull()
    @androidx.room.Insert()
    public abstract java.util.List<java.lang.Long> insertSentences(@org.jetbrains.annotations.NotNull()
    java.util.List<com.englishstudy.app.data.Sentence> sentences);
    
    @androidx.room.Update()
    public abstract void updateSentence(@org.jetbrains.annotations.NotNull()
    com.englishstudy.app.data.Sentence sentence);
    
    @androidx.room.Delete()
    public abstract void deleteSentence(@org.jetbrains.annotations.NotNull()
    com.englishstudy.app.data.Sentence sentence);
    
    @androidx.room.Query(value = "DELETE FROM sentences WHERE textEntryId = :textEntryId")
    public abstract void deleteSentencesByTextEntryId(long textEntryId);
    
    @androidx.room.Query(value = "SELECT COUNT(*) FROM sentences WHERE textEntryId = :textEntryId")
    public abstract int getSentenceCountForTextEntry(long textEntryId);
    
    @org.jetbrains.annotations.NotNull()
    @androidx.room.Query(value = "SELECT * FROM sentences WHERE textEntryId = :textEntryId AND audioFilePath IS NULL ORDER BY orderIndex ASC")
    public abstract java.util.List<com.englishstudy.app.data.Sentence> getSentencesWithoutAudio(long textEntryId);
}