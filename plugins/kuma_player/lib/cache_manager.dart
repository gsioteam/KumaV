

import 'dart:io';

import 'dart:typed_data';

import 'package:flutter/foundation.dart';

const int MAX_MEMORY_LENGTH = 20 * 1024 * 1024;

class CacheManager {
  Directory dir;
  Map<String, List<int>> _cache = {};
  List<String> _keys = [];
  int _memoryLength = 0;

  CacheManager(this.dir);

  Future<List<int>> load(String key) async {
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

  List<int> loadSync(String key) {
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

  void _addCache(String key, List<int> buf) {
    if (_cache.containsKey(key)) {
      return;
    }
    while (_memoryLength > MAX_MEMORY_LENGTH - buf.length && _memoryLength > 0 && _cache.length > 0) {
      String key = _keys.removeLast();
      List<int> data = _cache.remove(key);
      _memoryLength -= data.length;
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
      _memoryLength -= value.length;
    }
  }

  bool contains(String key) {
    if (_cache.containsKey(key)) {
      return true;
    }
    String path = dir.path + (key[0] == "/" ? key : "/"+key);
    return File(path).existsSync();
  }

  void insert(String key, List<int> buf) {
    _addCache(key, buf);
    String path = dir.path + (key[0] == "/" ? key : "/"+key);
    File file = File(path);
    Directory parent = file.parent;
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }
    file.writeAsBytes(buf);
  }

  void remove(String key) {
    _removeCache(key);
    String path = dir.path + (key[0] == "/" ? key : "/"+key);
    File(path).deleteSync();
  }
}