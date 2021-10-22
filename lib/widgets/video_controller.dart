
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:kumav/utils/video_downloader/proxy_server.dart';

class VideoController extends StatefulWidget {
  final VlcPlayerController controller;
  final ProxyItem? proxyItem;

  VideoController({
    Key? key,
    required this.controller,
    this.proxyItem,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => VideoControllerState();
}

class VideoControllerState extends State<VideoController> {

  bool isDisplay = true;
  bool _visible = true;
  Timer? timer;

  Duration _oldPosition = Duration.zero;

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
              visible: _visible || isDisplay,
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
                      child: Row(
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
                            valueListenable: widget.controller,
                            builder: (context, value, child) {
                              if (isBuffering) {
                                return SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: Center(
                                    child: SpinKitCircle(
                                      color: Colors.white,
                                      size: 36,
                                    ),
                                  ),
                                );
                              } else {
                                return IconButton(
                                  onPressed: () {
                                    if (value.isPlaying) {
                                      widget.controller.pause();
                                    } else {
                                      widget.controller.play();
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
                    Positioned(
                      bottom: 4,
                      left: 8,
                      right: 8,
                      child: ValueListenableBuilder<VlcPlayerValue>(
                        valueListenable: widget.controller,
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
                              await widget.controller.seekTo(duration);
                              _oldTime = DateTime.fromMillisecondsSinceEpoch(0);
                              _oldPosition = duration;
                              widget.controller.value = widget.controller.value.copyWith(
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
          ],
        ),
      ),
    );
  }

  bool _disposed = false;
  DateTime? _oldTime;

  bool get isBuffering {
    var value = widget.controller.value;
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
  }

  Duration? buffered() {
    var buffered = widget.proxyItem?.buffered;
    if (buffered != null) {
      double per = 0;
      for (var buf in buffered) {
        per += buf.end - buf.start;
      }
      return widget.controller.value.duration * per;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _disposed = true;
    timer?.cancel();
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
    setState(() {
      isDisplay = false;
    });
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
}