import 'dart:convert';

import 'package:flutter/services.dart';

import 'proxy_server.dart';
import 'request_queue.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;

class LoadItem {
  bool _loaded;
  int _weight;
  RequestItem Function() _requestItemBuilder;
  ProxyItem _proxyItem;
  void Function(int) onLoadData;

  String cacheKey;

  bool get loaded => _loaded;
  int get weight => _weight;
  dynamic data;

  LoadItem({
    this.cacheKey,
    ProxyItem proxyItem,
    int weight,
    RequestItem Function() builder,
    this.data
  }) : _proxyItem = proxyItem, _weight = weight, _requestItemBuilder = builder {
    _loaded = _proxyItem.server.cacheManager.contains(this.cacheKey);
  }

  List<ByteData> _testData = [];
  Future<ByteData> testData(int idx) async {
    if (_testData.length <= idx) {
      _testData.length = idx + 1;
    }
    if (_testData[idx] == null) {
      _testData[idx] = await rootBundle.load("assets/$idx");
    }
    return _testData[idx];
  }

  int get size =>  _proxyItem.server.cacheManager.getSize(cacheKey);
  List<int> readSync() => _proxyItem.server.cacheManager.loadSync(cacheKey);

  Stream<List<int>> read([int start = 0, int end = -1]) async* {
    if (_proxyItem.server.cacheManager.contains(this.cacheKey)) {
      List<int> buffer = await _proxyItem.server.cacheManager.load(this.cacheKey);
      if (buffer != null) {
        if (start != 0 || end > 0) {
          // print("[S]cached $cacheKey ($start-$end)");
          var buf = buffer.sublist(start, end > 0 ? end : null);
          yield buf;
          // print("[E]cached $cacheKey (${buf.length})");
        } else {
          yield buffer;
        }
        return;
      }
    }

    RequestItem item = _requestItemBuilder();
    if (item.method.toUpperCase() == "HEAD") {
      print("REQ: ${item.url}");
      var response = await item.getResponse();
      print("headers: ${response.headers}");
      String json = jsonEncode(response.headers);
      List<int> buf = utf8.encode(json);
      yield buf;
      onLoadData?.call(buf.length);
      _onComplete([buf]);
    } else {
      item.onComplete = _onComplete;
      var response = await item.getResponse();
      print("URL: ${response.request.url}");
      print("headers: ${response.headers}");
      print("statusCode: ${response.statusCode}");
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (end < 0) end = response.contentLength;
        int BLK_SIZE = 4096;
        for (int offset = start; offset < end; offset += BLK_SIZE) {
          // print("[S]read $cacheKey ($offset-${math.min(end, offset + BLK_SIZE)})");
          var buf = await item.readPart(offset, math.min(end, offset + BLK_SIZE));
          // print("[E]read $cacheKey (${buf.length})");
          onLoadData?.call(buf.length);
          yield buf;
        }
      } else {
        throw "Request $data failed code:${response.statusCode}";
      }
    }
  }

  void clear() {
    _loaded = false;
    if (_proxyItem.server.cacheManager.contains(this.cacheKey)) {
      _proxyItem.server.cacheManager.remove(this.cacheKey);
    }
  }

  void _onComplete(List<List<int>> chunks) {
    _loaded = true;
    _proxyItem.server.cacheManager.insert(cacheKey, chunks.expand((e) => e).toList());
    _proxyItem.itemLoaded(this, chunks);
  }
}