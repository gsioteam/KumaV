
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kumav/utils/video_downloader/proxy_server.dart';
import 'package:neo_video_player/neo_video_player.dart';

class SliderBar extends StatefulWidget {

  final VideoPlayerController controller;
  final ProxyItem proxyItem;
  final double handlerSize;
  final VoidCallback? onBeginDrag;
  final VoidCallback? onEndDrag;

  SliderBar({
    Key? key,
    required this.controller,
    required this.proxyItem,
    this.handlerSize = 18,
    this.onBeginDrag,
    this.onEndDrag,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SliderBarState();
}

class AnyGestureRecognizer extends OneSequenceGestureRecognizer {
  @override
  String get debugDescription => "any_gesture";

  @override
  void didStopTrackingLastPointer(int pointer) {
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer, event.transform);
    resolve(GestureDisposition.accepted);
  }

  @override
  void handleEvent(PointerEvent event) {
  }

}

class _SliderBarState extends State<SliderBar> {
  ValueNotifier<bool> _pointerOn = ValueNotifier(false);
  GlobalKey _containerKey = GlobalKey();

  double _draggingPercent = 0;
  bool _seeking = false;
  bool _waitSeeking = false;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        AnyGestureRecognizer: GestureRecognizerFactoryWithHandlers<AnyGestureRecognizer>(
            () => AnyGestureRecognizer(),
            (AnyGestureRecognizer instance) {
            },
        ),
      },
      child: Listener(
        child: Container(
          key: _containerKey,
          color: Colors.transparent,
          height: widget.handlerSize,
          child: LayoutBuilder(
            builder: (context, constraints) {
              Offset offset;
              double percent;
              var value = widget.controller.value;
              if (_seeking) {
                percent = _draggingPercent;
              } else if (_waitSeeking) {
                if (value.isBuffering) {
                  percent = _draggingPercent;
                } else {
                  percent = this.percent;
                  _waitSeeking = false;
                }
              } else {
                percent = this.percent;
              }
              if (_pointerOn.value) {
                offset = Offset(-widget.handlerSize / 2 + constraints.maxWidth * _draggingPercent, 0);
              } else {
                offset = Offset(-widget.handlerSize / 2 + constraints.maxWidth * percent, 0);
              }

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Container(
                      width: constraints.maxWidth,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.white38,
                        borderRadius: BorderRadius.circular(1),
                      ),
                      child: Stack(
                        children: [
                          FractionallySizedBox(
                            widthFactor: percent,
                            heightFactor: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: offset,
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _pointerOn,
                      builder: (context, value, child) {
                        return AnimatedContainer(
                          transform: value ? Matrix4.identity() : Matrix4.diagonal3Values(0.1, 0.1, 0.1),
                          duration: Duration(milliseconds: 300),
                          transformAlignment: Alignment.center,
                          width: widget.handlerSize,
                          height: widget.handlerSize,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(widget.handlerSize/2),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        onPointerDown: (event) {
          _draggingPercent = percent;
          _pointerOn.value = true;
          widget.onBeginDrag?.call();
        },
        onPointerMove: (event) {
          setState(() {
            _draggingPercent = draggingPercent(event.localPosition.dx);
          });
        },
        onPointerUp: (event) {
          _draggingPercent = draggingPercent(event.localPosition.dx);
          _seeking = true;
          _waitSeeking = true;
          widget.controller.seekTo(widget.controller.value.duration * _draggingPercent).then((value) {
            _seeking = false;
          });

          _pointerOn.value = false;
          widget.onEndDrag?.call();
        },
        onPointerCancel: (event) {
          _pointerOn.value = false;
          widget.onEndDrag?.call();
        },
      ),
    );
  }

  double get percent {
    var value = widget.controller.value;
    if (value.duration == Duration.zero) {
      return 0;
    }
    return value.position.inMilliseconds / value.duration.inMilliseconds;
  }

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(_update);
  }

  @override
  void dispose() {
    super.dispose();

    widget.controller.removeListener(_update);
  }

  void _update() {
    setState(() { });
  }

  double draggingPercent(double dx) {
    var rect = _containerKey.currentContext?.findRenderObject()?.semanticBounds;
    if (rect != null) {
      double per = dx / rect.width;
      return per.clamp(0, 1);
    }
    return 0;
  }
}