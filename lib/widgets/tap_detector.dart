
import 'dart:async';

import 'package:flutter/material.dart';

class TapEvent {
  Offset position;
  Offset localPosition;

  TapEvent(this.position, this.localPosition);
}

typedef TapListener = void Function(TapEvent);

class TapDetector extends StatefulWidget {

  final Widget child;
  final TapListener onTap;
  final TapListener onPanStart;
  final TapListener onPanMove;
  final TapListener onPanEnd;
  final TapListener onDoubleTap;
  final Duration doubleDuration;

  TapDetector({
    this.child,
    this.onTap,
    this.onPanStart,
    this.onPanMove,
    this.onPanEnd,
    this.onDoubleTap,
    this.doubleDuration = const Duration(milliseconds: 300)
  });

  @override
  State<StatefulWidget> createState() => _TapDetectorState();
}

enum _TapStatus {
  Any,
  Tap,
  Drag
}

class _TapDetectorState extends State<TapDetector> {
  _TapStatus status;
  Offset position;
  Timer doubleTapTimer;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: onPointerDown,
      onPointerMove: onPointerMove,
      onPointerUp: onPointerUp,
      onPointerCancel: onPointerCancel,
      child: widget.child,
    );
  }

  void onPointerDown(PointerDownEvent event) {
    if (doubleTapTimer?.isActive == true && status == _TapStatus.Tap) {
      if (widget.onDoubleTap != null) {
        doubleTapTimer?.cancel();
        widget.onDoubleTap.call(TapEvent(event.position, event.localPosition));
      }
    } else {
      status = _TapStatus.Any;
    }
    position = event.localPosition;
  }

  void onPointerMove(PointerMoveEvent event) {
    switch (status) {
      case _TapStatus.Any:
      case _TapStatus.Tap:
        {
        if ((event.localPosition - position).distance > 10) {
          doubleTapTimer?.cancel();
          status = _TapStatus.Drag;
          widget.onPanStart?.call(TapEvent(event.position, event.localPosition));
        }
        break;
      }
      case _TapStatus.Drag: {
        widget.onPanMove?.call(TapEvent(event.position, event.localPosition));
      }
    }
  }

  void onPointerUp(PointerUpEvent event) {
    switch (status) {
      case _TapStatus.Any: {
        if (widget.onDoubleTap != null) {
          status = _TapStatus.Tap;
          doubleTapTimer = Timer(widget.doubleDuration, () {
            widget.onTap?.call(TapEvent(event.position, event.localPosition));
          });
        } else {
          widget.onTap?.call(TapEvent(event.position, event.localPosition));
        }
        break;
      }
      case _TapStatus.Drag: {
        widget.onPanEnd?.call(TapEvent(event.position, event.localPosition));
        break;
      }
      default: break;
    }
  }

  void onPointerCancel(PointerCancelEvent event) {
    switch (status) {
      case _TapStatus.Drag: {
        widget.onPanEnd?.call(TapEvent(event.position, event.localPosition));
        break;
      }
      default: break;
    }
  }
}