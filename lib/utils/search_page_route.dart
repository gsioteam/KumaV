

import 'package:flutter/widgets.dart';

class _DisplayRectClipper extends CustomClipper<Rect> {

  Offset center;
  double value;

  _DisplayRectClipper(this.center, this.value);

  @override
  Rect getClip(Size size) {
    double length = (center - Offset(0, size.height)).distance;
    return Rect.fromCircle(
        center: center,
        radius: length * value
    );
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return !(oldClipper is _DisplayRectClipper) || (oldClipper as _DisplayRectClipper).value != value;
  }
}

class SearchPageRoute extends PageRoute {

  final WidgetBuilder builder;
  final Offset center;
  final bool maintainState;
  final Duration duration;

  SearchPageRoute({
    required this.builder,
    required this.center,
    this.maintainState = false,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return ClipOval(
          clipper: _DisplayRectClipper(center, animation.value),
          child: child,
        );
      },
      child: builder(context),
    );
  }

  @override
  Duration get transitionDuration => duration;

}