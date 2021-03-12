
import 'package:flutter/material.dart';

class Tracker extends StatefulWidget {
  final Color color;
  final bool appear;
  final double size;
  final String label;

  Tracker({
    Key key,
    this.color,
    this.appear = false,
    this.size,
    this.label
  });

  @override
  State<StatefulWidget> createState() => TrackerState();
}

class TrackerState extends State<Tracker> with SingleTickerProviderStateMixin {
  AnimationController controller;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      AnimatedBuilder(
        animation: controller,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.all(Radius.circular(widget.size/2))
          ),
        ),
        builder: (context, child) {
          return Opacity(
            opacity: controller.value,
            child: Transform.scale(
              scale: controller.value,
              child: child,
            ),
          );
        },
      ),
    ];
    if (widget.label != null) {
      children.add(
          OverflowBox(
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: Transform.translate(
              offset: Offset(0, -24),
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: controller.value,
                    child: child,
                  );
                },
                child: Container(
                  padding: EdgeInsets.fromLTRB(6, 4, 6, 4),
                  decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.all(Radius.circular(4))
                  ),
                  child: Text(widget.label, style: Theme.of(context).textTheme.bodyText1.copyWith(color: Colors.white),),
                ),
              ),
            ),
          )
      );
    }
    return Stack(
      children: children,
    );
  }

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 300)
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(Tracker oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.appear != widget.appear) {
      if (widget.appear) {
        controller.forward();
      } else {
        controller.reverse();
      }
    }
  }
}