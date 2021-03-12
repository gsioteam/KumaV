package com.qlp.kuma;

import android.content.Context;
import android.content.Intent;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.ColorFilter;
import android.graphics.Paint;
import android.graphics.PixelFormat;
import android.graphics.Point;
import android.graphics.PointF;
import android.graphics.Rect;
import android.os.Build;
import android.util.Log;
import android.view.MotionEvent;
import android.view.Surface;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.view.animation.AlphaAnimation;
import android.view.animation.Animation;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.RelativeLayout;

import com.google.android.exoplayer2.Format;
import com.google.android.exoplayer2.Player;
import com.google.android.exoplayer2.SimpleExoPlayer;

class OverlayPlayerView extends RelativeLayout implements Player.EventListener {

    SimpleExoPlayer exoPlayer;
    Surface flutterSurface;
    WindowManager.LayoutParams layoutParams;
    ImageButton pauseButton;

    interface OnEventListener {
        void onDismiss();
    }
    OnEventListener onEventListener;

    public void setOnEventListener(OnEventListener onEventListener) {
        this.onEventListener = onEventListener;
    }

    public OnEventListener getOnEventListener() {
        return onEventListener;
    }

    class TouchLayer extends View {

        PointF p = new PointF();
        PointF p2 = new PointF();

        final int STATE_CLICK = 0;
        final int STATE_DRAG = 1;
        final int STATE_SCALE = 2;

        int state = STATE_CLICK;

        public TouchLayer(Context context) {
            super(context);
        }

        @Override
        public boolean onTouchEvent(MotionEvent event) {
            int action = event.getAction();
            switch (action) {
                case MotionEvent.ACTION_DOWN: {
                    p.x = event.getRawX();
                    p.y = event.getRawY();
                    state = STATE_CLICK;
                    break;
                }
                case MotionEvent.ACTION_MOVE: {
                    if (event.getPointerCount() == 1) {
                        float nx = event.getRawX(), ny = event.getRawY();
                        if (state == STATE_CLICK) {
                            if (Math.abs(nx - p.x) > 4 || Math.abs(ny - p.y) > 4) {
                                state = STATE_DRAG;
                            }
                        } else if (state == STATE_SCALE) {
                            p.x = event.getRawX();
                            p.y = event.getRawY();
                        } else {
                            onDrag(nx - p.x, ny - p.y);
                            p.x = nx;
                            p.y = ny;
                        }
                    } else if (event.getPointerCount() == 2) {
                        if (state == STATE_SCALE) {
                            MotionEvent.PointerCoords coords0 = new MotionEvent.PointerCoords();
                            MotionEvent.PointerCoords coords1 = new MotionEvent.PointerCoords();
                            event.getPointerCoords(0, coords0);
                            event.getPointerCoords(1, coords1);

                            double len = Math.sqrt(Math.pow(coords0.x - coords1.x, 2) + Math.pow(coords0.y - coords1.y, 2));
                            double oldLen = Math.sqrt(Math.pow(p.x - p2.x, 2) + Math.pow(p.y - p2.y, 2));

                            onScale(len / oldLen);

                            p.x = coords0.x;
                            p.y = coords0.y;
                            p2.x = coords1.x;
                            p2.y = coords1.y;
                        } else {
                            MotionEvent.PointerCoords coords = new MotionEvent.PointerCoords();
                            event.getPointerCoords(0, coords);
                            p.x = coords.x;
                            p.y = coords.y;

                            event.getPointerCoords(1, coords);
                            p2.x = coords.x;
                            p2.y = coords.y;

                            state = STATE_SCALE;
                        }
                    }
                    break;
                }
                case MotionEvent.ACTION_UP: {
                    if (state == STATE_CLICK) {
                        onClicked();
                    }
                    break;
                }
            }
            return true;
        }
    }

    SurfaceView surfaceView;
    RelativeLayout controlLayer;
    boolean isAppear = false;
    ImageButton fullscreenButton;
    ImageButton closeButton;

    public OverlayPlayerView(Context context) {
        super(context);

        surfaceView = new SurfaceView(context);
        RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
        );
        surfaceView.setLayoutParams(params);
        addView(surfaceView);

        TouchLayer touchLayer = new TouchLayer(context);
        touchLayer.setLayoutParams(params);
        addView(touchLayer);

        controlLayer = new RelativeLayout(context);
        controlLayer.setLayoutParams(params);
        controlLayer.setBackgroundColor(Color.argb(44, 0, 0, 0));
//        controlLayer.setAlpha(0);
        addView(controlLayer);

        int margin = 5;
        fullscreenButton = new ImageButton(context);
        fullscreenButton.setScaleType(ImageView.ScaleType.CENTER_INSIDE);
        fullscreenButton.setImageResource(R.drawable.fullscreen);
        fullscreenButton.setBackgroundColor(Color.TRANSPARENT);
        params = new RelativeLayout.LayoutParams(
                100,
                100
        );
        params.setMargins(margin, margin, margin, margin);
        fullscreenButton.setColorFilter(Color.WHITE);
        fullscreenButton.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(getContext(), getContext().getClass());
                intent.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);
                intent.addFlags(Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED);
                intent.addFlags(Intent.FLAG_ACTIVITY_PREVIOUS_IS_TOP);
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                getContext().startActivity(intent);
            }
        });
        fullscreenButton.setLayoutParams(params);
        controlLayer.addView(fullscreenButton);

        closeButton = new ImageButton(context);
        closeButton.setImageResource(R.drawable.cancel);
        closeButton.setScaleType(ImageView.ScaleType.CENTER_INSIDE);
        closeButton.setBackgroundColor(Color.TRANSPARENT);
        params = new RelativeLayout.LayoutParams(
                100,
                100
        );
        params.setMargins(margin, margin, margin, margin);
        params.addRule(ALIGN_PARENT_RIGHT, TRUE);
        closeButton.setLayoutParams(params);
        closeButton.setColorFilter(Color.WHITE);
        closeButton.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                exoPlayer.setPlayWhenReady(false);
                dismissOverlay();
            }
        });
        controlLayer.addView(closeButton);

        pauseButton = new ImageButton(context);
        pauseButton.setImageResource(R.drawable.play);
        pauseButton.setScaleType(ImageView.ScaleType.CENTER_INSIDE);
        pauseButton.setBackgroundColor(Color.TRANSPARENT);
        pauseButton.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                if (exoPlayer.getPlayWhenReady()) {
                    exoPlayer.setPlayWhenReady(false);
                } else {
                    exoPlayer.setPlayWhenReady(true);
                }
                showAnimation();
                countToDismiss();
            }
        });
        params = new RelativeLayout.LayoutParams(
                160,
                160
        );
        params.addRule(CENTER_IN_PARENT, TRUE);
        pauseButton.setLayoutParams(params);
        pauseButton.setColorFilter(Color.WHITE);
        controlLayer.addView(pauseButton);
    }

    WindowManager getWindowManager() {
        return (WindowManager) getContext().getSystemService(Context.WINDOW_SERVICE);
    }

    public void showOverlay() {
        WindowManager windowManager = getWindowManager();
        Point size = new Point();
        windowManager.getDefaultDisplay().getSize(size);
        int flags;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            flags = WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY;
        } else {
            flags = WindowManager.LayoutParams.TYPE_SYSTEM_ALERT;
        }
        layoutParams = new WindowManager.LayoutParams(
                flags,
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON |
                        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
                PixelFormat.TRANSPARENT
        );
        int width = size.x * 2 / 3;
        int height = size.y / 2;
        Format format = exoPlayer.getVideoFormat();
        if (format != null) {
            int w = width, h = format.height * width / format.width;
            if (h > height) {
                h = height;
                w = format.width * height / format.height;
            }
            width = w;
            height = h;
        }
        layoutParams.width = width;
        layoutParams.height = height;
        videoSize.x = width;
        videoSize.y = height;
        layoutParams.x = (size.x - width) / 2 - 30;
        layoutParams.y = (size.y - height) / 2 - 260;
        windowManager.addView(this, layoutParams);

        exoPlayer.setVideoSurfaceView(surfaceView);
        exoPlayer.addListener(this);
        setPauseButton(exoPlayer.getPlayWhenReady());

    }

    @Override
    protected void onAttachedToWindow() {
        super.onAttachedToWindow();
        showAnimation();
        countToDismiss();
    }

    public void dismissOverlay() {
        WindowManager windowManager = getWindowManager();
        windowManager.removeView(this);
        exoPlayer.removeListener(this);
        exoPlayer.setVideoSurface(flutterSurface);
        if (onEventListener != null) {
            onEventListener.onDismiss();
        }
    }

    private void onDrag(float offx, float offy) {
        WindowManager windowManager = getWindowManager();
        Point size = new Point();
        windowManager.getDefaultDisplay().getSize(size);

        int maxX = (size.x - layoutParams.width) / 2;
        int maxY = (size.y - layoutParams.height) / 2;
        layoutParams.x = (int)Math.max(-maxX, Math.min(maxX, layoutParams.x + offx));
        layoutParams.y = (int)Math.max(-maxY, Math.min(maxY, layoutParams.y + offy));
        windowManager.updateViewLayout(this, layoutParams);
    }

    PointF videoSize = new PointF();

    private void onScale(double scale) {
        WindowManager windowManager = getWindowManager();
        Point size = new Point();
        windowManager.getDefaultDisplay().getSize(size);
        videoSize.x *= scale;
        videoSize.y *= scale;

        int width = size.x / 2;
        if (videoSize.x < width) {
            videoSize.y = videoSize.y * width / videoSize.x;
            videoSize.x = width;
        } else if (videoSize.x > size.x) {
            videoSize.y = videoSize.y * size.x / videoSize.x;
            videoSize.x = size.x;
        }
        layoutParams.width = (int)videoSize.x;
        layoutParams.height = (int)videoSize.y;
        onDrag(0, 0);
    }

    private void onClicked() {
        if (isAppear) {
            getHandler().removeCallbacks(missTimeout);
            missAnimation();
        } else {
            showAnimation();
            countToDismiss();
        }
    }

    void setPauseButton(boolean isPlaying) {
        if (isPlaying) {
            pauseButton.setImageResource(R.drawable.pause);
        } else {
            pauseButton.setImageResource(R.drawable.play);
        }
    }

    @Override
    public void onPlayerStateChanged(boolean playWhenReady, int playbackState) {
        setPauseButton(playWhenReady);
    }

    AlphaAnimation alphaAnimation;

    void showAnimation() {
        if (isAppear) return;
        isAppear = true;
        if (alphaAnimation != null) {
            alphaAnimation.cancel();
            alphaAnimation = null;
        }

        fullscreenButton.setVisibility(VISIBLE);
        pauseButton.setVisibility(VISIBLE);
        closeButton.setVisibility(VISIBLE);
        alphaAnimation = new AlphaAnimation(0, 1);
        alphaAnimation.setDuration(300);
        alphaAnimation.setFillAfter(true);
        alphaAnimation.setAnimationListener(new Animation.AnimationListener() {
            @Override
            public void onAnimationStart(Animation animation) {

            }

            @Override
            public void onAnimationEnd(Animation animation) {
                alphaAnimation = null;
            }

            @Override
            public void onAnimationRepeat(Animation animation) {

            }
        });
        controlLayer.startAnimation(alphaAnimation);
    }

    void missAnimation() {
        if (!isAppear) return;
        isAppear = false;
        if (alphaAnimation != null) {
            alphaAnimation.cancel();
            alphaAnimation = null;
        }

        alphaAnimation = new AlphaAnimation(1, 0);
        alphaAnimation.setDuration(300);
        alphaAnimation.setFillAfter(true);
        alphaAnimation.setAnimationListener(new Animation.AnimationListener() {
            @Override
            public void onAnimationStart(Animation animation) {

            }

            @Override
            public void onAnimationEnd(Animation animation) {
                alphaAnimation = null;
                fullscreenButton.setVisibility(INVISIBLE);
                pauseButton.setVisibility(INVISIBLE);
                closeButton.setVisibility(INVISIBLE);
            }

            @Override
            public void onAnimationRepeat(Animation animation) {

            }
        });
        controlLayer.startAnimation(alphaAnimation);
    }

    Runnable missTimeout = new Runnable() {
        @Override
        public void run() {
            missAnimation();
        }
    };

    void countToDismiss() {
        getHandler().removeCallbacks(missTimeout);
        getHandler().postDelayed(missTimeout, 5000);
    }
}