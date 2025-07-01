package com.englishstudy.app.utils;

import java.lang.System;

@kotlin.Metadata(mv = {1, 6, 0}, k = 1, d1 = {"\u00002\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u000b\n\u0000\n\u0002\u0010\u0007\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0004\n\u0002\u0010\u0002\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0002\b\u0006\u0018\u00002\u00020\u0001B\u0005\u00a2\u0006\u0002\u0010\u0002J\u0006\u0010\u000e\u001a\u00020\u000fJ\u0018\u0010\u0010\u001a\u00020\u000f2\u0006\u0010\u0011\u001a\u00020\u00122\b\b\u0002\u0010\u0013\u001a\u00020\u0006J\u0006\u0010\u0014\u001a\u00020\u000fJ\u0006\u0010\u0015\u001a\u00020\u000fJ\u000e\u0010\u0016\u001a\u00020\u000f2\u0006\u0010\u0013\u001a\u00020\u0006J\u0006\u0010\u0017\u001a\u00020\u000fR\u000e\u0010\u0003\u001a\u00020\u0004X\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0005\u001a\u00020\u0006X\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u0011\u0010\u0007\u001a\u00020\u00048F\u00a2\u0006\u0006\u001a\u0004\b\u0007\u0010\bR\u0010\u0010\t\u001a\u0004\u0018\u00010\nX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u0011\u0010\u000b\u001a\u00020\u00068F\u00a2\u0006\u0006\u001a\u0004\b\f\u0010\r\u00a8\u0006\u0018"}, d2 = {"Lcom/englishstudy/app/utils/AudioPlayer;", "", "()V", "_isPlaying", "", "_playbackSpeed", "", "isPlaying", "()Z", "mediaPlayer", "Landroid/media/MediaPlayer;", "playbackSpeed", "getPlaybackSpeed", "()F", "pauseAudio", "", "playAudio", "audioFilePath", "", "speed", "release", "resumeAudio", "setPlaybackSpeed", "stopAudio", "app_debug"})
public final class AudioPlayer {
    private android.media.MediaPlayer mediaPlayer;
    private boolean _isPlaying = false;
    private float _playbackSpeed = 1.0F;
    
    public AudioPlayer() {
        super();
    }
    
    public final boolean isPlaying() {
        return false;
    }
    
    public final float getPlaybackSpeed() {
        return 0.0F;
    }
    
    public final void playAudio(@org.jetbrains.annotations.NotNull()
    java.lang.String audioFilePath, float speed) {
    }
    
    public final void pauseAudio() {
    }
    
    public final void resumeAudio() {
    }
    
    public final void stopAudio() {
    }
    
    public final void setPlaybackSpeed(float speed) {
    }
    
    public final void release() {
    }
}