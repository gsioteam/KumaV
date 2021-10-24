
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:kumav/utils/plugin.dart';

import 'value_widget.dart';

enum _VideoSheetStatus {
  Closed,
  Mini,
  Fullscreen,
}

class VideoSheetNotification extends Notification {}
class VideoSheetOpenNotification extends VideoSheetNotification{}
class VideoSheetCloseNotification extends VideoSheetNotification{}

typedef VideoContentBuilder = Widget Function(BuildContext context, ScrollPhysics physics, ValueNotifier<RectValue> controller);

class _VideoSheetScrollPhysics extends ScrollPhysics {
  final VideoSheetState state;

  _VideoSheetScrollPhysics(this.state, {ScrollPhysics? parent}) : super(parent: parent);

  @override
  ScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _VideoSheetScrollPhysics(state, parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (state.onDrag(position, offset)) {
      return super.applyPhysicsToUserOffset(position, offset);
    }
    return 0;
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if (position is ScrollPositionWithSingleContext && (position as ScrollPositionWithSingleContext).activity is DragScrollActivity) {
      if (state.onDragOver(velocity)) {
        return super.createBallisticSimulation(position, velocity);
      }
    } else {
      return super.createBallisticSimulation(position, velocity);
    }
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => true;
}

class VideoSheet extends StatefulWidget {

  final VideoContentBuilder builder;
  final double barSize;
  final double bottomHeight;
  final double maxHeight;

  VideoSheet({
    Key? key,
    required this.builder,
    required this.maxHeight,
    this.barSize = 68,
    this.bottomHeight = 58,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => VideoSheetState();

}

const double _Gap = 10;

class RectValue {
  double left;
  double right;
  double top;
  double bottom;
  double barSize;

  RectValue({
    this.left = 0,
    this.right = 0,
    this.top = 0,
    this.bottom = 0,
    required this.barSize,
  });
}

class VideoInfo {
  String key;
  dynamic data;
  Plugin plugin;

  VideoInfo({
    required this.key,
    required this.data,
    required this.plugin,
  });
}

class VideoSheetState extends State<VideoSheet> with SingleTickerProviderStateMixin {
  late _VideoSheetScrollPhysics scrollPhysics;
  late double top;
  late AnimationController animation;
  double from = 0;
  double to = 0;
  late ValueNotifier<RectValue> rectController;

  _VideoSheetStatus status = _VideoSheetStatus.Closed;
  Widget? child;

  VideoInfo? _videoInfo;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    var rect = this.rect;
    rectController.value = rect;
    if (child == null) {
      child = widget.builder(context, scrollPhysics, rectController);
    }

    return Positioned(
      left: rect.left,
      right: rect.right,
      bottom: rect.bottom,
      top: rect.top,
      child: Opacity(
        opacity: _opacity,
        child: Material(
          color: Colors.white,
          elevation: 2,
          clipBehavior: Clip.hardEdge,
          child: status == _VideoSheetStatus.Closed ? null : OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: 0,
            minHeight: 0,
            maxWidth: size.width,
            maxHeight: size.height,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: NotificationListener<VideoSheetNotification>(
                child: Visibility(
                  key: ValueKey(_videoInfo?.key),
                  visible: _videoInfo?.key != null,
                  child: ValueWidget<VideoInfo>(
                    value: _videoInfo,
                    child: child!,
                  ),
                ),
                onNotification: (notification) {
                  if (notification is VideoSheetOpenNotification) {
                    open();
                  } else if (notification is VideoSheetCloseNotification) {
                    close();
                  }
                  return true;
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  RectValue get rect {
    var gap = _gap;
    return RectValue(
      left: gap,
      right: gap,
      top: top,
      bottom: _bottom,
      barSize: widget.barSize,
    );
  }

  double get _bottom {
    double topHeight = widget.maxHeight - widget.barSize - widget.bottomHeight;
    if (top < topHeight)
      return widget.bottomHeight * top / topHeight;
    else
      return widget.bottomHeight - (top - topHeight);
  }

  double get _gap {
    double topHeight = widget.maxHeight - widget.barSize - widget.bottomHeight;
    if (top < topHeight)
      return _Gap * top / topHeight;
    else
      return _Gap;
  }

  double get _opacity {
    double topHeight = widget.maxHeight - widget.barSize - widget.bottomHeight;
    if (top > topHeight) {
      double opacity = 1 - (top - topHeight) / widget.barSize;
      return math.max(0, opacity);
    }
    return 1;
  }

  @override
  void initState() {
    super.initState();

    scrollPhysics = _VideoSheetScrollPhysics(this);
    from = to = top = widget.maxHeight;

    rectController = ValueNotifier(rect);

    animation = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    animation.addListener(_update);
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
    rectController.dispose();
  }

  void _update() {
    setState(() {
      top = from * (1 - animation.value) + to * animation.value;
    });
  }

  bool onDrag(ScrollMetrics position, double offset) {
    animation.stop();
    switch (status) {
      case _VideoSheetStatus.Mini: {
        setState(() {
          top += offset;
          from = to = top;
        });
        return false;
      }
      case _VideoSheetStatus.Fullscreen: {
        if ((offset > 0 && position.pixels == 0) || top > 0) {
          setState(() {
            top += offset;
            from = to = top;
          });
          return false;
        }
        break;
      }
      case _VideoSheetStatus.Closed: {
        break;
      }
    }
    return true;
  }

  bool onDragOver(double velocity) {
    if (animation.isAnimating) return false;
    double topHeight = widget.maxHeight - widget.barSize - widget.bottomHeight;
    switch (status) {
      case _VideoSheetStatus.Mini: {
        if (top < topHeight - 200 || velocity > 200) {
          from = top;
          to = 0;
          setState(() {
            status = _VideoSheetStatus.Fullscreen;
          });
          animation.forward(from: 0).then((value) {
            from = to = top;
          });
        } else if (top > topHeight + widget.barSize / 2) {
          from = top;
          to = widget.maxHeight;
          animation.forward(from: 0).then((value) {
            from = to = top;
            setState(() {
              status = _VideoSheetStatus.Closed;
            });
          });
        } else {
          from = top;
          to = topHeight;
          animation.forward(from: 0).then((value) {
            from = to = top;
          });
        }
        return false;
      }
      case _VideoSheetStatus.Fullscreen: {
        if (top > 200 || (velocity < -200 && top > 20)) {
          from = top;
          to = topHeight;
          setState(() {
            status = _VideoSheetStatus.Mini;
          });
          animation.forward(from: 0).then((value) {
            from = to = top;
          });
          return false;
        } else if (top > 0) {
          from = top;
          to = 0;
          animation.forward(from: 0).then((value) {
            from = to = top;
          });
          return false;
        }
        break;
      }
      case _VideoSheetStatus.Closed: {
        break;
      }
    }

    return true;
  }

  void open() {
    from = top;
    to = 0;
    setState(() {
      status = _VideoSheetStatus.Fullscreen;
    });
    animation.forward(from: 0).then((value) {
      from = to = top;
    });
  }

  void play(VideoInfo videoInfo) {
    setState(() {
      _videoInfo = videoInfo;
    });
    open();
  }

  void close() {
    from = top;
    to = widget.maxHeight;
    animation.forward(from: 0).then((value) {
      from = to = top;
      setState(() {
        status = _VideoSheetStatus.Closed;
        _videoInfo = null;
      });
    });
  }

  @override
  void didUpdateWidget(covariant VideoSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.builder != widget.builder) {
      child = null;
    }
  }
}