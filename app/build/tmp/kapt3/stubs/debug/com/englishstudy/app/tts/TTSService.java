package com.englishstudy.app.tts;

import java.lang.System;

@kotlin.Metadata(mv = {1, 6, 0}, k = 1, d1 = {"\u0000B\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u000b\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0002\n\u0000\n\u0002\u0010 \n\u0002\u0010\u000e\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\u0010\b\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0000\u0018\u00002\u00020\u0001B\r\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0004J\u0006\u0010\t\u001a\u00020\nJF\u0010\u000b\u001a\n\u0012\u0006\u0012\u0004\u0018\u00010\r0\f2\f\u0010\u000e\u001a\b\u0012\u0004\u0012\u00020\r0\f2\u0006\u0010\u000f\u001a\u00020\r2 \b\u0002\u0010\u0010\u001a\u001a\u0012\u0004\u0012\u00020\u0012\u0012\u0004\u0012\u00020\u0012\u0012\u0004\u0012\u00020\r\u0012\u0004\u0012\u00020\n0\u0011J.\u0010\u0013\u001a\u0004\u0018\u00010\r2\u0006\u0010\u0014\u001a\u00020\r2\u0006\u0010\u0015\u001a\u00020\r2\u0014\b\u0002\u0010\u0010\u001a\u000e\u0012\u0004\u0012\u00020\r\u0012\u0004\u0012\u00020\n0\u0016R\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0005\u001a\u00020\u0006X\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u0010\u0010\u0007\u001a\u0004\u0018\u00010\bX\u0082\u000e\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u0017"}, d2 = {"Lcom/englishstudy/app/tts/TTSService;", "", "context", "Landroid/content/Context;", "(Landroid/content/Context;)V", "isInitialized", "", "textToSpeech", "Landroid/speech/tts/TextToSpeech;", "close", "", "generateSentenceAudio", "", "", "sentences", "baseFileName", "onProgress", "Lkotlin/Function3;", "", "generateSpeech", "text", "outputFileName", "Lkotlin/Function1;", "app_debug"})
public final class TTSService {
    private final android.content.Context context = null;
    private android.speech.tts.TextToSpeech textToSpeech;
    private boolean isInitialized = false;
    
    public TTSService(@org.jetbrains.annotations.NotNull()
    android.content.Context context) {
        super();
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String generateSpeech(@org.jetbrains.annotations.NotNull()
    java.lang.String text, @org.jetbrains.annotations.NotNull()
    java.lang.String outputFileName, @org.jetbrains.annotations.NotNull()
    kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> onProgress) {
        return null;
    }
    
    /**
     * Generate audio for multiple sentences
     * @param sentences List of sentence texts
     * @param baseFileName Base name for audio files (will append sentence index)
     * @param onProgress Progress callback with (currentIndex, totalCount, message)
     * @return List of generated audio file paths
     */
    @org.jetbrains.annotations.NotNull()
    public final java.util.List<java.lang.String> generateSentenceAudio(@org.jetbrains.annotations.NotNull()
    java.util.List<java.lang.String> sentences, @org.jetbrains.annotations.NotNull()
    java.lang.String baseFileName, @org.jetbrains.annotations.NotNull()
    kotlin.jvm.functions.Function3<? super java.lang.Integer, ? super java.lang.Integer, ? super java.lang.String, kotlin.Unit> onProgress) {
        return null;
    }
    
    public final void close() {
    }
}