
import 'package:flutter/material.dart';
import 'dart:math' as math;

enum _VideoSheetStatus {
  Closed,
  Mini,
  Fullscreen,
}

typedef VideoContentBuilder = Widget Function(BuildContext context, ScrollPhysics physics, double height);

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

class VideoSheetState extends State<VideoSheet> with SingleTickerProviderStateMixin {
  late _VideoSheetScrollPhysics scrollPhysics;
  late double top;
  late AnimationController animation;
  double from = 0;
  double to = 0;

  _VideoSheetStatus status = _VideoSheetStatus.Closed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _gap,
      right: _gap,
      bottom: _bottom,
      top: top,
      child: Opacity(
        opacity: _opacity,
        child: Material(
          color: Colors.white,
          elevation: 2,
          child: status == _VideoSheetStatus.Closed ? null : widget.builder(context, scrollPhysics, top),
        ),
      ),
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

  void show() {
    from = top;
    to = 0;
    setState(() {
      status = _VideoSheetStatus.Fullscreen;
    });
    animation.forward(from: 0).then((value) {
      from = to = top;
    });
  }
}