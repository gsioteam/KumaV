
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:kumav/widgets/bordered_menu_button.dart';
import 'package:neo_video_player/neo_video_player.dart' as neo;
import 'package:kumav/pages/fullscreen.dart';
import 'package:kumav/utils/video_downloader/proxy_server.dart';
import 'package:kumav/widgets/video_sheet.dart';

import 'slider_bar.dart';
import 'video_player.dart';

class VideoController extends StatefulWidget {
  final neo.VideoPlayerController? controller;
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

enum PlaySpeed {
  x0_5,
  x1,
  x1_5,
  x2,
}

class VideoControllerState extends State<VideoController> {

  bool isDisplay = true;
  bool _visible = true;
  ValueNotifier<int> _speed = ValueNotifier(0);
  Timer? timer;
  PlaySpeed _playSpeed = PlaySpeed.x1;

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
                          ValueListenableBuilder<neo.VideoPlayerValue>(
                            valueListenable: widget.controller!,
                            builder: (context, value, child) {
                              if (value.isBuffering) {
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
                                      // _oldTime = DateTime.now();
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
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              VideoSheetMinifyNotification().dispatch(context);
                            },
                            icon: Icon(Icons.keyboard_arrow_down)
                          ),
                          Expanded(child: Container()),
                          ValueListenableBuilder<int>(
                            valueListenable: _speed,
                            builder: (context, value, child) {
                              if (value > 0) {
                                return Text(
                                  _speedText(value),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                );
                              } else {
                                return Container();
                              }
                            }
                          ),
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
                    if (widget.controller != null) Positioned(
                      bottom: 4,
                      left: 8,
                      right: 8,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SliderBar(
                            controller: widget.controller!,
                            proxyItem: widget.proxyItem!,
                            onBeginDrag: () {
                              stopTimer();
                            },
                            onEndDrag: () {
                              resetTimer();
                            },
                          ),
                          Row(
                            children: [
                              BorderedMenuButton<PlaySpeed>(
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      WidgetSpan(
                                        child: Padding(
                                          padding: EdgeInsets.only(right: 2),
                                          child: Icon(Icons.speed, size: 12,),
                                        ),
                                        alignment: PlaceholderAlignment.middle,
                                      ),
                                      TextSpan(text: textFromSpeed(_playSpeed))
                                    ],
                                  )
                                ),
                                items: [
                                  PopupMenuItem(
                                    child: Text(textFromSpeed(PlaySpeed.x0_5)),
                                    value: PlaySpeed.x0_5,
                                  ),
                                  PopupMenuItem(
                                    child: Text(textFromSpeed(PlaySpeed.x1)),
                                    value: PlaySpeed.x1,
                                  ),
                                  PopupMenuItem(
                                    child: Text(textFromSpeed(PlaySpeed.x1_5)),
                                    value: PlaySpeed.x1_5,
                                  ),
                                  PopupMenuItem(
                                    child: Text(textFromSpeed(PlaySpeed.x2)),
                                    value: PlaySpeed.x2,
                                  ),
                                ],
                                onSelected: (speed) {
                                  if (_playSpeed != speed) {
                                    setState(() {
                                      _playSpeed = speed;
                                      double sp;
                                      switch (_playSpeed) {
                                        case PlaySpeed.x0_5: sp = 0.5; break;
                                        case PlaySpeed.x1: sp = 1; break;
                                        case PlaySpeed.x1_5: sp = 1.5; break;
                                        case PlaySpeed.x2: sp = 2; break;
                                      }
                                      widget.controller?.setPlaybackSpeed(sp);
                                    });
                                  }
                                },
                              ),
                              Expanded(child: Container()),
                              IconButton(
                                onPressed: () async {
                                  SystemChrome.setPreferredOrientations([
                                    DeviceOrientation.landscapeLeft,
                                    DeviceOrientation.landscapeRight
                                  ]);
                                  await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                                    return Fullscreen(
                                      controller: widget.controller!,
                                    );
                                  }));
                                  SystemChrome.setPreferredOrientations([
                                    DeviceOrientation.portraitUp
                                  ]);
                                },
                                icon: Icon(Icons.fullscreen)
                              )
                            ],
                          ),
                        ],
                      )
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
            if (widget.controller != null) ValueListenableBuilder<neo.VideoPlayerValue>(
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
                                  Text(value.errorDescription??""),
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
          ],
        ),
      ),
    );
  }

  bool _disposed = false;

  String textFromSpeed(PlaySpeed speed) {
    switch (speed) {
      case PlaySpeed.x0_5: return "0.5x";
      case PlaySpeed.x1: return "1x";
      case PlaySpeed.x1_5: return "1.5x";
      case PlaySpeed.x2: return "2x";
    }
  }

  @override
  void initState() {
    super.initState();

    resetTimer();
    widget.controller?.addListener(_update);
    widget.proxyItem?.addOnSpeed(_updateSpeed);
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
    widget.proxyItem?.removeOnSpeed(_updateSpeed);
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

    List<PopupMenuEntry<int>> items = [];
    for (int i = 0, t = widget.resolutions.length; i < t; ++i) {
      var resolution = widget.resolutions[i];
      items.add(PopupMenuItem(
        child: Text(resolution.title),
        value: i,
      ));
    }
    return BorderedMenuButton<int>(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
          ),
          Icon(Icons.arrow_drop_down),
        ],
      ),
      items: items,
      onPopup: stopTimer,
      onCanceled: resetTimer,
      onSelected: (index) {
        resetTimer();
        if (index != widget.currentSelect) {
          widget.onSelectResolution?.call(index);
        }
      },
      padding: EdgeInsets.only(
        left: 10,
      ),
    );
  }

  void _updateSpeed(int speed) {
    _speed.value = speed;
  }

  String _speedText(int speed) {
    double sp = speed / 1024;
    String unit = "KB";
    if (sp > 1024) {
      sp = sp / 1024;
      unit = "MB";
    }
    return "${sp.toStringAsFixed(2)} $unit";
  }
}