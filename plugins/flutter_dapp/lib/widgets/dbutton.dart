
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
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
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
    switch (type) {
      case DButtonType.elevated: {
        return ElevatedButton(
            onPressed: onPressed,
            onLongPress: onLongPress,
            child: child
        );
      }
      case DButtonType.icon: {
        return IconButton(
          icon: child,
          onPressed: onPressed,
        );
      }
      case DButtonType.material: {
        return MaterialButton(
          child: child,
          onPressed: onPressed,
          onLongPress: onLongPress,
        );
      }
      case DButtonType.text: {
        return TextButton(
          onPressed: onPressed,
          onLongPress: onLongPress,
          child: child
        );
      }
    }
  }
}
