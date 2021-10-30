
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class View extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;
  final Widget? child;
  final bool animate;
  final Duration duration;

  View({
    Key? key,
    this.width,
    this.height,
    this.color,
    this.child,
    this.animate = false,
    this.duration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    Material? mat;
    if (color != null) {
      mat = Material(
        color: color,
        child: child,
      );
    }

    if (animate) {
      return AnimatedContainer(
        duration: duration,
        width: width,
        height: height,
        child: mat == null ? child : mat,
      );
    } else {
      return Container(
        width: width,
        height: height,
        child: mat == null ? child : mat,
      );
    }
  }
}