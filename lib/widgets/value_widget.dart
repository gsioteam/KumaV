
import 'package:flutter/widgets.dart';

class ValueWidget<T> extends InheritedWidget {

  final T? value;

  ValueWidget({
    Key? key,
    required Widget child,
    required this.value,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    if (oldWidget is ValueWidget<T>) {
      return value != oldWidget.value;
    }
    return true;
  }

  static T? of<T>(BuildContext context) {
    var widget = context.dependOnInheritedWidgetOfExactType<ValueWidget<T>>();
    return widget?.value;
  }
}