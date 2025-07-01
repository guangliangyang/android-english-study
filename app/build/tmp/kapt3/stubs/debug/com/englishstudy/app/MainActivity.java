package com.englishstudy.app;

import java.lang.System;

@kotlin.Metadata(mv = {1, 6, 0}, k = 1, d1 = {"\u0000B\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0007\u0018\u00002\u00020\u0001B\u0005\u00a2\u0006\u0002\u0010\u0002J\b\u0010\r\u001a\u00020\u000eH\u0002J\b\u0010\u000f\u001a\u00020\u000eH\u0002J\u0010\u0010\u0010\u001a\u00020\u000e2\u0006\u0010\u0011\u001a\u00020\u0012H\u0002J\b\u0010\u0013\u001a\u00020\u000eH\u0002J\u0012\u0010\u0014\u001a\u00020\u000e2\b\u0010\u0015\u001a\u0004\u0018\u00010\u0016H\u0014J\b\u0010\u0017\u001a\u00020\u000eH\u0014J\b\u0010\u0018\u001a\u00020\u000eH\u0014J\b\u0010\u0019\u001a\u00020\u000eH\u0002J\b\u0010\u001a\u001a\u00020\u000eH\u0002J\b\u0010\u001b\u001a\u00020\u000eH\u0002J\u0010\u0010\u001c\u001a\u00020\u000e2\u0006\u0010\u0011\u001a\u00020\u0012H\u0002R\u000e\u0010\u0003\u001a\u00020\u0004X\u0082.\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0005\u001a\u00020\u0006X\u0082.\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0007\u001a\u00020\bX\u0082.\u00a2\u0006\u0002\n\u0000R\u000e\u0010\t\u001a\u00020\nX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u000b\u001a\u00020\fX\u0082.\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u001d"}, d2 = {"Lcom/englishstudy/app/MainActivity;", "Landroidx/appcompat/app/AppCompatActivity;", "()V", "adapter", "Lcom/englishstudy/app/adapter/TextEntryAdapter;", "audioPlayer", "Lcom/englishstudy/app/utils/AudioPlayer;", "binding", "Lcom/englishstudy/app/databinding/ActivityMainBinding;", "currentSearchQuery", "", "database", "Lcom/englishstudy/app/data/AppDatabase;", "addQuickTestEntry", "", "clearAllEntries", "deleteEntry", "entry", "Lcom/englishstudy/app/data/TextEntry;", "observeData", "onCreate", "savedInstanceState", "Landroid/os/Bundle;", "onDestroy", "onResume", "refreshData", "setupListeners", "setupRecyclerView", "showDeleteConfirmationDialog", "app_debug"})
public final class MainActivity extends androidx.appcompat.app.AppCompatActivity {
    private com.englishstudy.app.databinding.ActivityMainBinding binding;
    private com.englishstudy.app.data.AppDatabase database;
    private com.englishstudy.app.adapter.TextEntryAdapter adapter;
    private com.englishstudy.app.utils.AudioPlayer audioPlayer;
    private java.lang.String currentSearchQuery = "";
    
    public MainActivity() {
        super();
    }
    
    @java.lang.Override()
    protected void onCreate(@org.jetbrains.annotations.Nullable()
    android.os.Bundle savedInstanceState) {
    }
    
    private final void setupRecyclerView() {
    }
    
    private final void setupListeners() {
    }
    
    private final void clearAllEntries() {
    }
    
    private final void addQuickTestEntry() {
    }
    
    private final void observeData() {
    }
    
    @java.lang.Override()
    protected void onResume() {
    }
    
    private final void refreshData() {
    }
    
    private final void showDeleteConfirmationDialog(com.englishstudy.app.data.TextEntry entry) {
    }
    
    private final void deleteEntry(com.englishstudy.app.data.TextEntry entry) {
    }
    
    @java.lang.Override()
    protected void onDestroy() {
    }
}