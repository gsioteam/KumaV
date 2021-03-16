
import 'package:flutter/cupertino.dart';

class SpinItem extends StatefulWidget {
  final Widget child;
  final bool animated;

  SpinItem({Key key, this.child, this.animated = false}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SpinItemState();
}

class SpinItemState extends State<SpinItem> with SingleTickerProviderStateMixin {

  AnimationController animationController;

  @override
  void initState() {
    animationController = AnimationController(
        vsync: this,
        duration: Duration(seconds: 1)
    );
    super.initState();
    if (widget.animated) {
      startAnimation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      child: this.widget.child,
      builder: (BuildContext context, Widget _widget) {
        return Transform.rotate(
          angle: animationController.value * -6.3,
          child: _widget,
        );
      },
    );
  }

  @override
  void didUpdateWidget(covariant SpinItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animated != oldWidget.animated) {
      if (widget.animated) {
        startAnimation();
      } else {
        stopAnimation();
      }
    }
  }

  void startAnimation() {
    animationController.repeat();
  }


  void stopAnimation() {
    animationController.stop();
    animationController.reset();
  }

  bool get isLoading => animationController.isAnimating;

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }
}