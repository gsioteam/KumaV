
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:kumav/utils/video_downloader/proxy_server.dart';

import 'video_player.dart';

class VideoController extends StatefulWidget {
  final VlcPlayerController? controller;
  final ProxyItem? proxyItem;
  final List<VideoResolution> resolutions;
  final void Function(int index)? onSelectResolution;
  final int currentSelect;

  VideoController({
    Key? key,
    this.controller,
    this.proxyItem,
    this.resolutions = const [],
    this.onSelectResolution,
    this.currentSelect = 0,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => VideoControllerState();
}

class VideoControllerState extends State<VideoController> {

  bool isDisplay = true;
  bool _visible = true;
  Timer? timer;

  Duration _oldPosition = Duration.zero;
  GlobalKey _resolutionKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: IconTheme(
        data: IconThemeData(
          color: Colors.white,
        ),
        child: Stack(
          children: [
            Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    if (isDisplay) {
                      dismiss();
                    } else {
                      display();
                    }
                  },
                  child: Container(
                    color: Colors.transparent,
                  ),
                )
            ),
            Visibility(
              visible: (_visible || isDisplay),
              child: AnimatedOpacity(
                opacity: isDisplay ? 1 : 0,
                duration: Duration(milliseconds: 300),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Material(
                          color: Colors.black26,
                        ),
                      ),
                    ),
                    Center(
                      child: widget.controller == null ?
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: Center(
                          child: SpinKitRing(
                            color: Colors.white,
                            size: 36,
                            lineWidth: 3,
                          ),
                        ),
                      )  :
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              resetTimer();
                            },
                            icon: Icon(Icons.skip_previous),
                          ),
                          Padding(padding: EdgeInsets.only(left: 10)),
                          ValueListenableBuilder<VlcPlayerValue>(
                            valueListenable: widget.controller!,
                            builder: (context, value, child) {
                              if (isBuffering) {
                                return SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: Center(
                                    child: SpinKitRing(
                                      color: Colors.white,
                                      size: 36,
                                      lineWidth: 3,
                                    ),
                                  ),
                                );
                              } else {
                                return IconButton(
                                  onPressed: () {
                                    if (value.isPlaying) {
                                      widget.controller!.pause();
                                    } else {
                                      widget.controller!.play();
                                      _oldTime = DateTime.now();
                                    }
                                    resetTimer();
                                  },
                                  icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
                                  iconSize: 36,
                                );
                              }
                            },
                          ),
                          Padding(padding: EdgeInsets.only(left: 10)),
                          IconButton(
                            onPressed: () {
                              resetTimer();
                            },
                            icon: Icon(Icons.skip_next),
                          )
                        ],
                      ),
                    ),
                    if (widget.controller != null) Positioned(
                      bottom: 4,
                      left: 8,
                      right: 8,
                      child: ValueListenableBuilder<VlcPlayerValue>(
                        valueListenable: widget.controller!,
                        builder: (context, value, child) {
                          return ProgressBar(
                            progress: value.position,
                            total: value.duration,
                            buffered: buffered(),
                            baseBarColor: Colors.white24,
                            bufferedBarColor: Colors.white38,
                            timeLabelType: TimeLabelType.totalTime,
                            timeLabelLocation: TimeLabelLocation.above,
                            timeLabelTextStyle: TextStyle(
                                color: Colors.white
                            ),
                            thumbRadius: 6,
                            barHeight: 3,
                            onSeek: (duration) async {
                              await widget.controller!.seekTo(duration);
                              _oldTime = DateTime.fromMillisecondsSinceEpoch(0);
                              _oldPosition = duration;
                              widget.controller!.value = widget.controller!.value.copyWith(
                                position: duration,
                              );
                            },
                            onDragStart: (_) {
                              stopTimer();
                            },
                            onDragEnd: () {
                              resetTimer();
                            },
                          );
                        },
                      ),
                    )
                  ],
                ),
                onEnd: () {
                  if (!isDisplay) {
                    setState(() {
                      _visible = false;
                    });
                  }
                },
              ),
            ),
            if (widget.controller != null) ValueListenableBuilder<VlcPlayerValue>(
                valueListenable: widget.controller!,
                builder: (context, value, child) {
                  return Visibility(
                    visible: value.hasError,
                    child: Positioned.fill(
                      child: Material(
                        color: Colors.black,
                        child: Center(
                          child: DefaultTextStyle(
                            style: TextStyle(
                              color: Colors.deepOrange
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 20,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    "Error",
                                    style: TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                  Padding(padding: EdgeInsets.only(top: 10)),
                                  Text(value.errorDescription),
                                ],
                              ),
                            )
                          ),
                        ),
                      )
                    ),
                  );
                }
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Row(
                children: [
                  Expanded(child: Container()),
                  if (widget.resolutions.length > 1) _buildResolutionButton(context),
                  PopupMenuButton(
                    itemBuilder: (context) {
                      return [
                        PopupMenuItem<int>(
                          child: Row(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: Icon(Icons.refresh, color: Colors.black54,),
                              ),
                              Text("reload"),
                            ],
                          ),
                          value: 0,
                        ),
                      ];
                    },
                    onSelected: (index) {

                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _disposed = false;
  DateTime? _oldTime;

  bool get isBuffering {
    var value = widget.controller!.value;
    if (value.duration == Duration.zero) return true;
    if (value.isPlaying) {
      if (value.position == _oldPosition) {
        var now = DateTime.now();
        if (_oldTime == null) {
          _oldTime = now;
        } else if (now.difference(_oldTime!).inMilliseconds > 1100) {
          return true;
        }
      } else {
        _oldPosition = value.position;
        _oldTime = DateTime.now();
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();

    resetTimer();
    widget.controller?.addListener(_update);
  }

  Duration? buffered() {
    var buffered = widget.proxyItem?.buffered;
    if (buffered != null) {
      double per = 0;
      for (var buf in buffered) {
        per += buf.end - buf.start;
      }
      return widget.controller!.value.duration * per;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _disposed = true;
    timer?.cancel();
    widget.controller?.removeListener(_update);
  }

  void display() {
    resetTimer();
    setState(() {
      _visible = true;
    });
    Future.delayed(Duration(milliseconds: 30), () {
      if (_disposed) return;
      setState(() {
        isDisplay = true;
      });
    });
  }

  void dismiss() {
    timer?.cancel();
    timer = null;
    if (_disposed) return;
    if (widget.controller != null && widget.controller!.value.isPlaying) {
      setState(() {
        isDisplay = false;
      });
    }
  }

  void stopTimer() {
    timer?.cancel();
    timer = null;
  }

  void resetTimer() {
    timer?.cancel();
    timer = Timer(Duration(milliseconds: 4000), () {
      dismiss();
    });
  }

  bool _oldPlaying = false;
  void _update() {
    var isPlaying = widget.controller!.value.isPlaying;
    if (isPlaying != _oldPlaying) {
      _oldPlaying = isPlaying;
      if (isPlaying) {
        resetTimer();
      }
    }
  }

  Widget _buildResolutionButton(BuildContext context) {
    String title;
    if (widget.resolutions.length > widget.currentSelect) {
      var resolution = widget.resolutions[widget.currentSelect];
      title = resolution.title;
    } else {
      title = "";
    }
    return OutlinedButton(
      key: _resolutionKey,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          Icon(Icons.arrow_drop_down),
        ],
      ),
      style: OutlinedButton.styleFrom(
        primary: Colors.white,
        side: BorderSide(
          color: Colors.white,
        ),
        minimumSize: Size.zero,
        padding: EdgeInsets.only(
          left: 10,
        ),
      ),
      onPressed: () async {
        var renderObject = _resolutionKey.currentContext?.findRenderObject();
        var transform = renderObject?.getTransformTo(null);
        if (transform != null) {
          var rect = renderObject!.semanticBounds;
          var leftTop = rect.topLeft;
          var point = transform.applyToVector3Array([leftTop.dx, leftTop.dy, 0]);

          List<PopupMenuEntry<int>> items = [];
          for (int i = 0, t = widget.resolutions.length; i < t; ++i) {
            var resolution = widget.resolutions[i];
            items.add(PopupMenuItem(
              child: Text(resolution.title),
              value: i,
            ));
          }
          var index = await showMenu(
            context: context,
            position: RelativeRect.fromLTRB(
              point[0],
              point[1],
              point[0] + rect.width,
              point[1] + rect.height,
            ),
            items: items,
          );
          if (index != null && index != widget.currentSelect) {
            widget.onSelectResolution?.call(index);
          }
        }
      },
    );
  }
}