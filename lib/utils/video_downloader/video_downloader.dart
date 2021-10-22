

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'load_item.dart';
import 'proxy_server.dart';
import 'package:path/path.dart' as path;

import 'load_item.dart';

enum DownloadState {
  Stop,
  Downloading,
  Complete
}

class DownloadTaskItem {
  LoadItem item;
  bool canceled = false;

  int _loaded = 0;
  int get loaded => _loaded;

  DownloadTaskItem(this.item);

  Future<Error?> download() async {
    try {
      if (!await item.loaded) {
        var stream = item.read();
        _loaded = 0;
        List<int> list = [];
        await for (var buf in stream) {
          if (canceled) break;
          list.addAll(buf);
          _loaded += buf.length;
        }
        item.proxyItem.processBuffer(item, list);
      }
      return null;
    } catch (e) {
      return e is Error ? e : ExceptionError(e.toString());
    }
  }

  void stop() {
    canceled = true;
  }

  DownloadTaskItem clone() {
    return DownloadTaskItem(item);
  }
}

class DownloadTaskQueue {
  Set<DownloadTaskItem> downloading = Set();
  int maxDownloading = 3;
  int maxFailed = 5;
  Queue<DownloadTaskItem> queue = Queue();
  void Function(bool success)? onComplete;

  int _failedCount = 0;

  bool _stop = true;

  Error? lastError;

  void start() async {
    if (!_stop) return;
    _stop = false;

    for (int i = downloading.length; i < maxDownloading; ++i) {
      if (downloading.length >= maxDownloading || queue.length == 0) break;
      _startItem();
      await Future.delayed(Duration(seconds: 1));
    }
  }

  void _startItem() async {
    if (_stop) return;
    if (queue.length == 0 || _failedCount >= maxFailed || downloading.length >= maxDownloading) return;
    DownloadTaskItem item = queue.removeFirst();
    downloading.add(item);
    Error? err = await item.download();
    downloading.remove(item);
    if (err != null) {
      _failedCount++;
      lastError = err;
      queue.addLast(item.clone());
      if (downloading.length == 0 && _failedCount >= maxFailed) {
        // failed
        _stop = true;
        onComplete?.call(true);
        return;
      }
    } else {
      _failedCount = 0;
    }
    if (queue.length == 0 && downloading.length == 0) {
      // complete
      _stop = true;
      onComplete?.call(false);
    } else {
      _startItem();
    }
  }

  void stop() {
    if (_stop) return;
    _stop = true;
    for (var item in downloading) {
      item.stop();
      queue.addFirst(item.clone());
    }
    downloading.clear();
  }

  void add(LoadItem item) {
    queue.addLast(DownloadTaskItem(item));
    _startItem();
  }

  int downloadingSize() {
    int size = 0;
    for (var item in downloading) {
      size += item.loaded;
    }
    return size;
  }
}

class TimeoutError extends Error {
  @override
  String toString() {
    return "No data received in ${VideoDownloader.MAX_SIZE} seconds";
  }
}

class ExceptionError extends Error {
  String error;

  ExceptionError(this.error);

  @override
  String toString() => error;
}

class VideoDownloader {
  late ProxyItem _proxyItem;
  DownloadState _state = DownloadState.Stop;

  ProxyItem get proxyItem => _proxyItem;

  VoidCallback? onProgress;
  VoidCallback? onSpeed;
  VoidCallback? onState;
  void Function(Error)? onError;
  DownloadTaskQueue? _queue;

  late Completer<void> _completer;

  late Future<void> _ready;
  Future<void> get ready => _ready;
  Set<String> _added = Set();

  int _multiThreadLimit = 3;
  int get multiThreadLimit => _multiThreadLimit;
  set multiThreadLimit(int count) {
    if (_multiThreadLimit != count) {
      _multiThreadLimit = count;
      _queue?.maxDownloading = count;
    }
  }

  VideoDownloader(String url, {Map<String, String>? headers}) {
    ProxyServer server = ProxyServer.instance;
    _proxyItem = server.get(url, headers: headers);
    _proxyItem.retain();

    _ready = _checkState();

    _proxyItem.addOnBuffered(_onBuffered);
    _proxyItem.addOnSpeed(_onSpeed);
  }

  int loaded = 0;
  Future<void> _checkState() async {
    _completer = Completer();
    try {
      bool setup = _queue == null;
      int size = 0;
      int totalWeight = 0, loadedWeight = 0;
      if (setup) {
        _queue = DownloadTaskQueue();
        _queue!.maxDownloading = multiThreadLimit;
      }
      await _proxyItem.prepareDownload();
      await _proxyItem.checkBuffered();
      int count = 0;
      for (var item in _proxyItem.loadItems) {
        if (await item.loaded) {
          count++;
          if (count > loaded)
            loaded = count;
          size += await item.size;
          loadedWeight += item.weight;
        } else {
          if (!_added.contains(item.cacheKey)) {
            _queue!.add(item);
            _added.add(item.cacheKey);
          }
        }
        totalWeight += item.weight;
      }
      if (count == _proxyItem.loadItems.length && _state != DownloadState.Complete) {
        _state = DownloadState.Complete;
        onState?.call();
      } else if (setup) {
        _queue!.onComplete = (failed) {
          if (failed) {
            _state = DownloadState.Stop;
            onError?.call(_queue!.lastError!);
          } else {
            _state = DownloadState.Complete;
          }
          onState?.call();
        };
      }
      _size = size;
      if (_state == DownloadState.Downloading) {
        onProgress?.call();
      }
    } catch (e) {
      print(e);
    }
    _completer.complete();
  }

  void dispose() {
    _proxyItem.removeOnSpeed(_onSpeed);
    _proxyItem.removeOnBuffered(_onBuffered);
    _proxyItem.release();
  }

  void _onBuffered() {
    if (_completer.isCompleted) {
      _checkState();
    }
  }

  double get progress {
    if (state == DownloadState.Complete) return 1;
    if (_proxyItem is SingleProxyItem) {
      if (_proxyItem.total == 0) return 0;
      double p = size / _proxyItem.total;
      if (p < 0) return 0;
      if (p > 1) return 1;
      return p;
    } else {
      if (_proxyItem.loadItems.length == 0) return 0;
      double p = 0;
      if (_proxyItem.buffered != null) {
        for (var buffered in _proxyItem.buffered!) {
          p += (buffered.end - buffered.start);
        }
      }
      if (p < 0) return 0;
      if (p > 1) return 1;
      return p;
    }
  }

  int _size = 0;
  int get size {
    return _size + (_queue?.downloadingSize() ?? 0);
  }

  DownloadState get state => _state;

  void start() {
    if (_state == DownloadState.Stop) {
      _speeds.clear();
      _state = DownloadState.Downloading;
      onState?.call();
      _queue?.start();
    }
  }

  void stop() {
    if (_state == DownloadState.Downloading) {
      _proxyItem.stopLoading();
      _state = DownloadState.Stop;
      onState?.call();
      onSpeed?.call();
      _queue?.stop();
    }
  }

  Future<void> remove() async {
    stop();
    await _proxyItem.remove();
    dispose();
  }

  static const int MAX_SIZE = 30;
  Queue<int> _speeds = Queue();
  void _onSpeed(int speed) {
    if (_state == DownloadState.Downloading) {
      _speeds.add(speed);
      if (_speeds.length >= MAX_SIZE) {
        bool hasSpeed = false;
        for (var spd in _speeds) {
          if (spd != 0) {
            hasSpeed = true;
            break;
          }
        }
        if (!hasSpeed) {
          onError?.call(TimeoutError());
          _state = DownloadState.Stop;
          onState?.call();
        }
      }
      while (_speeds.length > MAX_SIZE) {
        _speeds.removeFirst();
      }
      onSpeed?.call();
    }
  }

  int get speed {
    if (_state == DownloadState.Downloading) {
      int total = 0;
      for (var speed in _speeds) {
        total += speed;
      }
      if (_speeds.length == 0) return 0;
      return (total / _speeds.length).round();
    } else {
      return 0;
    }
  }
}