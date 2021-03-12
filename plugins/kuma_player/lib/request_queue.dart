
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;

typedef LoadCallback = void Function(List<List<int>> chunks);
typedef ResponseCallback = void Function(http.StreamedResponse response);
typedef CompleteCallback = void Function(List<List<int>> chunks);

class _LoadListener {
  int reach;
  LoadCallback cb;

  _LoadListener(this.cb, [this.reach]);
}

class RequestItem {
  List<List<int>> chunks = List();
  String url;
  RequestQueue queue;
  Set<_LoadListener> _listeners = Set();
  Set<ResponseCallback> _responseCallbacks = {};
  int _length = 0;
  http.StreamedResponse _response;
  Map<String, String> headers;
  String method;
  CompleteCallback onComplete;

  RequestItem(this.url, this.queue);

  void _receive(List<int> chunk) {
    chunks.add(chunk);
    _length += chunk.length;
    Set<_LoadListener> needRemove = {};
    _listeners.forEach((element) {
      if (element.reach != null && element.reach <= _length) {
        element.cb?.call(chunks);
        needRemove.add(element);
      }
    });
    _listeners.removeAll(needRemove);
  }

  void _complete() {
    _listeners.forEach((element) {
      element.cb?.call(chunks);
    });
    _listeners.clear();
    queue._finished(this);
    onComplete?.call(chunks);
  }

  void _receiveResponse() {
    _responseCallbacks.forEach((element) {
      element.call(_response);
    });
  }

  void _start() async {
    var request = http.Request(method, Uri.parse(url));
    if (headers != null) request.headers.addAll(headers);
    var response = await request.send();
    _response = response;
    _receiveResponse();
    await for (var chunk in response.stream) {
      _receive(chunk);
    }
    _complete();
  }

  Future<List<List<int>>> read([int reach]) {
    if (reach != null && _length >= reach)
      return SynchronousFuture(chunks);
    Completer<List<List<int>>> completer = Completer();
    _listeners.add(_LoadListener((chunks) {
      completer.complete(chunks);
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

  Future<http.StreamedResponse> getResponse() {
    if (_response != null) {
      return SynchronousFuture(_response);
    }

    Completer<http.StreamedResponse> completer = Completer();
    _responseCallbacks.add((response) {
      completer.complete(response);
    });
    return completer.future;
  }
}

class RequestQueue {
  Map<String, RequestItem> items = Map();

  RequestItem start(String url, {
    String key,
    Map<String, String> headers,
    String method = "GET"
  }) {
    key = key ?? url;
    RequestItem item = items[key];
    if (item == null) {
      item = RequestItem(url, this);
      item.headers = headers;
      item.method = method;
      items[key] = item;
      item._start();
    }
    return item;
  }

  void _finished(RequestItem item) {
    items.removeWhere((key, value) => item == value);
  }
}
