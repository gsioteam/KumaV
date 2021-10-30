
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:kumav/extensions/js_processor.dart';
import 'package:kumav/utils/manager.dart';
import 'package:sembast/sembast.dart';
import 'get_ready.dart';
import 'plugin.dart';
import 'video_item.dart';
import 'message_exception.dart';

class FavoriteItem extends ItemData implements ChangeNotifier {

  int itemsLength = 0;
  String lastTitle = '';
  String lastKey = '';
  int date = 0;
  bool _hasNew = false;

  bool get hasNew => _hasNew;
  set hasNew(bool v) {
    if (_hasNew != v) {
      _hasNew = v;
      notifyListeners();
    }
  }

  VoidCallback? _onUpdate;
  List<VoidCallback> _listeners = [];

  FavoriteItem({
    required String key,
    required String pluginID,
    required int date,
    dynamic data,
    dynamic customer,
  }) : super(
    key: key,
    pluginID: pluginID,
    date: date,
    data: data,
    customer: customer,
  );

  FavoriteItem.fromData(Map data) : super.fromData(data) {
    var favData = data['fav'];
    itemsLength = favData['length'];
    lastTitle = favData['lst_title'];
    lastKey = favData['key'];
    date = favData['date'];
    hasNew = favData['has_new'];
  }

  @override
  toData() {
    Map data = super.toData();
    data['fav'] = {
      'length': itemsLength,
      'lst_title': lastTitle,
      'key': lastKey,
      'date': date,
      'has_new': hasNew,
    };
    return data;
  }

  void update() {
    _onUpdate?.call();
  }

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void dispose() {
    _listeners.clear();
  }

  @override
  bool get hasListeners => _listeners.length > 0;

  @override
  void notifyListeners() {
    for (var func in _listeners) {
      func();
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }
}

class Favorites extends GetReady with ChangeNotifier {

  static RecordRef _favoritesRecord = StoreRef.main().record("favorites");

  late List<FavoriteItem> items;
  final Database database;

  Favorites(this.database);

  Future<void> setup() async {
    var data = await _favoritesRecord.get(database);
    items = [];
    if (data != null) {
      for (var d in data) {
        var item = FavoriteItem.fromData(d);
        item._onUpdate = () {
          _updateItem(item);
        };
        items.add(item);
      }
    }
    _automaticallyUpdate();
  }

  Future<FavoriteItem> add({
    required String key,
    required dynamic data,
    required Plugin plugin,
  }) async {
    for (var it in items) {
      if (it.key == key && plugin.id == it.pluginID) return it;
    }
    FavoriteItem item = FavoriteItem(
      key: key,
      pluginID: plugin.id,
      date: DateTime.now().millisecondsSinceEpoch,
      data: data,
    );
    item._onUpdate = () {
      _updateItem(item);
    };
    items.add(item);

    notifyListeners();
    await synchronize();
    return item;
  }

  Future<void> remove({
    required String key,
    Plugin? plugin,
    String? pluginID,
  }) async {
    if (pluginID == null) {
      pluginID = plugin!.id;
    }
    List<ItemData> needRemove = [];
    for (int i = 0, t = items.length; i < t; ++i) {
      var item = items[i];
      if (item.key == key && pluginID == item.pluginID) {
        item._onUpdate = null;
        needRemove.add(item);
      }
    }

    if (needRemove.isNotEmpty) {
      items.removeWhere((element) => needRemove.contains(element));
      notifyListeners();
      await synchronize();
    }
  }

  bool contains({
    required String key,
    Plugin? plugin,
    String? pluginID,
  }) {
    if (pluginID == null) {
      pluginID = plugin!.id;
    }
    for (int i = 0, t = items.length; i < t; ++i) {
      var item = items[i];
      if (item.key == key && pluginID == item.pluginID) {
        return true;
      }
    }
    return false;
  }

  Future<void> clearNew({
    required String key,
    Plugin? plugin,
    String? pluginID,
  }) async {
    if (pluginID == null) {
      pluginID = plugin!.id;
    }
    for (int i = 0, t = items.length; i < t; ++i) {
      var item = items[i];
      if (item.key == key && pluginID == item.pluginID) {
        if (item.hasNew) {
          item.hasNew = false;
          await synchronize();
        }
      }
    }
  }

  Future<void> synchronize() async {
    await _favoritesRecord.put(database, items.map((e) => e.toData()).toList(), merge: false);
  }

  Future<void> _loadData(FavoriteItem item) async {
    if (item.date + 1800 * 1000 > DateTime.now().millisecondsSinceEpoch) return;
    Processor processor = Processor(item.key);
    Plugin plugin = await Manager.instance.plugins[item.pluginID];
    if (plugin.isValidate == true) {
      JsValue jsProcessor = plugin.makeProcessor(processor);

      try {
        JsValue promise = jsProcessor.invoke("load", [item.data]);
        await promise.asFuture;

        var len = processor.value.items.length;
        var last = processor.value.items.last;

        if (item.itemsLength != len || item.lastKey != last.key) {
          item.hasNew = true;
        }
        if (len > 0) {
          await processor.saveCache(plugin, {
            "time": DateTime.now().millisecondsSinceEpoch,
          });
        }
      } catch (e) {
      }
    } else {
    }
  }

  void _automaticallyUpdate() async {
    var items = List<FavoriteItem>.from(this.items);
    for (var item in items) {
      await _loadData(item);
    }
    Future.delayed(Duration(minutes: 30), _automaticallyUpdate);
  }

  void _updateItem(FavoriteItem item) async {
    if (items.contains(item)) {
      item.date = DateTime.now().millisecondsSinceEpoch;
      await synchronize();
    }
  }
}