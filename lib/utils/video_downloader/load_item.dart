import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'proxy_server.dart';
import 'request_queue.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;

class LoadItem {
  late Future<bool> _loaded;
  int _weight;
  RequestItem Function() _requestItemBuilder;
  ProxyItem _proxyItem;
  void Function(int)? onLoadData;
  ProxyItem get proxyItem => _proxyItem;

  String cacheKey;

  Future<bool> get loaded => _loaded;
  int get weight => _weight;
  dynamic data;

  LoadItem({
    required this.cacheKey,
    required ProxyItem proxyItem,
    required int weight,
    required RequestItem Function() builder,
    this.data
  }) : _proxyItem = proxyItem, _weight = weight, _requestItemBuilder = builder {
    _loaded = _proxyItem.server.cacheManager.contains(this.cacheKey);
  }

  Future<int> get size =>  _proxyItem.server.cacheManager.getSize(cacheKey);
  List<int>? readSync() => _proxyItem.server.cacheManager.loadSync(cacheKey);

  RequestItem? currentRequest;

  Stream<List<int>> read([int start = 0, int end = -1]) async* {
    if (await _proxyItem.server.cacheManager.contains(this.cacheKey)) {
      List<int>? buffer = await _proxyItem.server.cacheManager.load(this.cacheKey);
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
    currentRequest = item;
    if (item.method.toUpperCase() == "HEAD") {
      print("REQ: ${item.url}");
      var response = await item.getResponse();
      print("headers: ${response.headers}");
      Map<String, String> headers = {};
      response.headers.forEach((name, values) => headers[name.toLowerCase()] = values.join(','));
      String json = jsonEncode(headers);
      List<int> buf = utf8.encode(json);
      yield buf;
      onLoadData?.call(buf.length);
      _onComplete(true, [buf]);
      currentRequest = null;
    } else {
      item.onComplete = _onComplete;
      item.onFailed = _onFailed;
      print("URL: ${item.url}");
      var response = await item.getResponse();
      print("headers: ${response.headers}");
      print("statusCode: ${response.statusCode}");
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        int contentLength = int.tryParse(response.headers.value(Headers.contentLengthHeader) ?? "0") ?? 0;
        if (contentLength > 0) {
          if (end < 0) end = int.tryParse(response.headers.value(Headers.contentLengthHeader) ?? "0") ?? 0;
          int BLK_SIZE = 4096;
          for (int offset = start; offset < end; offset += BLK_SIZE) {
            // print("[S]read $cacheKey ($offset-${math.min(end, offset + BLK_SIZE)})");
            var buf = await item.readPart(offset, math.min(end, offset + BLK_SIZE));
            // print("[E]read $cacheKey (${buf.length})");
            onLoadData?.call(buf.length);
            yield buf;
          }
        } else {
          Future<List<List<int>>> wait() {
            Completer<List<List<int>>> completer = Completer();
            item.addListener(LoadListener((success, chunks) {
              if (success)
                completer.complete(chunks);
              else completer.completeError(Exception());
            }));
            return completer.future;
          }
          var chunks = await wait();
          int readed = 0;
          for (var chunk in chunks) {
            if (end > 0) {
              int len = chunk.length;
              if (readed + len > end) {
                var buf = chunk.sublist(0, end - readed);
                onLoadData?.call(buf.length);
                yield buf;
                break;
              } else {
                readed += chunk.length;
                onLoadData?.call(chunk.length);
                yield chunk;
              }
            } else {
              onLoadData?.call(chunk.length);
              yield chunk;
            }
          }
        }
        currentRequest = null;
      } else {
        currentRequest = null;
        throw "Request $data failed code:${response.statusCode}";
      }
    }
  }

  Future<void> clear() async {
    _loaded = SynchronousFuture<bool>(false);
    if (_proxyItem.server.cacheManager.containsSync(this.cacheKey)) {
      await _proxyItem.server.cacheManager.remove(this.cacheKey);
    }
  }

  void _onComplete(bool success, List<List<int>>? chunks) {
    if (success) {
      _loaded = SynchronousFuture<bool>(true);
      _proxyItem.server.cacheManager.insert(cacheKey, chunks!.expand((e) => e).toList());
      _proxyItem.itemLoaded(this, chunks);
    }
  }

  void _onFailed() {
    _loaded = SynchronousFuture<bool>(false);
  }

  void stopLoading() {
    currentRequest?.stop();
  }
}