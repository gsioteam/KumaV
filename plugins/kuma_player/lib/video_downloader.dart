

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:kuma_player/load_item.dart';
import 'package:kuma_player/proxy_server.dart';
import 'package:path/path.dart' as path;

enum DownloadState {
  Stop,
  Downloading,
  Complete
}


class TimeoutError extends Error {
  @override
  String toString() {
    return "No data received in 15 seconds";
  }
}

class ExceptionError extends Error {
  Exception exception;

  ExceptionError(this.exception);

  @override
  String toString() => exception.toString();
}

class VideoDownloader {
  ProxyItem _proxyItem;
  double _progress = 0;
  bool _progressDirty = true;
  bool _dependDirty = false;
  DownloadState _state = DownloadState.Stop;

  ProxyItem get proxyItem => _proxyItem;

  VoidCallback onProgress;
  VoidCallback onSpeed;
  VoidCallback onState;
  void Function(Error) onError;

  bool _loading = false;

  VideoDownloader(String url, {Map<String, String> headers}) {
    ProxyServer server = ProxyServer.instance;
    _proxyItem = server.get(url, headers: headers);
    _proxyItem.retain();

    try {
      _proxyItem.checkBuffered();
      int count = 0;
      for (var item in _proxyItem.loadItems) {
        if (item.loaded) count++;
      }
      if (count == _proxyItem.loadItems.length) {
        _state = DownloadState.Complete;
        onState?.call();
      }
    } catch (e) {

    }

    _proxyItem.addOnBuffered(_onBuffered);
    _proxyItem.addOnSpeed(_onSpeed);
  }

  void dispose() {
    _proxyItem?.removeOnSpeed(_onSpeed);
    _proxyItem?.removeOnBuffered(_onBuffered);
    _proxyItem?.release();
  }

  void _onBuffered() {
    _progressDirty = true;
    _sizeDirty = true;
    if (_state == DownloadState.Downloading) {
      onProgress?.call();
    }
  }

  double get progress {
    if (_progressDirty && _proxyItem != null) {
      var buffered = _proxyItem.buffered;
      _progress = 0;
      for (var part in buffered) {
        _progress += (part.end - part.start);
      }
      _progressDirty = false;
    }
    return _progress;
  }

  int _size = 0;
  bool _sizeDirty = true;
  int get size {
    if (_sizeDirty) {
      _size = 0;
      for (var item in _proxyItem.loadItems) {
        if (item.loaded) {
          _size += item.size;
        }
      }
      _sizeDirty = false;
    }
    return _size;
  }

  DownloadState get state => _state;

  void checkState() {
    if (_state == DownloadState.Downloading) {
      if (_dependDirty) {
        _dependDirty = false;
        _onBuffered();
      }
      _startDownload();
    }
  }

  Future<void> _startDownload() async {
    if (!_loading) {
      _loading = true;

      try {
        int count = 0;
        for (int i = 0; i < proxyItem.loadItems.length; ++i) {
          LoadItem item = proxyItem.loadItems[i];
          if (!item.loaded) {
            var stream = item.read();
            List<int> list = [];
            await for (var buf in stream) {
              if (_state != DownloadState.Downloading) {
                break;
              }
              list.addAll(buf);
            }
            proxyItem.processBuffer(item, list);
            count++;
          } else {
            count++;
          }
          if (_state != DownloadState.Downloading) {
            break;
          }
        }
        if (count == proxyItem.loadItems.length) {
          _state = DownloadState.Complete;
          onState?.call();
          onSpeed?.call();
        }
      } catch (e) {
        onError?.call(e is Error ? e : ExceptionError(e));
        _state = DownloadState.Stop;
        onState?.call();
        onSpeed?.call();
      }

      _loading = false;
    }
  }

  void start() {
    if (_state == DownloadState.Stop) {
      _speeds.clear();
      _state = DownloadState.Downloading;
      onState?.call();
      checkState();
    }
  }

  void stop() {
    if (_state == DownloadState.Downloading) {
      _state = DownloadState.Stop;
      onState?.call();
      onSpeed?.call();
    }
  }

  static const int MAX_SIZE = 15;
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