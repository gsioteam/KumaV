
import 'package:flutter/material.dart';

import '../dwidget.dart';

enum DButtonType {
  elevated,
  text,
  icon,
  material,
}

class DButton extends StatelessWidget {

  final Widget child;
  final String? onPressed;
  final String? onLongPress;
  final DButtonType type;

  DButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.type = DButtonType.elevated,
  }) : super(key: key);



  @override
  Widget build(BuildContext context) {
    VoidCallback? onPressedCallback = onPressed == null ? null : () {
      var controller = DWidget.of(context)?.controller;
      controller?.invoke(onPressed!);
    };
    VoidCallback? onLongPressCallback = onLongPress == null ? null : () {
      var controller = DWidget.of(context)?.controller;
      controller?.invoke(onLongPress!);
    };
    switch (type) {
      case DButtonType.elevated: {
        return ElevatedButton(
            onPressed: onPressedCallback,
            onLongPress: onLongPressCallback,
            child: child
        );
      }
      case DButtonType.icon: {
        return IconButton(
          icon: child,
          onPressed: onPressedCallback,
        );
      }
      case DButtonType.material: {
        return MaterialButton(
          child: child,
          onPressed: onPressedCallback,
          onLongPress: onLongPressCallback,
        );
      }
      case DButtonType.text: {
        return TextButton(
          onPressed: onPressedCallback,
          onLongPress: onLongPressCallback,
          child: child
        );
      }
    }
  }
}
