package com.neo.neo_video_player;

import android.content.Context;
import android.graphics.Color;
import android.os.Handler;
import android.view.SurfaceView;
import android.view.TextureView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.RelativeLayout;

import java.util.Map;

import io.flutter.Log;
import io.flutter.plugin.platform.PlatformView;

public class NeoVideoPlayer implements PlatformView {
    Object id;
    PlayerView playerView;
//    TextureView textureView;
    RelativeLayout container;

    NeoVideoPlayer(Context context, NeoVideoPlayerController controller, Map params) {
        this.id = params.get("id");
//
        playerView = new PlayerView(context, controller);
        playerView.enable();
//        textureView = new TextureView(context);
//        textureView.setSurfaceTexture(controller.getSurfaceTexture());

        container = new RelativeLayout(context);
        container.addView(playerView);
//        container.addView(textureView);

    }

    @Override
    public View getView() {
        return container;
    }

    @Override
    public void dispose() {
        playerView.disable();
    }
}
