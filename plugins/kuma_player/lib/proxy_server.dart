
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:http_multi_server/http_multi_server.dart';
import 'package:shelf/shelf.dart';
import 'cache_manager.dart';
import 'load_item.dart';
import 'request_queue.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' as platform;
import 'package:mime/mime.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'package:path/path.dart' as path;

String _calculateKey(String url) {
  var hash = crypto.sha256.convert(utf8.encode(url));
  return hash.toString();
}

class _ProxyData {
  String url;
  dynamic customerData;

  _ProxyData(this.url, [this.customerData]);
}

class _RangeData {
  int start, end;

  _RangeData(this.start, this.end);
}

_RangeData _getRange(Map<String, String> headers) {
  String range = headers["Range"] ?? headers["range"];
  if (range != null) {
    int start = 0, end = -1;
    var words = range.split('=');
    if (words.length == 2) {
      words = words[1].split('-');
      if (words.length == 2) {
        start = int.tryParse(words[0]) ?? 0;
        end = int.tryParse(words[1]) ?? -1;
        if (end != -1) end++;
      }
    }
    return _RangeData(start, end);
  } else {
    return null;
  }
}

class BufferedRange {
  double start = 0;
  double end = 0;

  BufferedRange();
}

abstract class ProxyItem {
  Uri _url;
  String _base;
  String _key;
  String _entry;
  Map<String, _ProxyData> _files = Map();
  ProxyServer _server;
  RequestQueue _queue = RequestQueue();
  Uri get url => _url;
  String get base => _base;
  String get key => _key;
  String get entry => _entry;
  ProxyServer get server => _server;
  Timer _timer;
  int _oldSpeed = 0;
  int _speed = 0;
  List<void Function(int)> _onSpeeds = [];
  List<void Function()> _onBuffered = [];
  LoadItem _lastItem;

  List<LoadItem> _loadItems = List();
  Map<String, LoadItem> _loadItemIndex = Map();

  List<LoadItem> get loadItems => _loadItems;

  ProxyItem._(this._server, String url) {
    int index = url.lastIndexOf("/");
    if (index < 0) {
      throw "Wrong url $_url";
    }
    _url = Uri.parse(url);
    _entry = path.basename(_url.path);
    _base = url.substring(0, index + 1);
    _key = _calculateKey(url);
    _files[entry] = _ProxyData(url);

    _timer = Timer(Duration(seconds: 1), _speedTimer);
  }

  void _speedTimer() {
    _oldSpeed = _speed;
    for (var onSpeed in _onSpeeds)
      onSpeed(_oldSpeed);
    _speed = 0;
    _timer = Timer(Duration(seconds: 1), _speedTimer);
  }

  void _receiveData(int length) {
    _speed += length;
  }

  factory ProxyItem(ProxyServer server, String url) {
    int idx = url.indexOf('?');
    String raw;
    if (idx >= 0) {
      raw = url.substring(0, idx - 1);
    } else if ((idx = url.indexOf('#')) >= 0) {
      raw = url.substring(0, idx - 1);
    } else {
      raw = url;
    }
    String filename = raw.substring(raw.lastIndexOf('/') + 1);
    idx = filename.lastIndexOf('\.');
    String ext;
    if (idx >= 0) {
      ext = filename.substring(idx + 1).toLowerCase();
    }
    if (ext == "m3u8") {
      return HlsProxyItem._(server, url);
    } else {
      return SingleProxyItem._(server, url);
    }
  }

  void gotError() {
    _lastItem?.clear();
  }

  Future<Response> handle(Request request, String key);

  int _retainCount = 0;
  void retain() {
    _retainCount ++;
  }

  void release() {
    _retainCount --;
    if (_retainCount <= 0) dispose();
  }

  void dispose() {
    server._removeItem(this);
    _timer.cancel();
  }

  void itemLoaded(LoadItem item, List<List<int>> chunks) {
    _buffered = null;
    for (var onBuffered in _onBuffered)
      onBuffered();
  }

  void addLoadItem(LoadItem item) {
    _loadItems.add(item);
    _loadItemIndex[item.cacheKey] = item;
    _buffered = null;
  }

  LoadItem getLoadItem(String cacheKey) => _loadItemIndex[cacheKey];

  List<BufferedRange> _buffered;
  List<BufferedRange> get buffered {
    if (_buffered == null) {
      _buffered = [];
      List<_RangeData> ranges = [];
      bool outRange = true;
      int offset = 0;
      _RangeData range;
      for (LoadItem item in _loadItems) {
        if (outRange) {
          if (item.loaded) {
            range = _RangeData(offset, offset + item.weight);
            outRange = false;
          } else {
          }
        } else {
          if (item.loaded) {
            range.end += item.weight;
          } else {
            ranges.add(range);
            range = null;
            outRange = true;
          }
        }
        offset += item.weight;
      }
      if (range != null) ranges.add(range);

      for (_RangeData range in ranges) {
        _buffered.add(BufferedRange()
          ..start = (offset == 0 ? 0 : range.start / offset)
          ..end = (offset == 0 ? 0 : range.end / offset)
        );
      }
    }
    return _buffered;
  }

  void addOnSpeed(void Function(int) cb) => _onSpeeds.add(cb);
  void removeOnSpeed(void Function(int) cb) => _onSpeeds.remove(cb);

  void addOnBuffered(VoidCallback cb) => _onBuffered.add(cb);
  void removeOnBuffered(VoidCallback cb) => _onBuffered.remove(cb);

  void checkBuffered();

  void processBuffer(LoadItem item, List<int> buffer);
}

enum ParseState {
  Line,
  Url
}

class HlsProxyItem extends ProxyItem {

  Map<Uri, String> cached = Map();

  HlsProxyItem._(ProxyServer server, String url) : super._(server, url) {
    String cacheKey = "$key/$entry";
    addLoadItem(LoadItem(
      proxyItem: this,
      weight: 1,
      cacheKey: cacheKey,
      builder: () => _queue.start(url),
      data: url
    )..onLoadData = _receiveData);
    _ProxyData proxyData = _files[entry];
    proxyData.customerData = getLoadItem(cacheKey);
  }

  String getFileEntry(String url) {
    int index;
    String rawUrl;
    if ((index = url.indexOf("?")) > 0) {
      rawUrl = url.substring(0, index);
    } else if ((index = url.indexOf("#")) > 0) {
      rawUrl = url.substring(0, index);
    } else {
      rawUrl = url;
    }
    if (rawUrl.indexOf(base) == 0) {
      return rawUrl.replaceFirst(base, "");
    } else {
      int lastIndex = rawUrl.lastIndexOf('/');
      if (lastIndex < 0) {
        throw "Wrong url $url";
      }
      String filename = rawUrl.substring(lastIndex + 1);
      String prePath = rawUrl.substring(0, lastIndex + 1);
      String key = _calculateKey(prePath);
      key = key + '/' + filename;
      return key;
    }
  }

  String _insertFile(String url) {
    String entry = getFileEntry(url);
    if (!_files.containsKey(entry)) {
      String cacheKey = "$key/$entry";
      var item = LoadItem(
        proxyItem: this,
        cacheKey: cacheKey,
        weight: 1,
        builder: () => _queue.start(url),
        data: url
      );
      item.onLoadData = _receiveData;
      _files[entry] = _ProxyData(url, item);
      addLoadItem(item);
    }
    return entry;
  }

  Response _createResponse(Request request, dynamic Function(_RangeData) creator) {
    String mimeType = lookupMimeType(request.url.path);
    String range = request.headers['range'] ?? request.headers['Range'];
    int start = 0, end = -1;
    int statusCode = 200;
    if (range != null) {
      var words = range.split('=');
      if (words.length == 2) {
        words = range[1].split('-');
        if (words.length == 2) {
          start = int.tryParse(words[0]) ?? 0;
          end = int.tryParse(words[1]) ?? -1;
          statusCode = 206;
        }
      }
    }

    var body = creator(_RangeData(start, end == -1 ? end : (end + 1)));

    Map<String, Object> headers = {
      "Content-Type": mimeType
    };
    if (range != null) {
      headers["Content-Range"] = "bytes ${start ?? 0}-${end == -1 ? "" : end}/${end == -1 ? "" : (end - start + 1)}";
    }
    return Response(statusCode,
        body: body,
        headers: headers
    );
  }

  String handleUrl(String url) {
    return "/$key/${_insertFile(url)}";
  }

  //  static const RegExp
  static const String URI_STATE = "URI=\"";

  String parseHls(Uri uri, String body) {
    String content = cached[uri];
    if (content != null) return content;

    var lines = body.split("\n");
    List<String> newLines = [];
    ParseState state = ParseState.Line;
    lines.forEach((line) {
      int index = 0;
      switch (state) {
        case ParseState.Line: {
          if ((index = line.indexOf(URI_STATE)) >= 0) {
            String begin = line.substring(0, index + URI_STATE.length);
            String tail;
            bool transform = false;
            StringBuffer sb = StringBuffer();
            for (int off = index + URI_STATE.length; off < line.length; ++off) {
              String ch = line[off];
              if (transform) {
                sb.write(ch);
                transform = false;
              } else {
                if (ch == '\\') {
                  transform = true;
                } else if (ch == '"') {
                  tail = line.substring(off);
                  break;
                } else {
                  sb.write(ch);
                }
              }
            }

            newLines.add(begin + handleUrl(uri.resolve(sb.toString()).toString().replaceAll('"', '\\"')) + tail);
          } else if (line.indexOf("#EXT-X-STREAM-INF:") == 0 ||
              line.indexOf("#EXTINF:") == 0) {
            state = ParseState.Url;
            newLines.add(line.trim());
          } else {
            newLines.add(line.trim());
          }
          break;
        }
        case ParseState.Url: {
          state = ParseState.Line;
          newLines.add(handleUrl(uri.resolve(line.trim()).toString()));
          break;
        }

        default:
          break;
      }
    });

    content = newLines.join("\n");
    cached[uri] = content;
    return content;
  }

  @override
  Future<Response> handle(Request request, String path) async {
    if (_files.containsKey(path)) {
      String ext = p.extension(path)?.toLowerCase();
      bool isList = false;
      if (ext != '.m3u8') {
        var file = _files[path];
        LoadItem item = file.customerData;
        var stream = item.read(0, 7);
        try {
          var text = await utf8.decodeStream(stream);
          isList = text == '#EXTM3U';
        } catch (e) {
        }
      } else {
        isList = true;
      }
      if (isList) {
        var file = _files[path];
        LoadItem item = file.customerData;
        _lastItem = item;
        var stream = item.read();
        String body = await utf8.decodeStream(stream);

        body = parseHls(Uri.parse(file.url), body);

        String mimeType = lookupMimeType(request.url.path);
        return Response(200,
          body: body,
          headers: {
            "Content-Type": mimeType
          }
        );
      } else {
        var file = _files[path];
        LoadItem item = file.customerData;
        _lastItem = item;

        return _createResponse(request, (range) {
          return item.read(range.start, range.end);
        });
      }
    } else {
      return Response.notFound(null);
    }
  }

  bool _isM3u8(List<int> buf) {
    try {
      return buf.length > 7 && utf8.decode(buf.sublist(0, 7)) == '#EXTM3U';
    } catch (e) {
      return false;
    }
  }

  void checkBuffered() {
    for (int i = 0; i < _loadItems.length; ++i) {
      var item = _loadItems[i];
      if (item.loaded) {
        String ext = p.extension(item.cacheKey)?.toLowerCase();
        var buf = item.readSync();
        if (ext == '.m3u8' || _isM3u8(buf)) {
          parseHls(Uri.parse(item.data), utf8.decode(buf));
        }
      }
    }
  }

  @override
  void processBuffer(LoadItem item, List<int> buffer) {
    String ext = p.extension(item.cacheKey)?.toLowerCase();
    if (ext == '.m3u8' || _isM3u8(buffer)) {
      parseHls(Uri.parse(item.data), utf8.decode(buffer));
    }
  }

}

class SingleProxyItem extends ProxyItem {

  static const int STREAM_LENGTH = 2 * 1024;
  static const int BLOCK_LENGTH = 5 * 1024 * 1024;
  int contentLength;
  bool canSeek;
  String _rawUrl;

  String _cacheKey;
  String get cacheKey {
    if (_cacheKey == null) {
      _cacheKey = "${this.key}/$entry";
    }
    return _cacheKey;
  }

  SingleProxyItem._(ProxyServer server, String url) : super._(server, url) {
    _rawUrl = url;
    String indexKey = "$cacheKey/index";
    addLoadItem(LoadItem(
      proxyItem: this,
      cacheKey: indexKey,
      weight: 100,
      builder: () => requestHEAD(url)
    )..onLoadData = _receiveData);
    _ProxyData proxyData = _files[entry];
    proxyData.customerData = getLoadItem(indexKey);
  }

  RequestItem requestHEAD(String url) {
    return _queue.start(url,
      key: url + "#index#",
      method: "HEAD",
      headers: {
        "Range": "bytes=0-"
      }
    );
  }

  RequestItem requestBody(String url, int index, _RangeData range) {
    return _queue.start(url,
      key: url + "#$index#",
      headers: {
        "Range": "bytes=${range.start}-${range.end - 1}"
      }
    );
  }

  Future<void> getResponse() async {
    if (contentLength == null) {
      String indexKey = "$cacheKey/index";
      LoadItem item = getLoadItem(indexKey);
      var stream = item.read();
      String str = await utf8.decodeStream(stream);
      Map<String, dynamic> headers = jsonDecode(str);
      contentLength = int.parse(headers["content-length"]);
      if (contentLength <= 0) {
        contentLength = null;
        item.clear();
        throw Exception("Wrong content length!");
      }
      canSeek = headers.containsKey("accept-ranges");

      int total = (contentLength / BLOCK_LENGTH).floor();
      if (contentLength % BLOCK_LENGTH != 0) total++;
      for (int i = 0; i < total; ++i) {
        int size = math.min(BLOCK_LENGTH, contentLength - BLOCK_LENGTH * i);
        addLoadItem(LoadItem(
            proxyItem: this,
            cacheKey: "$cacheKey/$i",
            weight: size,
            builder: () => requestBody(_rawUrl, i, _RangeData(BLOCK_LENGTH * i, math.min(contentLength, BLOCK_LENGTH * (i + 1))))
        )..onLoadData = _receiveData);
      }
    }
  }

  Stream<List<int>> requestRange(_RangeData range) async* {
    int offset = range.start;
    while ((offset < range.end || range.end == -1) && offset < contentLength) {
      int blockIndex = (offset / BLOCK_LENGTH).floor();
      int blockStart = blockIndex * BLOCK_LENGTH, blockEnd = blockStart + BLOCK_LENGTH;

      blockEnd = math.min(blockEnd, contentLength);

      String cacheKey = "${this.cacheKey}/$blockIndex";
      LoadItem item = getLoadItem(cacheKey);
      _lastItem = item;
      var start = offset - blockStart, end = (range.end > 0 ? math.min(blockEnd, range.end) : blockEnd) - blockStart;
      await for (var buf in item.read(start, end)) {
        yield buf;
        offset+= buf.length;
      }
    }
  }

  @override
  Future<Response> handle(Request request, String path) async {
    if (_files.containsKey(path)) {
      _RangeData range = _getRange(request.headers);
      bool hasRange = range != null;
      if (range == null) {
        range = _RangeData(0, -1);
      }
      await getResponse();
      var body = requestRange(range);
      var headers = {
        "Content-Type": lookupMimeType(path),
        "Content-Length": "${(range.end == -1 ? contentLength : range.end) - range.start}"
      };
      if (hasRange) {
        headers["Content-Range"] = "bytes ${range.start}-${range.end == -1 ? (contentLength - 1) : (range.end - 1)}/$contentLength";
      }
      print("Response headers $headers");
      Response res = Response(hasRange ? 206 : 200,
          body: body,
          headers: headers
      );
      return res;
    } else {
      return Response.notFound("Not found $path");
    }
  }


  void checkBuffered() {
    for (int i = 0; i < _loadItems.length; ++i) {
      var item = _loadItems[i];
      if (item.loaded) {
        if (item.cacheKey == "$cacheKey/index") {
          if (contentLength == null) {
            String indexKey = "$cacheKey/index";
            LoadItem item = getLoadItem(indexKey);
            String str = utf8.decode(item.readSync());
            Map<String, dynamic> headers = jsonDecode(str);
            contentLength = int.parse(headers["content-length"]);
            if (contentLength == 0) {
              item.clear();
              contentLength = null;
              throw Exception("Empty content-length.");
            }
            canSeek = headers.containsKey("accept-ranges");

            int total = (contentLength / BLOCK_LENGTH).floor();
            if (contentLength % BLOCK_LENGTH != 0) total++;
            for (int i = 0; i < total; ++i) {
              int size = math.min(BLOCK_LENGTH, contentLength - BLOCK_LENGTH * i);
              addLoadItem(LoadItem(
                  proxyItem: this,
                  cacheKey: "$cacheKey/$i",
                  weight: size,
                  builder: () => requestBody(_rawUrl, i, _RangeData(BLOCK_LENGTH * i, math.min(contentLength, BLOCK_LENGTH * (i + 1))))
              )..onLoadData = _receiveData);
            }
          }
        }
      }
    }
  }

  @override
  void processBuffer(LoadItem item, List<int> buffer) {
    if (contentLength == null && item.cacheKey == "$cacheKey/index") {
      Map<String, dynamic> headers = jsonDecode(utf8.decode(buffer));
      contentLength = int.parse(headers["content-length"]);
      canSeek = headers.containsKey("accept-ranges");
      if (contentLength == 0) {
        item.clear();
        contentLength = null;
        throw Exception("Empty content-length.");
      }

      int total = (contentLength / BLOCK_LENGTH).floor();
      if (contentLength % BLOCK_LENGTH != 0) total++;
      for (int i = 0; i < total; ++i) {
        int size = math.min(BLOCK_LENGTH, contentLength - BLOCK_LENGTH * i);
        addLoadItem(LoadItem(
            proxyItem: this,
            cacheKey: "$cacheKey/$i",
            weight: size,
            builder: () =>
                requestBody(_rawUrl, i, _RangeData(BLOCK_LENGTH * i,
                    math.min(contentLength, BLOCK_LENGTH * (i + 1))))
        )..onLoadData = _receiveData);
      }
    }
  }
}

class ProxyServer {
  static ProxyServer _instance;
  Completer<HttpMultiServer> _completer = Completer();

  HttpMultiServer _server;
  Map<String, ProxyItem> items = Map();
  Directory dir;
  CacheManager cacheManager;

  Future<HttpMultiServer> get server {
    if (_completer.isCompleted) {
      return SynchronousFuture(_server);
    } else {
      return _completer.future;
    }
  }

  static ProxyServer get instance {
    if (_instance == null) {
      var server = ProxyServer();
      server.setup();
      _instance = server;
    }
    return _instance;
  }

  Future<void> ready() async {
    if (!_completer.isCompleted) {
      await _completer.future;
    }
  }

  Future<void> setup() async {
    dir = await platform.getTemporaryDirectory();
    dir = Directory(dir.path + '/video');
    if (!dir.existsSync()) dir.createSync();
    cacheManager = CacheManager(dir);

    _server = await HttpMultiServer.loopback(0);
    shelf_io.serveRequests(_server, (request) {
      print("[${request.method}] ${request.requestedUri}");
      print(request.headers);
      var segs = request.requestedUri.path.split("/");
      String key;
      int split = 0;
      for (String seg in segs) {
        split++;
        if (seg.isNotEmpty) {
          key = seg;
          break;
        } else {
        }
      }
      ProxyItem item = items[key];
      if (item != null) {
        try {
          return item.handle(request, segs.sublist(split).join("/"));
        } catch (e) {
          return Response.internalServerError(body: e.toString());
        }
      } else {
        return Response.notFound("${request.requestedUri.path} no resource");
      }
    });
    _completer.complete(_server);
  }

  ProxyItem get(String url) {
    String key = _calculateKey(url);
    ProxyItem item = items[key];
    if (item == null) {
      item = ProxyItem(this, url);
      items[key] = item;
      item._server = this;
    }
    return item;
  }

  void _removeItem(ProxyItem item) {
    items.remove(item.key);
  }
}
