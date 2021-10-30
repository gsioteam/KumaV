package com.neo.neo_video_player;

import android.content.Context;

import androidx.annotation.NonNull;

import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MessageCodec;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;
import io.flutter.view.TextureRegistry;

/** NeoVideoPlayerPlugin */
public class NeoVideoPlayerPlugin implements FlutterPlugin, MethodCallHandler {

  private Context context;
  private MethodChannel channel;
  private Map<Object, NeoVideoPlayerController> controllers = new HashMap<>();
  private TextureRegistry textureRegistry;
  
  class NeoPlayerViewFactory extends PlatformViewFactory {
    public NeoPlayerViewFactory() {
      super(StandardMessageCodec.INSTANCE);
    }

    @Override
    public PlatformView create(Context context, int viewId, Object args) {
      Map data = (Map)args;
      NeoVideoPlayerController controller = controllers.get(data.get("id"));
      return new NeoVideoPlayer(context, controller, data);
    }
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "neo_player");
    channel.setMethodCallHandler(this);

    context = flutterPluginBinding.getApplicationContext();
    textureRegistry = flutterPluginBinding.getTextureRegistry();
    
    flutterPluginBinding.getPlatformViewRegistry().registerViewFactory(
            "neo_player_view",
            new NeoPlayerViewFactory());
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case "init": {
        Object id = call.argument("id");
        NeoVideoPlayerController controller = new NeoVideoPlayerController(
                context,
                (Map)call.arguments,
                textureRegistry,
                channel);
        controllers.put(id, controller);
        result.success(null);
        break;
      }
      case "dispose": {
        Object id = call.argument("id");
        NeoVideoPlayerController controller = controllers.remove(id);
        if (controller != null) {
          controller.dispose();
        }
        result.success(null);
        break;
      }
      case "play": {
        Object id = call.argument("id");
        NeoVideoPlayerController controller = controllers.get(id);
        if (controller != null) {
          controller.player.play();
        }
        result.success(null);
        break;
      }
      case "pause": {
        Object id = call.argument("id");
        NeoVideoPlayerController controller = controllers.get(id);
        if (controller != null) {
          controller.player.pause();
        }
        result.success(null);
        break;
      }
      case "seek": {
        Object id = call.argument("id");
        NeoVideoPlayerController controller = controllers.get(id);
        if (controller != null) {
          Number time = call.argument("time");
          controller.player.seekTo(0, time.longValue());
        }
        result.success(null);
        break;
      }
      case "loop": {
        Object id = call.argument("id");
        NeoVideoPlayerController controller = controllers.get(id);
        if (controller != null) {
          Boolean loop = call.argument("loop");
          controller.setLooping(loop);
        }
        result.success(null);
        break;
      }
      case "canPictureInPicture": {
        Object id = call.argument("id");
        NeoVideoPlayerController controller = controllers.get(id);
        if (controller != null) {
          result.success(controller.canPictureInPicture());
        } else {
          result.success(false);
        }
        break;
      }
      case "startPictureInPicture": {
        Object id = call.argument("id");
        NeoVideoPlayerController controller = controllers.get(id);
        if (controller != null) {
          controller.startPictureInPicture();
        }
        result.success(null);
        break;
      }
      case "stopPictureInPicture": {
        Object id = call.argument("id");
        NeoVideoPlayerController controller = controllers.get(id);
        if (controller != null) {
          controller.stopPictureInPicture();
        }
        result.success(null);
        break;
      }
      case "setAutoPip": {
        Object id = call.argument("id");
        NeoVideoPlayerController controller = controllers.get(id);
        if (controller != null) {
          Boolean value = call.argument("value");
          controller.setAutoPip(value);
        }
        result.success(null);
        break;
      }
      case "setVolume": {
        Object id = call.argument("id");
        NeoVideoPlayerController controller = controllers.get(id);
        if (controller != null) {
          Number value = call.argument("value");
          controller.player.setVolume(value.floatValue());
        }
        result.success(null);
        break;
      }
      case "setPlaybackSpeed": {
        Object id = call.argument("id");
        NeoVideoPlayerController controller = controllers.get(id);
        if (controller != null) {
          Number value = call.argument("speed");
          controller.player.setPlaybackSpeed(value.floatValue());
        }
        result.success(null);
        break;
      }
      default:
        result.notImplemented();
        break;
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}
