

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:kuma_player/kuma_player.dart';
import 'package:kuma_player/proxy_server.dart';
import 'dart:math' as math;
import 'tracker.dart';
import 'utils.dart';

typedef AnimatedWidgetBuilder<T> = Widget Function(BuildContext context, Widget child, T value);

class AnimatedWidget<T extends dynamic> extends StatefulWidget {
  final T value;
  final AnimatedWidgetBuilder<T> builder;
  final Duration duration;
  final Widget child;

  AnimatedWidget({
    Key key,
    @required this.value,
    @required this.builder,
    this.duration = const Duration(milliseconds: 300),
    this.child
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => StateAnimatedWidget<T>();
}

class StateAnimatedWidget<T extends dynamic> extends State<AnimatedWidget<T>> with SingleTickerProviderStateMixin {
  AnimationController controller;
  T from;
  T to;
  T current;

  T lerp(T from, T to, double a) {
    return from + (to - from) * a;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: controller,
        child: widget.child,
        builder: (context, child) {
          current = lerp(from, to, controller.value);
          return widget.builder(context, child, current);
        }
    );
  }

  @override
  void initState() {
    super.initState();
    from = to = current = widget.value;
    controller = AnimationController(
      vsync: this,
      duration: widget.duration
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      from = current;
      to = widget.value;
      controller.reset();
      controller.forward();
    }
  }
}

const double TRACKER_SIZE = 4;

class BufferedRangePainter extends CustomPainter {
  final List<BufferedRange> ranges;
  final Color color;
  Paint _paint;

  BufferedRangePainter({
    @required this.ranges,
    @required this.color
  }) {
    _paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (BufferedRange range in ranges) {
      double start = range.start * size.width, end = range.end * size.width;

      if (end - start < size.height) {
        canvas.drawCircle(
            Offset((start + end) / 2, size.height / 2),
            size.height/2,
            _paint
        );
      } else {
        canvas.drawRect(Rect.fromLTRB(
            start + size.height / 2,
            0,
            end - size.height / 2,
            size.height
        ), _paint);
        canvas.drawArc(
            Rect.fromLTRB(start, 0, start + size.height, size.height),
            math.pi/2, math.pi,
            true, _paint
        );
        canvas.drawArc(
            Rect.fromLTRB(end - size.height, 0, end, size.height),
            -math.pi/2, math.pi,
            true, _paint
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is BufferedRangePainter) {
      return ranges != oldDelegate.ranges;
    } else return true;
  }

}

class BufferedWidget extends StatefulWidget {

  final KumaPlayerController controller;

  BufferedWidget({
    this.controller,
  });

  @override
  State<StatefulWidget> createState() => BufferedWidgetState();
}
class BufferedWidgetState extends State<BufferedWidget> {

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, double.infinity),
      painter: BufferedRangePainter(
        ranges: widget.controller?.buffered ?? [],
        color: Color.fromARGB(0x66, 0xff, 0xff, 0xff)
      ),
    );
  }

  void onBuffered() {
    setState(() { });
  }

  @override
  void initState() {
    super.initState();
    widget.controller?.addOnBuffered(onBuffered);
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller?.removeOnBuffered(onBuffered);
  }

  @override
  void didUpdateWidget(BufferedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeOnBuffered(onBuffered);
      widget.controller?.addOnBuffered(onBuffered);
    }
  }
}

class PlayerSlider extends StatefulWidget {
  final KumaPlayerController controller;
  final VoidCallback onStartDrag;
  final VoidCallback onEndDrag;

  PlayerSlider({
    Key key,
    this.controller,
    this.onStartDrag,
    this.onEndDrag
  }): super(key: key);

  @override
  State<StatefulWidget> createState() => PlayerSliderState();
}

class PlayerSliderState extends State<PlayerSlider> {

  Duration _dragDuration;
  bool _isDragging = false;

  double _processTime(Duration position, Duration duration) {
    if (position == null || duration == null || duration.inMilliseconds == 0) return 0;
    return position.inMilliseconds / duration.inMilliseconds;
  }

  double _getPercent() {
    return _processTime(_dragDuration ?? widget.controller?.value?.position, widget.controller?.value?.duration);
  }

  void _onPointerDown(PointerDownEvent event) {
    widget.onStartDrag?.call();
    setState(() {
      _isDragging = true;
    });
  }

  void _onPointerUp(PointerUpEvent event) async {
    if (_dragDuration != null) {
      await widget.controller.seekTo(_dragDuration);
      _dragDuration = null;
    }
    widget.onEndDrag?.call();
    setState(() {
      _isDragging = false;
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    Duration duration = widget.controller?.value?.duration;
    Rect bounds = context.findRenderObject()?.semanticBounds;
    if (duration != null && bounds != null) {
      setState(() {
        double per = math.max(0, math.min(1, event.localPosition.dx / bounds.size.width));
        _dragDuration = duration * per;
      });
    }
  }

  static const double borderSize = 10;

  @override
  Widget build(BuildContext context) {
    return Listener(
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerMove: _onPointerMove,
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(left: borderSize, right: borderSize),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    width: double.infinity,
                    height: TRACKER_SIZE,
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                        color: Color.fromARGB(0x33, 0xff, 0xff, 0xff),
                        borderRadius: BorderRadius.all(Radius.circular(TRACKER_SIZE / 2))
                    ),
                    child: AnimatedWidget<double>(
                      duration: const Duration(milliseconds: 0),
                      value: _getPercent(),
                      builder: (context, child, value) {
                        return FractionallySizedBox(
                          child: child,
                          widthFactor: value,
                          heightFactor: 1,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.lightBlue,
                            borderRadius: BorderRadius.all(Radius.circular(TRACKER_SIZE / 2))
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: TRACKER_SIZE,
                    child: BufferedWidget(
                      controller: widget.controller,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: borderSize/2, right: borderSize/2),
                    child: Container(
                      child: AnimatedWidget<double>(
                        duration: const Duration(milliseconds: 0),
                        value: _getPercent(),
                        builder: (context, child, value) {
                          return LayoutBuilder(
                            builder: (context, constraints){
                              return Transform.translate(
                                  offset: Offset(
                                    constraints.biggest.width * (value - 0.5),
                                    0
                                  ),
                                child: child,
                              );
                            }
                          );
                        },
                        child: OverflowBox(
                          alignment: Alignment.center,
                          maxWidth: TRACKER_SIZE * 3,
                          maxHeight: TRACKER_SIZE * 3,
                          child: Tracker(
                            color: Colors.lightBlue,
                            appear: _isDragging,
                            size: TRACKER_SIZE * 3,
                            label: calculateTime(_dragDuration ?? widget.controller?.value?.position),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        )
    );
  }

  void _onPlayerEvent() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onPlayerEvent);
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller?.removeListener(_onPlayerEvent);
  }

  @override
  void didUpdateWidget(PlayerSlider oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller?.disposed != true)
        oldWidget.controller?.removeListener(_onPlayerEvent);
      widget.controller?.addListener(_onPlayerEvent);
    }
  }
}