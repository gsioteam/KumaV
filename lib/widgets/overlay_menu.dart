

import 'package:flutter/material.dart';
import '../utils/controller.dart';

enum MenuStatus {
  Hidden,
  Showing
}

enum MenuEvent {
  Miss
}

class OverlayMenuItem {
  final Widget child;
  final VoidCallback onPressed;

  OverlayMenuItem({
    this.child,
    this.onPressed
  });
}

class OverlayMenu extends StatefulWidget {

  final Widget Function(BuildContext context, VoidCallback onPressed) builder;
  final List<OverlayMenuItem> items;
  final Controller<MenuStatus, MenuEvent, void> controller;

  OverlayMenu({
    this.builder,
    this.items,
    this.controller,
  });

  @override
  State<StatefulWidget> createState() => OverlayMenuState();
}

class OverlayMenuState extends State<OverlayMenu> {
  OverlayEntry entry;

  @override
  Widget build(BuildContext context) {
    GlobalKey key = GlobalKey();
    return Container(
      key: key,
      child: widget.builder(context, () {
        _onPressed(context, key);
      }),
    );
  }

  void _onPressed(BuildContext context, GlobalKey key) {
    var object = key.currentContext.findRenderObject();
    var translation = object?.getTransformTo(null)?.getTranslation();
    var size = object?.semanticBounds?.size;
    Rect rect;
    if (translation != null) {
      double x = translation.x, y = translation.y;
      rect = Rect.fromLTWH(x, y, size.width, size.height);
    } else {
      rect = Rect.fromLTWH(0, 0, size.width, size.height);
    }
    entry = OverlayEntry(
        builder: (context) {
          return OverlayMenuBody(
            children: widget.items,
            position: rect,
            onComplete: () {
              removeEntry();
            },
          );
        }
    );
    Overlay.of(context).insert(entry);
  }

  @override
  void initState() {
    super.initState();

    widget.controller?.onEvent = (event) {
      switch (event) {
        case MenuEvent.Miss: {
          removeEntry();
        }
      }
    };
    widget.controller?.onStatus = () {
      return entry == null ? MenuStatus.Hidden : MenuStatus.Showing;
    };
  }

  void removeEntry() {
    entry?.remove();
    entry = null;
  }
}

class MenuClipper extends CustomClipper<Rect> {
  double percent;

  MenuClipper(this.percent);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width, size.height * percent);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) {
    if (oldClipper is MenuClipper) {
      return percent != oldClipper.percent;
    }
    return true;
  }

}

class OverlayMenuBody extends StatefulWidget {
  final List<OverlayMenuItem> children;
  final Rect position;
  final VoidCallback onComplete;

  OverlayMenuBody({
    this.children,
    this.position,
    this.onComplete
  });

  @override
  State<StatefulWidget> createState() => OverlayMenuBodyState();
}

class OverlayMenuBodyState extends State<OverlayMenuBody> with SingleTickerProviderStateMixin {

  AnimationController controller;

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    List<Widget> children = [];
    widget.children.forEach((element) {
      children.add(
        TextButton(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all(Colors.white)
          ),
          child: element.child,
          onPressed: () {
            element.onPressed();
            miss();
          },
        )
      );
    });
    double left, right, top, bottom;
    var center = widget.position.center;
    if (center.dx < size.width / 2) {
      left = widget.position.left;
    } else {
      right = size.width - widget.position.right;
    }
    if (center.dy < size.height / 2) {
      top = widget.position.top;
    } else {
      bottom = size.height - widget.position.bottom;
    }
    return Stack(
      children: [
        Listener(
          child: Container(
            width: size.width,
            height: size.height,
            color: Colors.transparent,
          ),
          onPointerDown: (e) {
            miss();
          },
        ),
        Positioned(
          left: left,
          right: right,
          top: top,
          bottom: bottom,
          child: AnimatedBuilder(
            child: Container(
              margin: EdgeInsets.all(2),
              decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey,
                        offset: Offset(1, 1),
                        blurRadius: 2
                    )
                  ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: children,
              ),
            ),
            animation: controller,
            builder: (context, child) {
              return ClipRect(
                child: child,
                clipper: MenuClipper(controller.value),
              );
            },
          )
        )
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300)
    );
    controller.value = 0;
    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void miss() async {
    if (controller.isAnimating) return;
    await controller.reverse();
    widget.onComplete?.call();
  }
}