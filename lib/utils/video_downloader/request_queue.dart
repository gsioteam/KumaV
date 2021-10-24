
import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

typedef LoadCallback = void Function(bool secuess, List<List<int>>? chunks);
typedef ResponseCallback = void Function(Response<ResponseBody>? response);
typedef CompleteCallback = void Function(bool secuess, List<List<int>>? chunks);

class LoadListener {
  int? reach;
  LoadCallback cb;

  LoadListener(this.cb, [this.reach]);
}

class RequestItem {
  List<List<int>> chunks = [];
  String url;
  RequestQueue queue;
  Set<LoadListener> _listeners = {};
  Set<ResponseCallback> _responseCallbacks = {};
  int _length = 0;
  late Dio dio;
  Response<ResponseBody>? _response;
  Map<String, dynamic>? headers;
  String method = "GET";
  CompleteCallback? onComplete;
  VoidCallback? onFailed;
  bool _isComplete = false;
  bool get isComplete => _isComplete;

  RequestItem(this.url, this.queue);

  void _receive(List<int> chunk) {
    chunks.add(chunk);
    _length += chunk.length;
    Set<LoadListener> needRemove = {};
    _listeners.forEach((element) {
      if (element.reach != null && element.reach! <= _length) {
        element.cb.call(true, chunks);
        needRemove.add(element);
      }
    });
    _listeners.removeAll(needRemove);
  }

  void _complete() {
    _isComplete = true;
    _listeners.forEach((element) {
      element.cb.call(true, chunks);
    });
    _listeners.clear();
    queue._finished(this);
    onComplete?.call(true, chunks);
  }

  void _failed() {
    _listeners.forEach((element) {
      element.cb.call(false, null);
    });
    _listeners.clear();
    queue._finished(this);
    onFailed?.call();
    onComplete?.call(false, null);
  }

  void _receiveResponse() {
    var set = Set.from(_responseCallbacks);
    set.forEach((element) {
      element.call(_response);
    });
  }

  bool _loading = false;
  void request() async {
    if (_loading) return;
    _loading = true;
    try {
      await _start();
    } finally {
      _loading = false;
    }
  }

  Future<void> _start() async {
    Uri uri = Uri.parse(url);
    dio = Dio(BaseOptions(
      headers: headers,
      responseType: ResponseType.stream
    ));
    try {
      _response = await dio.requestUri<ResponseBody>(
          uri
      );
    } catch (e) {
      _response = null;
      _receiveResponse();
      _failed();
      return;
    }
    if (_response!.statusCode != null && _response!.statusCode! >= 200 && _response!.statusCode! < 300) {
      _receiveResponse();
      await for (var chunk in _response!.data!.stream) {
        _receive(chunk);
      }
      _complete();
    } else {
      _response = null;
      _receiveResponse();
      _failed();
    }
  }

  void stop() {
    try {
      dio.clear();
      dio.close(force: true);
    } catch (e) {
    }
    queue._finished(this);
  }

  void addListener(LoadListener listener) {
    if (isComplete) {
      listener.cb.call(true, chunks);
    } else {
      _listeners.add(listener);
    }
  }

  Stream<List<int>> streamChunks() async* {
    for (var chunk in chunks) {
      yield chunk;
    }
  }

  Future<List<List<int>>> read([int? reach]) {
    if (reach != null && _length >= reach)
      return SynchronousFuture(chunks);
    Completer<List<List<int>>> completer = Completer();
    _listeners.add(LoadListener((success, chunks) {
      if (success)
        completer.complete(chunks);
      else
        completer.completeError(Exception());
    }, reach));
    return completer.future;
  }

  Future<List<int>> readPart(int start, int end) async {
    var chunks = await read(end);
    int offset = 0;
    List<List<int>> newChunks = [];
    for (var chunk in chunks) {
      int soff = start - offset, eoff = end - offset;
      if (eoff <= 0) break;
      else if (soff <= chunk.length)
        newChunks.add(chunk.sublist(math.max(0, soff), math.min(chunk.length, eoff)));
      offset = offset + chunk.length;
    }
    return newChunks.expand<int>((element) => element).toList();
  }

  Future<Response<ResponseBody>> getResponse() {
    if (_response != null) {
      return SynchronousFuture(_response!);
    }

    Completer<Response<ResponseBody>> completer = Completer();
    void receiveResponse(Response<ResponseBody>? response) {
      _responseCallbacks.remove(receiveResponse);
      if (response == null) {
        completer.completeError(Exception());
      } else {
        completer.complete(response);
      }
    }
    _responseCallbacks.add(receiveResponse);
    return completer.future;
  }
}

class RequestQueue {
  Map<String, RequestItem> items = Map();

  RequestItem start(String url, {
    String? key,
    Map<String, dynamic>? headers,
    String method = "GET"
  }) {
    key = key ?? url;
    RequestItem? item = items[key];
    if (item == null) {
      item = RequestItem(url, this);
      item.headers = headers;
      item.method = method;
      items[key] = item;
    }
    item.request();
    return item;
  }

  void _finished(RequestItem item) {
    items.removeWhere((key, value) => item == value);
  }
}
