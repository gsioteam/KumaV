
import 'dart:async';

import 'package:flutter/material.dart';

class OverlayDialog<T> {
  final Widget Function(BuildContext context) builder;
  OverlayEntry entry;

  OverlayDialog({
    this.builder,

  });

  Completer<T> completer;
  Future<T> show(BuildContext context) {
    if (entry == null) {
      completer = Completer();
      entry = OverlayEntry(
          builder: (context) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: builder(context),
              ),
            );
          }
      );
      Overlay.of(context).insert(entry);
      return completer.future;
    } else {
      throw new Exception("Dialog is already showing.");
    }
  }

  void dismiss([T result]) {
    completer?.complete(result);
    entry?.remove();
    entry = null;
  }

  bool get display => entry != null;
}