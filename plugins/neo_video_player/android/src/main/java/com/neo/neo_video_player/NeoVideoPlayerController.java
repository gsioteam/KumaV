package com.neo.neo_video_player;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Rect;
import android.graphics.SurfaceTexture;
import android.net.Uri;
import android.os.Handler;
import android.view.Surface;
import android.view.SurfaceHolder;

import androidx.annotation.Nullable;

import com.google.android.exoplayer2.C;
import com.google.android.exoplayer2.MediaItem;
import com.google.android.exoplayer2.MediaMetadata;
import com.google.android.exoplayer2.PlaybackException;
import com.google.android.exoplayer2.PlaybackParameters;
import com.google.android.exoplayer2.Player;
import com.google.android.exoplayer2.SimpleExoPlayer;
import com.google.android.exoplayer2.Timeline;
import com.google.android.exoplayer2.audio.AudioAttributes;
import com.google.android.exoplayer2.device.DeviceInfo;
import com.google.android.exoplayer2.metadata.Metadata;
import com.google.android.exoplayer2.source.MediaSource;
import com.google.android.exoplayer2.source.ProgressiveMediaSource;
import com.google.android.exoplayer2.source.TrackGroupArray;
import com.google.android.exoplayer2.source.dash.DashMediaSource;
import com.google.android.exoplayer2.source.dash.DefaultDashChunkSource;
import com.google.android.exoplayer2.source.hls.HlsMediaSource;
import com.google.android.exoplayer2.source.smoothstreaming.DefaultSsChunkSource;
import com.google.android.exoplayer2.source.smoothstreaming.SsMediaSource;
import com.google.android.exoplayer2.text.Cue;
import com.google.android.exoplayer2.trackselection.TrackSelectionArray;
import com.google.android.exoplayer2.upstream.DataSource;
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory;
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource;
import com.google.android.exoplayer2.util.Util;
import com.google.android.exoplayer2.video.VideoSize;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.TextureRegistry;


public class NeoVideoPlayerController {
    private static final String FORMAT_SS = "ss";
    private static final String FORMAT_DASH = "dash";
    private static final String FORMAT_HLS = "hls";
    private static final String FORMAT_OTHER = "other";

    Player.Listener listener = new Player.Listener() {

        @Override
        public void onPlaybackStateChanged(int playbackState) {
            Map map = newData();
            map.put("isBuffering", playbackState == Player.STATE_BUFFERING);
            channel.invokeMethod("update", map);
            if (playbackState == Player.STATE_ENDED) {
                channel.invokeMethod("onStop", newData());
            }
        }

        @Override
        public void onIsPlayingChanged(boolean isPlaying) {
            Map map = newData();
            map.put("isPlaying", isPlaying);
            channel.invokeMethod("update", map);
        }

        @Override
        public void onRepeatModeChanged(int repeatMode) {
            Map map = newData();
            map.put("isLooping", repeatMode != Player.REPEAT_MODE_OFF);
            channel.invokeMethod("update", map);
        }

        @Override
        public void onPlayerError(PlaybackException error) {
            Map map = newData();
            map.put("errorDescription", error.getMessage());
            channel.invokeMethod("update", map);
        }

        @Override
        public void onPlaybackParametersChanged(PlaybackParameters playbackParameters) {
            Map map = newData();
            map.put("playbackSpeed", playbackParameters.speed);
            channel.invokeMethod("update", map);
        }

        @Override
        public void onVolumeChanged(float volume) {
            Map map = newData();
            map.put("volume", volume);
            channel.invokeMethod("update", map);
        }

        @Override
        public void onVideoSizeChanged(VideoSize videoSize) {
            Map map = newData();
            List list = new ArrayList();
            list.add((float)videoSize.width);
            list.add((float)videoSize.height);
            map.put("size", list);
            channel.invokeMethod("update", map);
        }

        @Override
        public void onTimelineChanged(Timeline timeline, int reason) {

        }

        @Override
        public void onMediaItemTransition(@Nullable MediaItem mediaItem, int reason) {

        }

        @Override
        public void onTracksChanged(TrackGroupArray trackGroups, TrackSelectionArray trackSelections) {

        }

        @Override
        public void onIsLoadingChanged(boolean isLoading) {

        }

        @Override
        public void onAvailableCommandsChanged(Player.Commands availableCommands) {

        }

        @Override
        public void onPlayWhenReadyChanged(boolean playWhenReady, int reason) {

        }

        @Override
        public void onPlaybackSuppressionReasonChanged(int playbackSuppressionReason) {

        }

        @Override
        public void onShuffleModeEnabledChanged(boolean shuffleModeEnabled) {

        }

        @Override
        public void onPlayerErrorChanged(@Nullable PlaybackException error) {

        }

        @Override
        public void onPositionDiscontinuity(Player.PositionInfo oldPosition, Player.PositionInfo newPosition, int reason) {

        }

        @Override
        public void onSeekForwardIncrementChanged(long seekForwardIncrementMs) {

        }

        @Override
        public void onSeekBackIncrementChanged(long seekBackIncrementMs) {

        }

        @Override
        public void onAudioSessionIdChanged(int audioSessionId) {

        }

        @Override
        public void onAudioAttributesChanged(AudioAttributes audioAttributes) {

        }

        @Override
        public void onSkipSilenceEnabledChanged(boolean skipSilenceEnabled) {

        }

        @Override
        public void onDeviceInfoChanged(DeviceInfo deviceInfo) {

        }

        @Override
        public void onDeviceVolumeChanged(int volume, boolean muted) {

        }

        @Override
        public void onEvents(Player player, Player.Events events) {

        }

        @Override
        public void onSurfaceSizeChanged(int width, int height) {

        }

        @Override
        public void onRenderedFirstFrame() {

        }

        @Override
        public void onCues(List<Cue> cues) {

        }

        @Override
        public void onMetadata(Metadata metadata) {

        }

        @Override
        public void onMediaMetadataChanged(MediaMetadata mediaMetadata) {

        }

        @Override
        public void onPlaylistMetadataChanged(MediaMetadata mediaMetadata) {

        }
    };

    class ProgressTracker implements Runnable {
        private Handler handler;
        boolean canceled = false;

        public ProgressTracker() {
            handler = new Handler();
            handler.post(this);
        }

        public void run() {
            if (canceled) return;
            long currentPosition = player.getCurrentPosition();
            long duration = player.getDuration();
            Map map = newData();
            map.put("duration", duration / 1000.0);
            map.put("position", currentPosition / 1000.0);
            channel.invokeMethod("update", map);
            handler.postDelayed(this, 500 /* ms */);
        }

        public void cancel() {
            canceled = true;
        }
    }


    NeoVideoPlayerController(Context context, Map params, TextureRegistry textureRegistry, MethodChannel channel) {
        id = params.get("id");
        player = new SimpleExoPlayer.Builder(context).build();
        String src = (String)params.get("src");
        Map httpHeaders = (Map)params.get("headers");
        String formatHint = (String)params.get("hint");

        this.channel = channel;

        Uri uri = Uri.parse(src);

        DataSource.Factory dataSourceFactory;
        if (isHTTP(uri)) {
            DefaultHttpDataSource.Factory httpDataSourceFactory =
                    new DefaultHttpDataSource.Factory()
                            .setUserAgent("ExoPlayer")
                            .setAllowCrossProtocolRedirects(true);

            if (httpHeaders != null && !httpHeaders.isEmpty()) {
                httpDataSourceFactory.setDefaultRequestProperties(httpHeaders);
            }
            dataSourceFactory = httpDataSourceFactory;
        } else {
            dataSourceFactory = new DefaultDataSourceFactory(context, "ExoPlayer");
        }

        MediaSource mediaSource = buildMediaSource(uri, dataSourceFactory, formatHint, context);
        player.setMediaSource(mediaSource);
        player.prepare();

        surfaceTextureEntry = textureRegistry.createSurfaceTexture();
        surfaceTexture = surfaceTextureEntry.surfaceTexture();
        surfaceTexture.setOnFrameAvailableListener(new SurfaceTexture.OnFrameAvailableListener() {
            @Override
            public void onFrameAvailable(SurfaceTexture surfaceTexture) {
                for (OnFrameListener listener : onFrameListeners) {
                    listener.onFrame();
                }
            }
        });
        Surface surface = new Surface(surfaceTexture);
        player.setVideoSurface(surface);

        player.addListener(listener);

        progressTracker = new ProgressTracker();
    }

    private static boolean isHTTP(Uri uri) {
        if (uri == null || uri.getScheme() == null) {
            return false;
        }
        String scheme = uri.getScheme();
        return scheme.equals("http") || scheme.equals("https");
    }

    private MediaSource buildMediaSource(
            Uri uri, DataSource.Factory mediaDataSourceFactory, String formatHint, Context context) {
        int type;
        if (formatHint == null) {
            type = Util.inferContentType(uri.getLastPathSegment());
        } else {
            switch (formatHint) {
                case FORMAT_SS:
                    type = C.TYPE_SS;
                    break;
                case FORMAT_DASH:
                    type = C.TYPE_DASH;
                    break;
                case FORMAT_HLS:
                    type = C.TYPE_HLS;
                    break;
                case FORMAT_OTHER:
                    type = C.TYPE_OTHER;
                    break;
                default:
                    type = -1;
                    break;
            }
        }
        switch (type) {
            case C.TYPE_SS:
                return new SsMediaSource.Factory(
                        new DefaultSsChunkSource.Factory(mediaDataSourceFactory),
                        new DefaultDataSourceFactory(context, null, mediaDataSourceFactory))
                        .createMediaSource(MediaItem.fromUri(uri));
            case C.TYPE_DASH:
                return new DashMediaSource.Factory(
                        new DefaultDashChunkSource.Factory(mediaDataSourceFactory),
                        new DefaultDataSourceFactory(context, null, mediaDataSourceFactory))
                        .createMediaSource(MediaItem.fromUri(uri));
            case C.TYPE_HLS:
                return new HlsMediaSource.Factory(mediaDataSourceFactory)
                        .createMediaSource(MediaItem.fromUri(uri));
            case C.TYPE_OTHER:
                return new ProgressiveMediaSource.Factory(mediaDataSourceFactory)
                        .createMediaSource(MediaItem.fromUri(uri));
            default:
            {
                throw new IllegalStateException("Unsupported type: " + type);
            }
        }
    }

    public void dispose() {
        progressTracker.cancel();
        surfaceTextureEntry.release();
        player.release();
    }

    Object id;
    SimpleExoPlayer player;
    MethodChannel channel;

    ProgressTracker progressTracker;

    TextureRegistry.SurfaceTextureEntry surfaceTextureEntry;
    SurfaceTexture surfaceTexture;

    public void setLooping(boolean looping) {
        player.setRepeatMode(looping ? Player.REPEAT_MODE_ONE : Player.REPEAT_MODE_OFF);
    }

    Map newData() {
        Map map = new HashMap();
        map.put("id", id);
        return map;
    }

    public SurfaceTexture getSurfaceTexture() {
        return surfaceTexture;
    }

    public interface OnFrameListener {
        void onFrame();
    }
    List<OnFrameListener> onFrameListeners = new ArrayList<>();

    void addOnFrameListener(OnFrameListener listener) {
        onFrameListeners.add(listener);
    }

    void removeOnFrameListener(OnFrameListener listener) {
        onFrameListeners.remove(listener);
    }

    public boolean canPictureInPicture() {
        return false;
    }
    
    public void startPictureInPicture() {
    }

    public void stopPictureInPicture() {

    }

    public void setAutoPip(boolean autoPip) {
        
    }
}
