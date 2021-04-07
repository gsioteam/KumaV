package com.qlp.kuma;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.Point;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;
import android.util.Log;
import android.util.LongSparseArray;
import android.view.Surface;

import androidx.annotation.NonNull;

import com.google.android.exoplayer2.Format;
import com.google.android.exoplayer2.Player;
import com.google.android.exoplayer2.SimpleExoPlayer;

import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.HashMap;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugins.videoplayer.VideoPlayerPlugin;

/** KumaPlayerPlugin */
public class KumaPlayerPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;

  private FlutterEngine flutterEngine;

  private HashMap<Long, OverlayPlayerView> overlayPlayers = new HashMap<>();

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    try {
      flutterEngine = flutterPluginBinding.getFlutterEngine();
      channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "kuma_player");
      channel.setMethodCallHandler(this);

      IntentFilter intentFilter = new IntentFilter();
      intentFilter.addAction(Intent.ACTION_SCREEN_OFF);
      flutterPluginBinding.getApplicationContext().registerReceiver(new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
          if (intent.getAction().equals(Intent.ACTION_SCREEN_OFF)) {
            for (Long key : overlayPlayers.keySet()) {
              OverlayPlayerView playerView = overlayPlayers.get(key);
              playerView.exoPlayer.pause();
            }
          }
        }
      }, intentFilter);
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "kuma_player");
    channel.setMethodCallHandler(new KumaPlayerPlugin());
  }

  Activity activity;
  final int ACTION_MANAGE_OVERLAY_PERMISSION_REQUEST_CODE = 0x992;

  VideoPlayerPlugin videoPlayerPlugin;

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    Class<VideoPlayerPlugin> videoPlayerPluginClass = VideoPlayerPlugin.class;
    VideoPlayerPlugin plugin = (VideoPlayerPlugin)flutterEngine.getPlugins().get(videoPlayerPluginClass);
    if (plugin != null) {
      videoPlayerPlugin = plugin;
    }
    if (call.method.equals("canOverlay")) {
      if (activity != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        result.success(Settings.canDrawOverlays(activity));
      } else {
        result.success(false);
      }
    } else if (call.method.equals("requestOverlayPermission")) {
      if (activity != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        Intent intent = new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:" + activity.getPackageName()));
        activity.startActivityForResult(intent, ACTION_MANAGE_OVERLAY_PERMISSION_REQUEST_CODE);
      }
      result.success(null);
    } else if (call.method.equals("requestOverlay")) {
      if (activity != null) {
        HashMap map = (HashMap) call.arguments;
        final Number textureId = (Number) map.get("textureId");
        try {
          Field field = videoPlayerPluginClass.getDeclaredField("videoPlayers");
          field.setAccessible(true);
          LongSparseArray videoPlayers = (LongSparseArray)field.get(videoPlayerPlugin);
          Object videoPlayer = videoPlayers.get(textureId.longValue());
          if (videoPlayer != null) {
            Class playerClass = videoPlayer.getClass();
            field = playerClass.getDeclaredField("exoPlayer");
            field.setAccessible(true);
            SimpleExoPlayer exoPlayer = (SimpleExoPlayer) field.get(videoPlayer);

            field = playerClass.getDeclaredField("surface");
            field.setAccessible(true);
            Surface surface = (Surface) field.get(videoPlayer);

            if (exoPlayer.getPlaybackState() == Player.STATE_READY) {
              OverlayPlayerView overlayPlayerView = new OverlayPlayerView(activity);
              overlayPlayerView.exoPlayer = exoPlayer;
              overlayPlayerView.flutterSurface = surface;
              overlayPlayerView.setOnEventListener(new OverlayPlayerView.OnEventListener() {
                @Override
                public void onDismiss() {
                  overlayPlayers.remove(textureId.longValue());
                }
              });
              overlayPlayers.put(textureId.longValue(), overlayPlayerView);
              overlayPlayerView.showOverlay();
            }
          }
        } catch (Exception e) {
          e.printStackTrace();
        }
      }
      result.success(null);
    } else if (call.method.equals("removeOverlay")) {
      HashMap map = (HashMap) call.arguments;
      Number textureId = (Number) map.get("textureId");
      boolean isPlaying = false;
      try {
        Field field = videoPlayerPluginClass.getDeclaredField("videoPlayers");
        field.setAccessible(true);
        LongSparseArray videoPlayers = (LongSparseArray) field.get(videoPlayerPlugin);
        Object videoPlayer = videoPlayers.get(textureId.longValue());
        if (videoPlayer != null) {
          OverlayPlayerView overlayPlayerView = overlayPlayers.get(textureId.longValue());
          if (overlayPlayerView != null) {
            overlayPlayerView.dismissOverlay();
            isPlaying = overlayPlayerView.exoPlayer.getPlayWhenReady();
            overlayPlayers.remove(textureId.longValue());
          }
        }
      } catch (Exception e) {
        e.printStackTrace();
      }
      result.success(isPlaying);
    } else {
      result.notImplemented();
    }
  }


  public static void onPause() {

  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
//    Class<VideoPlayerPlugin> videoPlayerPluginClass = VideoPlayerPlugin.class;
//    try {
//      Method method = videoPlayerPluginClass.getDeclaredMethod("onDestroy");
//      method.setAccessible(true);
//      method.invoke(videoPlayerPlugin);
//    } catch (Exception e) {
//      e.printStackTrace();
//    }
//    channel.setMethodCallHandler(null);
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    activity = binding.getActivity();
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {

  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

  }

  @Override
  public void onDetachedFromActivity() {
    activity = null;
  }
}
