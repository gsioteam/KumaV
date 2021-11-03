
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sembast/sembast.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:yaml/yaml.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:glib/utils/secp256k1.dart';
import 'dart:convert';

import 'get_ready.dart';
import 'plugin.dart';

class PluginInfo {
  String title;
  String? icon;
  String src;
  bool ignore;
  String? branch;
  int date = 0;

  String get id => hex.encode(md5.convert(utf8.encode(src)).bytes);

  PluginInfo.fromData(Map data) :
        title = data["title"],
        icon = data["icon"],
        src = data['src'],
        ignore = data['ignore'] ?? false,
        branch = data['branch'];

  PluginInfo({
    required this.title,
    this.icon,
    required this.src,
    this.ignore = false,
    this.branch,
  });

  toData() => {
    "title": title,
    "icon": icon,
    "src": src,
    "ignore": ignore,
    "branch": branch,
    "date": date,
  };
}

class Plugins extends GetReady with ChangeNotifier {

  static RecordRef<String, String> _currentPluginRef = StoreRef<String, String>.main().record("current_plugin");
  static StoreRef _cachedInfoStoreRef = StoreRef("cached_plugins");
  static RecordRef _pluginUpdateTimeRecord = StoreRef.main().record("plugin_update");
  static StoreRef _addedStoreRef = StoreRef("added_plugin");

  Map<String, Plugin > _plugins = {};

  final Database database;

  Plugin? _current;
  Plugin? get current => _current;
  set current(Plugin? plugin) {
    if (plugin != null && plugin.isValidate) {
      _current = plugin;
      _currentPluginRef.put(database, plugin.id);
      notifyListeners();
    } else {
      _current = null;
      _currentPluginRef.delete(database);
      notifyListeners();
    }
  }

  Plugins(this.database);

  Plugin? operator [](String id) {
    return _plugins[id];
  }

  operator []=(String id, Plugin plugin) {
    _plugins[id] = plugin;
  }

  Future<Plugin> loadPlugin(String id) async {
    if (_plugins.containsKey(id)) {
      return _plugins[id]!;
    }
    Plugin plugin = Plugin(id);
    await plugin.ready;
    if (plugin.isValidate)
      _plugins[id] = plugin;
    return plugin;
  }

  @override
  Future<void> setup() async {
    await Plugin.setup();
    String? id = await _currentPluginRef.get(database);
    if (id != null) {
      Plugin plugin = Plugin(id);
      await plugin.ready;
      if (plugin.isValidate) {
        _current = plugin;
      }
    }
  }

  Stream<PluginInfo> all() async* {
    var stream = _cachedInfoStoreRef.stream(database);
    await for (var rec in stream) {
      yield PluginInfo.fromData(rec.value);
    }
  }

  Future<void> add(PluginInfo plugin) async {
    plugin.date = DateTime.now().millisecondsSinceEpoch;
    var ret = await _cachedInfoStoreRef.find(database, finder: Finder(
      filter: Filter.equals("src", plugin.src),
    ));
    if (ret.isNotEmpty) {
      var rec = ret.first;
      await _cachedInfoStoreRef.record(rec.key).update(database, plugin.toData());
    } else {
      await _cachedInfoStoreRef.add(database, plugin.toData());
    }
  }

  Future<void> remove(PluginInfo pluginInfo) async {
    await _cachedInfoStoreRef.delete(database, finder: Finder(
      filter: Filter.equals("src", pluginInfo.src),
    ));
    var plugin = await loadPlugin(pluginInfo.id);
    await plugin.delete();
    _plugins.remove(pluginInfo.id);
    if (current?.id == pluginInfo.id) {
      current = null;
    }
  }

  Future<DateTime> lastUpdateTime() async {
    var date = await _pluginUpdateTimeRecord.get(database) ?? 0;
    return DateTime.fromMillisecondsSinceEpoch(date);
  }

  Future<void> updateData(String pubKey, dynamic data) async {
    if (data is List) {
      String prev = "";
      for (var d in data) {
        try {
          var body = d['body'];
          var bodyData = loadYaml(body);
          String token = bodyData["token"];
          var info = PluginInfo.fromData(bodyData);

          var ret = isMarch(pubKey, token, info.src, prev);
          if (ret) {
            prev = token;
            var rec = _addedStoreRef.record(info.src);
            if (await rec.get(database) != null) {
              continue;
            }
            await rec.put(database, true);
            await add(info);
          } else {
            print("not");
          }
        } catch (e) {
          print("Error $e");
        }

      }
      await _pluginUpdateTimeRecord.put(database, DateTime.now().millisecondsSinceEpoch);
    }
  }

  bool isMarch(String pubKey, String token, String url, String prev) {
    return Secp256k1.verify(pubKey, token, url, prev);
  }
}