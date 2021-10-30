
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class BorderedMenuButton<T> extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPopup;
  final VoidCallback? onCanceled;
  final List<PopupMenuEntry<T>> items;
  final PopupMenuItemSelected<T>? onSelected;
  final EdgeInsets padding;

  BorderedMenuButton({
    Key? key,
    required this.child,
    required this.items,
    this.onPopup,
    this.onCanceled,
    this.onSelected,
    this.padding = const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 4
    ),
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _BorderedMenuButtonState<T>();

}

class _BorderedMenuButtonState<T> extends State<BorderedMenuButton<T>> {
  GlobalKey _globalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      key: _globalKey,
      child: DefaultTextStyle(
        style: TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        child: IconTheme(
            data: IconThemeData(
              color: Colors.white,
            ),
            child: widget.child
        ),
      ),
      style: OutlinedButton.styleFrom(
        primary: Colors.white,
        side: BorderSide(
          color: Colors.white,
        ),
        minimumSize: Size.zero,
        padding: widget.padding,
      ),
      onPressed: () async {
        var renderObject = _globalKey.currentContext?.findRenderObject();
        var transform = renderObject?.getTransformTo(null);
        if (transform != null) {
          var rect = renderObject!.semanticBounds;
          var leftTop = rect.topLeft;
          var point = transform.applyToVector3Array([leftTop.dx, leftTop.dy, 0]);

          widget.onPopup?.call();
          var value = await showMenu<T>(
            context: context,
            position: RelativeRect.fromLTRB(
              point[0],
              point[1],
              point[0] + rect.width,
              point[1] + rect.height,
            ),
            items: widget.items,
          );
          if (value != null) {
            widget.onSelected?.call(value);
          } else {
            widget.onCanceled?.call();
          }
        }
      },
    );
  }
}