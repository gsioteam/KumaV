import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glib/core/array.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/models.dart';
import 'package:glib/main/project.dart';
import 'package:kuma_player/kuma_player.dart';
import 'package:kumav/utils/controller.dart';
import 'package:kumav/utils/github_account.dart';
import 'package:kumav/widgets/danmaku_layer.dart';
import 'package:kumav/widgets/danmaku_widget.dart';
import 'package:kumav/widgets/fullscreen_player.dart';
import 'package:kumav/widgets/overlay_menu.dart';
import 'dart:math' as math;

import '../configs.dart';
import 'better_refresh_indicator.dart';
import 'full_kuma_player.dart';
import 'player_controller.dart';
import 'tap_detector.dart';
import '../utils/video_notification.dart';
import '../utils/cancelable.dart';
import 'package:auto_orientation/auto_orientation.dart';

enum ItemPageStatus {
  Fullscreen,
  InPage,
  SmallWindow,
  Hidden
}

abstract class VideoData {
  List<String> get list;

  String get key;
  int get initialIndex;

  Future<String> load(int index);
}

class Bound {
  final double left, right, top, bottom;

  Bound({
    this.left = 0,
    this.right = 0,
    this.top = 0,
    this.bottom = 0
  });

  static Bound mix(Bound from, Bound to, double p) {
    return Bound(
        left: from.left + (to.left - from.left) * p,
        right: from.right + (to.right - from.right) * p,
        top: from.top + (to.top - from.top) * p,
        bottom: from.bottom + (to.bottom - from.bottom) * p
    );
  }
}

class VideoInner extends StatefulWidget {
  final VideoData data;
  final Widget child;
  final double videoHeight;
  final EdgeInsets padding;
  final KumaState state;
  final void Function(TouchState state, Offset offset) onDrag;
  final double videoWidth;
  final String title;
  final String subtitle;
  final VoidCallback onClose;
  final VoidCallback onTapWhenMini;
  final VoidCallback onMiniClicked;
  final VoidCallback onReload;
  final Future<void> Function(WidgetBuilder) onEnterFullscreen;
  final VoidCallback onExitFullscreen;
  final ShowAlertListener showAlert;
  final Controller<MenuStatus, MenuEvent, void> switchController;

  VideoInner({
    Key key,
    this.data,
    this.child,
    this.videoHeight,
    this.padding,
    this.state,
    this.onDrag,
    this.title,
    this.videoWidth = 0,
    this.subtitle,
    this.onClose,
    this.onTapWhenMini,
    this.onMiniClicked,
    this.onReload,
    this.showAlert,
    this.switchController,
    @required this.onEnterFullscreen,
    this.onExitFullscreen,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => VideoInnerState();
}

class VideoInnerState extends State<VideoInner> {

  KumaPlayerController controller;
  String loadError;
  String speed = "";
  int selected = 0;
  GitIssueDanmakuController danmakuController;

  Widget buildSwitch(BuildContext context) {
    if ((widget.data?.list?.length ?? 0) > 1) {
      List<OverlayMenuItem> items = [];
      String selTitle = "";
      if (selected >= widget.data.list.length) {
        selected = 0;
      }
      for (int i = 0, t = widget.data.list.length; i < t; ++i) {
        var title = widget.data.list[i];
        if (i == selected) selTitle = title;
        items.add(OverlayMenuItem(
          child: Text(title, style: TextStyle(color: i == selected ? Theme.of(context).primaryColor : Colors.black87,)),
          onPressed: () {
            setState(() {
              selected = i;
              KeyValue.set("$video_select_key:${widget.data.key}", selected.toString());
              _play(selected);
            });
          }
        ));
      }

      return OverlayMenu(
        controller: widget.switchController,
        builder: (context, onPressed) {
          return MaterialButton(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: selTitle
                  ),
                  WidgetSpan(
                    child: Icon(Icons.arrow_drop_down),
                    alignment: PlaceholderAlignment.middle
                  )
                ]
              ),
            ),
            onPressed: onPressed,
            textColor: Colors.white
          );
        },
        items: items,
      );
    } else {
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Padding(
            padding: widget.padding,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    height: math.max(widget.videoHeight, 0),
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: Colors.black
                    ),
                    child: OverflowBox(
                      maxHeight: math.max(widget.videoHeight, MINI_SIZE),
                      child: Row(
                        children: [
                          Expanded(
                            child: FullKumaPlayer(
                              controller: controller,
                              state: widget.state,
                              onDrag: widget.onDrag,
                              onTapWhenMini: widget.onTapWhenMini,
                              topBar: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.keyboard_arrow_down),
                                    color: Colors.white,
                                    onPressed: widget.onMiniClicked
                                  ),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(speed, style: Theme.of(context).textTheme.bodyText1.copyWith(color: Colors.white),),
                                    )
                                  ),
                                  buildSwitch(context),
                                  Container(width: 8,)
                                ],
                              ),
                              onToggleFullscreen: () {
                                onToggleFullscreen(widget.data);
                              },
                              otherError: loadError,
                              showAlert: widget.showAlert,
                              onReload: () {
                                setState(() {
                                  loadError = null;
                                });
                                widget.onReload?.call();
                              },
                              videoKey: widget.data?.key,
                              onTurnMini: widget.onMiniClicked,
                              danmakuController: danmakuController,
                            )
                          ),
                          Container(
                            width: widget.videoWidth,
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              color: Colors.white
                            ),
                            child: OverflowBox(
                              maxWidth: math.max(160, widget.videoWidth),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TapDetector(
                                      onTap: (event) {
                                        if (widget.state == KumaState.Mini) {
                                          widget.onTapWhenMini?.call();
                                        }
                                      },
                                      onPanStart: onPanStart,
                                      onPanMove: onPanMove,
                                      onPanEnd: onPanEnd,
                                      child: Padding(
                                        padding: EdgeInsets.only(left: 10, right: 10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Text(widget.title, overflow: TextOverflow.ellipsis, maxLines: 1,),
                                            Text(widget.subtitle, style: Theme.of(context).textTheme.bodyText2.copyWith(color: Colors.grey), overflow: TextOverflow.ellipsis, maxLines: 1,)
                                          ],
                                        ),
                                      ),
                                    )
                                  ),
                                  IconButton(
                                    icon: Icon(controller?.value?.isPlaying == true ? Icons.pause : Icons.play_arrow),
                                    onPressed: playOrPause
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close),
                                    onPressed: widget.onClose
                                  )
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: widget.child
                  ),
                ],
              ),
            )
        ),
      ),
    );
  }

  void onToggleFullscreen(VideoData videoData) async {
    AutoOrientation.landscapeAutoMode();
    SystemChrome.setEnabledSystemUIOverlays([]);
    await widget.onEnterFullscreen.call((context) {
      return FullscreenPlayer(
        controller: controller,
        onExitFullscreen: widget.onExitFullscreen,
        videoKey: videoData.key,
        onReload: widget.onReload,
        onTurnMini: () async {
          widget.onExitFullscreen?.call();
          await Future.delayed(Duration(milliseconds: 1000));
          widget.onMiniClicked?.call();
        },
        danmakuController: danmakuController
      );
    });
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    AutoOrientation.portraitUpMode();
  }

  void playOrPause() {

  }

  String get startTimeKey => "$start_time_key:${widget.data.key}";

  Duration old;

  void onChangeState() {
    if (widget.data != null && controller.value?.position != null) {
      if (old == null) {
        old = controller.value.position;
      } else if ((controller.value.position - old).abs() > Duration(seconds: 2)) {
        KeyValue.set(startTimeKey, controller.value.position.inMilliseconds.toString());
        old = controller.value.position;
      }
    }
    setState(() { });
  }

  Cancelable<String> loadCancelable;

  void _play(int index) async {
    loadCancelable?.cancel();
    releaseController();
    if ((widget.data?.list?.length ?? 0) > index) {
      loadCancelable = Cancelable(widget.data.load(index));
      try {
        String url = await loadCancelable.future;
        Uri uri = Uri.parse(url);
        if (!uri.hasScheme) {
          throw new Exception("Wrong url");
        }

        String timeStr = KeyValue.get(startTimeKey);
        Duration startTime;
        if (timeStr.isNotEmpty) {
          startTime = Duration(
            milliseconds: int.parse(timeStr)
          );
        }
        // danmakuController?.dispose();
        controller = KumaPlayerController.network(url,
          startTime: startTime,
        );
        // danmakuController = GitIssueDanmakuController(
        //   controller,
        //   issue: GithubAccount().get(widget.data.key)
        // );
        controller.addListener(onChangeState);
        controller.addOnSpeed(_onSpeed);
        setState(() {
          loadError = null;
        });
      } catch (e) {
        setState(() {
          loadError = e.toString();
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.data != null) {
      if (widget.data?.initialIndex != null) {
        selected = widget.data.initialIndex;
      } else {
        String str = KeyValue.get("$video_select_key:${widget.data.key}");
        selected = int.tryParse(str) ?? 0;
      }
      _play(selected);
    }
  }

  @override
  void dispose() {
    super.dispose();
    danmakuController?.dispose();
    releaseController();
  }

  void releaseController() {
    controller?.removeListener(onChangeState);
    controller?.removeOnSpeed(_onSpeed);
    controller?.dispose();
    controller = null;
  }

  void saveCurrentTime() {

  }

  Queue<int> _speeds = Queue();

  void _onSpeed(int sp) {
    _speeds.add(sp);
    while (_speeds.length > 10) {
      _speeds.removeFirst();
    }
    int total = 0;
    for (var spd in _speeds) {
      total += spd;
    }
    double speed = total / _speeds.length;
    String unit = 'KB/s';
    speed = speed / 1024;
    if (speed > 1024) {
      unit = 'MB/s';
      speed = speed / 1024;
    }
    String speedStr = "";
    if (speed != 0) {
      speedStr = "${speed.toStringAsFixed(2)} $unit";
    }
    if (speedStr != this.speed) {
      setState(() {
        this.speed = speedStr;
      });
    }
  }

  Offset oldPosition;
  void onPanStart(TapEvent event) {
    oldPosition = event.position;
    widget.onDrag?.call(TouchState.Start, Offset.zero);
  }

  void onPanMove(TapEvent event) {
    widget.onDrag?.call(TouchState.Move, event.position - oldPosition);
    oldPosition = event.position;
  }

  void onPanEnd(TapEvent event) {
    widget.onDrag?.call(TouchState.End, event.position - oldPosition);
    oldPosition = event.position;
  }
}
