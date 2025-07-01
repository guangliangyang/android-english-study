package com.englishstudy.app;

import java.lang.System;

@kotlin.Metadata(mv = {1, 6, 0}, k = 1, d1 = {"\u0000L\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\t\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\b\n\u0000\n\u0002\u0010\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0006\u0018\u00002\u00020\u0001B\u0005\u00a2\u0006\u0002\u0010\u0002J\u0010\u0010\u000f\u001a\u00020\u00102\u0006\u0010\u0011\u001a\u00020\u0012H\u0002J\b\u0010\u0013\u001a\u00020\u0014H\u0002J\b\u0010\u0015\u001a\u00020\u0014H\u0002J\u0012\u0010\u0016\u001a\u00020\u00142\b\u0010\u0017\u001a\u0004\u0018\u00010\u0018H\u0014J\b\u0010\u0019\u001a\u00020\u0014H\u0014J\b\u0010\u001a\u001a\u00020\u0014H\u0002J\b\u0010\u001b\u001a\u00020\u0014H\u0002J\b\u0010\u001c\u001a\u00020\u0014H\u0002J\b\u0010\u001d\u001a\u00020\u0014H\u0002R\u000e\u0010\u0003\u001a\u00020\u0004X\u0082.\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0005\u001a\u00020\u0006X\u0082.\u00a2\u0006\u0002\n\u0000R\u0010\u0010\u0007\u001a\u0004\u0018\u00010\bX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010\t\u001a\u00020\nX\u0082.\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u000b\u001a\u00020\fX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010\r\u001a\u00020\u000eX\u0082.\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u001e"}, d2 = {"Lcom/englishstudy/app/TextReaderActivity;", "Landroidx/appcompat/app/AppCompatActivity;", "()V", "audioPlayer", "Lcom/englishstudy/app/utils/AudioPlayer;", "binding", "Lcom/englishstudy/app/databinding/ActivityTextReaderBinding;", "currentEntry", "Lcom/englishstudy/app/data/TextEntry;", "database", "Lcom/englishstudy/app/data/AppDatabase;", "entryId", "", "ttsService", "Lcom/englishstudy/app/tts/TTSService;", "estimateDuration", "", "wordCount", "", "generateAudio", "", "loadEntry", "onCreate", "savedInstanceState", "Landroid/os/Bundle;", "onDestroy", "playAudio", "saveAndFinish", "setupListeners", "setupSpeedControl", "app_debug"})
public final class TextReaderActivity extends androidx.appcompat.app.AppCompatActivity {
    private com.englishstudy.app.databinding.ActivityTextReaderBinding binding;
    private com.englishstudy.app.data.AppDatabase database;
    private com.englishstudy.app.tts.TTSService ttsService;
    private com.englishstudy.app.utils.AudioPlayer audioPlayer;
    private com.englishstudy.app.data.TextEntry currentEntry;
    private long entryId = -1L;
    
    public TextReaderActivity() {
        super();
    }
    
    @java.lang.Override()
    protected void onCreate(@org.jetbrains.annotations.Nullable()
    android.os.Bundle savedInstanceState) {
    }
    
    private final void setupListeners() {
    }
    
    private final void setupSpeedControl() {
    }
    
    private final void loadEntry() {
    }
    
    private final void saveAndFinish() {
    }
    
    private final void generateAudio() {
    }
    
    private final void playAudio() {
    }
    
    private final java.lang.String estimateDuration(int wordCount) {
        return null;
    }
    
    @java.lang.Override()
    protected void onDestroy() {
    }
}