package com.englishstudy.app;

import java.lang.System;

@kotlin.Metadata(mv = {1, 6, 0}, k = 1, d1 = {"\u0000^\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\b\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000b\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0002\n\u0002\b\u0002\n\u0002\u0010\t\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u000b\u0018\u00002\u00020\u0001:\u0001(B\u0005\u00a2\u0006\u0002\u0010\u0002J\b\u0010\u0016\u001a\u00020\u0017H\u0002J\u0010\u0010\u0018\u001a\u00020\u00172\u0006\u0010\u0019\u001a\u00020\u001aH\u0002J\b\u0010\u001b\u001a\u00020\u0017H\u0002J\u0012\u0010\u001c\u001a\u00020\u00172\b\u0010\u001d\u001a\u0004\u0018\u00010\u001eH\u0014J\b\u0010\u001f\u001a\u00020\u0017H\u0014J\b\u0010 \u001a\u00020\u0017H\u0002J\b\u0010!\u001a\u00020\u0017H\u0002J\u0010\u0010\"\u001a\u00020\u00172\u0006\u0010#\u001a\u00020\u0010H\u0002J\b\u0010$\u001a\u00020\u0017H\u0002J\b\u0010%\u001a\u00020\u0017H\u0002J\b\u0010&\u001a\u00020\u0017H\u0002J\b\u0010\'\u001a\u00020\u0017H\u0002R\u000e\u0010\u0003\u001a\u00020\u0004X\u0082.\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0005\u001a\u00020\u0006X\u0082.\u00a2\u0006\u0002\n\u0000R\u0010\u0010\u0007\u001a\u0004\u0018\u00010\bX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010\t\u001a\u00020\nX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u000b\u001a\u00020\fX\u0082.\u00a2\u0006\u0002\n\u0000R\u000e\u0010\r\u001a\u00020\u000eX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u000f\u001a\u00020\u0010X\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0011\u001a\u00020\u0012X\u0082.\u00a2\u0006\u0002\n\u0000R\u0014\u0010\u0013\u001a\b\u0012\u0004\u0012\u00020\u00150\u0014X\u0082\u000e\u00a2\u0006\u0002\n\u0000\u00a8\u0006)"}, d2 = {"Lcom/englishstudy/app/ReadingActivity;", "Landroidx/appcompat/app/AppCompatActivity;", "()V", "audioPlayer", "Lcom/englishstudy/app/utils/AudioPlayer;", "binding", "Lcom/englishstudy/app/databinding/ActivityReadingBinding;", "currentEntry", "Lcom/englishstudy/app/data/TextEntry;", "currentSentenceIndex", "", "database", "Lcom/englishstudy/app/data/AppDatabase;", "isPlaying", "", "readingMode", "Lcom/englishstudy/app/ReadingActivity$ReadingMode;", "sentenceAdapter", "Lcom/englishstudy/app/adapter/SentenceAdapter;", "sentences", "", "Lcom/englishstudy/app/data/Sentence;", "adjustFontSize", "", "loadEntry", "entryId", "", "nextSentence", "onCreate", "savedInstanceState", "Landroid/os/Bundle;", "onDestroy", "playCurrentSentence", "previousSentence", "setReadingMode", "mode", "setupListeners", "setupRecyclerView", "togglePlayPause", "updateProgress", "ReadingMode", "app_debug"})
public final class ReadingActivity extends androidx.appcompat.app.AppCompatActivity {
    private com.englishstudy.app.databinding.ActivityReadingBinding binding;
    private com.englishstudy.app.data.AppDatabase database;
    private com.englishstudy.app.utils.AudioPlayer audioPlayer;
    private com.englishstudy.app.data.TextEntry currentEntry;
    private java.util.List<com.englishstudy.app.data.Sentence> sentences;
    private int currentSentenceIndex = 0;
    private com.englishstudy.app.ReadingActivity.ReadingMode readingMode = com.englishstudy.app.ReadingActivity.ReadingMode.SEQUENTIAL;
    private boolean isPlaying = false;
    private com.englishstudy.app.adapter.SentenceAdapter sentenceAdapter;
    
    public ReadingActivity() {
        super();
    }
    
    @java.lang.Override()
    protected void onCreate(@org.jetbrains.annotations.Nullable()
    android.os.Bundle savedInstanceState) {
    }
    
    private final void setupListeners() {
    }
    
    private final void loadEntry(long entryId) {
    }
    
    private final void setupRecyclerView() {
    }
    
    private final void updateProgress() {
    }
    
    private final void setReadingMode(com.englishstudy.app.ReadingActivity.ReadingMode mode) {
    }
    
    private final void previousSentence() {
    }
    
    private final void nextSentence() {
    }
    
    private final void playCurrentSentence() {
    }
    
    private final void togglePlayPause() {
    }
    
    private final void adjustFontSize() {
    }
    
    @java.lang.Override()
    protected void onDestroy() {
    }
    
    @kotlin.Metadata(mv = {1, 6, 0}, k = 1, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0010\u0010\n\u0002\b\u0005\b\u0086\u0001\u0018\u00002\b\u0012\u0004\u0012\u00020\u00000\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002j\u0002\b\u0003j\u0002\b\u0004j\u0002\b\u0005\u00a8\u0006\u0006"}, d2 = {"Lcom/englishstudy/app/ReadingActivity$ReadingMode;", "", "(Ljava/lang/String;I)V", "SEQUENTIAL", "POINT_READ", "REPEAT", "app_debug"})
    public static enum ReadingMode {
        /*public static final*/ SEQUENTIAL /* = new SEQUENTIAL() */,
        /*public static final*/ POINT_READ /* = new POINT_READ() */,
        /*public static final*/ REPEAT /* = new REPEAT() */;
        
        ReadingMode() {
        }
    }
}