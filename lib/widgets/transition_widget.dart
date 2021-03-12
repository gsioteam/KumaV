
import 'package:flutter/material.dart';

typedef TransitionWidgetBuilder<T> = Widget Function(BuildContext context, Widget child, T value);
typedef TransitionMixer<T> = T Function(T a, T b, double alpha);

class TransitionWidget<T> extends StatefulWidget {
  final Widget child;
  final TransitionWidgetBuilder<T> builder;
  final TransitionMixer<T> lerp;
  final T value;
  final Duration duration;

  TransitionWidget({
    Key key,
    this.child,
    @required this.builder,
    @required this.lerp,
    @required this.value,
    this.duration = const Duration(milliseconds: 300)
  })
      : assert(builder != null),
        assert(lerp != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() => TransitionWidgetState<T>();

}

class TransitionWidgetState<T> extends State<TransitionWidget<T>> with SingleTickerProviderStateMixin {

  AnimationController controller;
  T from;
  T to;
  T current;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: widget.child,
      builder: (context, child) {
        current = widget.lerp(from, to, controller.value);
        return widget.builder(context, child, current);
      },
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
  void didUpdateWidget(TransitionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      from = current;
      to = widget.value;
      controller.forward(from: 0);
    }
  }
}