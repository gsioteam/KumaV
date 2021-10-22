

import 'dart:io';

import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

const int MAX_MEMORY_LENGTH = 20 * 1024 * 1024;

class SizeResult {
  int cached = 0;
  int other = 0;
}

class CacheManager {
  Directory dir;
  Map<String, List<int>> _cache = {};
  List<String> _keys = [];
  int _memoryLength = 0;

  CacheManager(this.dir);

  Future<List<int>?> load(String key) async {
    if (_cache.containsKey(key)) {
      _keys.remove(key);
      _keys.insert(0, key);
      return SynchronousFuture(_cache[key]);
    }
    String path = dir.path + (key[0] == "/" ? key : "/"+key);
    File file = File(path);
    if (file.existsSync()) {
      Uint8List buf = await file.readAsBytes();
      if (buf.length > 0) {
        _addCache(key, buf);
        return buf;
      } else {
        file.deleteSync();
        return null;
      }
    } else {
      return null;
    }
  }

  List<int>? loadSync(String key) {
    if (_cache.containsKey(key)) {
      _keys.remove(key);
      _keys.insert(0, key);
      return _cache[key];
    }
    String path = dir.path + (key[0] == "/" ? key : "/"+key);
    File file = File(path);
    if (file.existsSync()) {
      Uint8List buf = file.readAsBytesSync();
      if (buf.length > 0) {
        _addCache(key, buf);
        return buf;
      } else {
        file.deleteSync();
        return null;
      }
    } else {
      return null;
    }
  }

  Future<int> getSize(String key) async {
    if (_cache.containsKey(key)) {
      _keys.remove(key);
      _keys.insert(0, key);
      return _cache[key]?.length ?? 0;
    }
    String path = dir.path + (key[0] == "/" ? key : "/"+key);
    File file = File(path);
    if (file.existsSync()) {
      var stat = await file.stat();
      return stat.size;
    } else {
      return 0;
    }
  }


  int getSizeSync(String key) {
    if (_cache.containsKey(key)) {
      _keys.remove(key);
      _keys.insert(0, key);
      return _cache[key]?.length ?? 0;
    }
    String path = dir.path + (key[0] == "/" ? key : "/"+key);
    File file = File(path);
    if (file.existsSync()) {
      var stat = file.statSync();
      return stat.size;
    } else {
      return 0;
    }
  }

  void _addCache(String key, List<int> buf) {
    if (_cache.containsKey(key)) {
      return;
    }
    while (_memoryLength > MAX_MEMORY_LENGTH - buf.length && _memoryLength > 0 && _cache.length > 0) {
      String key = _keys.removeLast();
      List<int>? data = _cache.remove(key);
      _memoryLength -= data!.length;
    }
    _cache[key] = buf;
    _keys.add(key);
    _memoryLength += buf.length;
  }

  void _removeCache(String key) {
    if (_cache.containsKey(key)) {
      var value = _cache[key];
      _cache.remove(key);
      _keys.remove(key);
      _memoryLength -= value!.length;
    }
  }

  Future<bool> contains(String key) async {
    if (_cache.containsKey(key)) {
      return SynchronousFuture<bool>(true);
    }
    String path = dir.path + (key[0] == "/" ? key : "/"+key);
    var stat = await File(path).stat();
    return stat.type != FileSystemEntityType.notFound && stat.size > 0;
  }

  bool containsSync(String key) {
    if (_cache.containsKey(key)) {
      return true;
    }
    String path = dir.path + (key[0] == "/" ? key : "/"+key);
    var stat = File(path).statSync();
    return stat.type != FileSystemEntityType.notFound && stat.size > 0;
  }

  void insert(String key, List<int> buf) async {
    _addCache(key, buf);
    String path = dir.path + (key[0] == "/" ? key : "/"+key);
    File file = File(path);
    Directory parent = file.parent;
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }
    await file.writeAsBytes(buf, flush: true);
    if (!file.existsSync()) {
      file.writeAsBytesSync(buf, flush: true);
    }
  }

  Future<void> remove(String key) async {
    _removeCache(key);
    String path = dir.path + (key[0] == "/" ? key : "/"+key);
    var file = File(path);
    if (await file.exists())
      await file.delete();
  }

  Future<SizeResult> calculateSize(Set<String> cached) async {
    SizeResult result = SizeResult();
    await for (var entry in dir.list(recursive: true, followLinks: false)) {
      if (entry is File) {
        var path = entry.path.replaceFirst("${dir.path}/", '');
        String key = path.split('/').first;
        if (cached.contains(key)) {
          result.cached += (await entry.stat()).size;
        } else {
          result.other += (await entry.stat()).size;
        }
      }
    }
    return result;
  }

  Future<void> clearWithout(Set<String> cached) async {
    await for (var entry in dir.list(followLinks: false)) {
      String name = path.basename(entry.path);
      if (!cached.contains(name)) {
        await entry.delete(recursive: true);
      }
    }
  }
}