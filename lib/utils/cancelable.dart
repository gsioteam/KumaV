library cancelable;

import 'dart:async';

class CancelError extends Error {
}

class Cancelable<T> {
  Completer<T> completer;
  bool _canceled = false;

  Future<T> get future => completer.future;

  bool get isCompleted {
    if (_canceled) {
      return true;
    } else {
      return completer.isCompleted;
    }
  }

  Cancelable(Future<T> future) {
    completer = Completer();
    _wait(future);
  }

  _wait(Future<T> future) async {
    T result = await future;
    if (!_canceled && !completer.isCompleted) {
      completer.complete(result);
    }
  }

  void cancel() {
    _canceled = true;
    if (!completer.isCompleted)
      completer.completeError(CancelError());
  }
}
