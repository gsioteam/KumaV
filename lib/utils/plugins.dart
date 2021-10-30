
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sembast/sembast.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import 'get_ready.dart';
import 'plugin.dart';

class Plugins extends GetReady {

  static RecordRef<String, String> _currentPluginRef = StoreRef<String, String>.main().record("current_plugin");
  Map<String, Future<Plugin> > _plugins = {};

  final Database database;

  Plugin? current;

  Plugins(this.database);

  Future<Plugin> operator [](String id) {
    if (_plugins.containsKey(id)) {
      return _plugins[id]!;
    } else {
      var future = _getPlugin(id);
      _plugins[id] = future;
      return future;
    }
  }

  operator []=(String id, Plugin plugin) {
    _plugins[id] = SynchronousFuture(plugin);
  }

  Future<Plugin> _getPlugin(String id) async {
    Plugin plugin = Plugin(id);
    await plugin.ready;
    if (!plugin.isValidate) {
      _plugins.remove(plugin.id);
    }
    return plugin;
  }

  @override
  Future<void> setup() async {
    await Plugin.setup();
    String? id = await _currentPluginRef.get(database);
    if (id != null) {
      current = Plugin(id);
    }
  }
}