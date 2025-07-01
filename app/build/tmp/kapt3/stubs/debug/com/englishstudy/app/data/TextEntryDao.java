package com.englishstudy.app.data;

import java.lang.System;

@androidx.room.Dao()
@kotlin.Metadata(mv = {1, 6, 0}, k = 1, d1 = {"\u00002\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\b\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\u0010 \n\u0002\b\u0003\n\u0002\u0010\t\n\u0002\b\u0003\n\u0002\u0010\u000e\n\u0002\b\u0002\bg\u0018\u00002\u00020\u0001J\u0010\u0010\u0002\u001a\u00020\u00032\u0006\u0010\u0004\u001a\u00020\u0005H\'J\u0014\u0010\u0006\u001a\u000e\u0012\n\u0012\b\u0012\u0004\u0012\u00020\u00050\b0\u0007H\'J\u000e\u0010\t\u001a\b\u0012\u0004\u0012\u00020\u00050\bH\'J\u0012\u0010\n\u001a\u0004\u0018\u00010\u00052\u0006\u0010\u000b\u001a\u00020\fH\'J\u0010\u0010\r\u001a\u00020\f2\u0006\u0010\u0004\u001a\u00020\u0005H\'J\u001c\u0010\u000e\u001a\u000e\u0012\n\u0012\b\u0012\u0004\u0012\u00020\u00050\b0\u00072\u0006\u0010\u000f\u001a\u00020\u0010H\'J\u0010\u0010\u0011\u001a\u00020\u00032\u0006\u0010\u0004\u001a\u00020\u0005H\'\u00a8\u0006\u0012"}, d2 = {"Lcom/englishstudy/app/data/TextEntryDao;", "", "deleteEntry", "", "entry", "Lcom/englishstudy/app/data/TextEntry;", "getAllEntries", "Landroidx/lifecycle/LiveData;", "", "getAllEntriesSync", "getEntryById", "id", "", "insertEntry", "searchEntries", "searchQuery", "", "updateEntry", "app_debug"})
public abstract interface TextEntryDao {
    
    @org.jetbrains.annotations.NotNull()
    @androidx.room.Query(value = "SELECT * FROM text_entries ORDER BY createdAt DESC")
    public abstract androidx.lifecycle.LiveData<java.util.List<com.englishstudy.app.data.TextEntry>> getAllEntries();
    
    @org.jetbrains.annotations.NotNull()
    @androidx.room.Query(value = "SELECT * FROM text_entries ORDER BY createdAt DESC")
    public abstract java.util.List<com.englishstudy.app.data.TextEntry> getAllEntriesSync();
    
    @org.jetbrains.annotations.NotNull()
    @androidx.room.Query(value = "SELECT * FROM text_entries WHERE title LIKE \'%\' || :searchQuery || \'%\' OR content LIKE \'%\' || :searchQuery || \'%\' ORDER BY createdAt DESC")
    public abstract androidx.lifecycle.LiveData<java.util.List<com.englishstudy.app.data.TextEntry>> searchEntries(@org.jetbrains.annotations.NotNull()
    java.lang.String searchQuery);
    
    @org.jetbrains.annotations.Nullable()
    @androidx.room.Query(value = "SELECT * FROM text_entries WHERE id = :id")
    public abstract com.englishstudy.app.data.TextEntry getEntryById(long id);
    
    @androidx.room.Insert()
    public abstract long insertEntry(@org.jetbrains.annotations.NotNull()
    com.englishstudy.app.data.TextEntry entry);
    
    @androidx.room.Update()
    public abstract int updateEntry(@org.jetbrains.annotations.NotNull()
    com.englishstudy.app.data.TextEntry entry);
    
    @androidx.room.Delete()
    public abstract int deleteEntry(@org.jetbrains.annotations.NotNull()
    com.englishstudy.app.data.TextEntry entry);
}