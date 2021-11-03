
import 'dart:async';

import 'package:glib/core/core.dart';
import 'package:glib/utils/git_repository.dart';
import 'package:kumav/utils/plugin.dart';
import 'progress_dialog.dart';

class GitError extends Error {
  final String msg;

  GitError(this.msg);

  @override
  String toString() => msg;
}

typedef GitItemBuilder = Stream<GitActionValue> Function();

class GitItem extends ProgressItem {
  GitAction? action;
  GitItemBuilder builder;
  bool _canceled = false;
  int retryCount = 5;

  GitItem(this.builder, String defaultText) {
    this.defaultText = defaultText;
    start();
  }

  void start() async {
    late String lastError;
    for (int i = 0; i < retryCount; ++i) {
      try {
        await _run();
      } catch (e) {
        lastError = e.toString();
        continue;
      }
      complete();
      return;
    }
    fail(lastError);
  }

  Future<void> _run() async {
    this.progress(defaultText);
    String? error;

    Stream<GitActionValue> stream = builder();
    await for (var value in stream) {
      if (_canceled) return;
      action = value.action;
      this.progress("${value.label} (${value.loaded}/${value.total})");
      error = value.error;
    }
    action = null;
    if (error != null) {
      throw GitError(error);
    }
  }

  @override
  void cancel() {
    _canceled = true;
    action?.cancel();
  }

  @override
  void complete() {
    super.complete();
  }

  @override
  void fail(String msg) {
    super.fail(msg);
  }

  @override
  void retry() {
    action?.release();
    start();
  }
}