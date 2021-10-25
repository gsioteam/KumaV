
import 'package:flutter/widgets.dart';
import 'package:sembast/sembast.dart';
import 'get_ready.dart';
import 'plugin.dart';
import 'video_item.dart';

class Favorites extends GetReady with ChangeNotifier {

  static RecordRef _favoritesRecord = StoreRef.main().record("favorites");

  late List<ItemData> items;
  final Database database;

  Favorites(this.database);

  Future<void> setup() async {
    var data = await _favoritesRecord.get(database);
    items = [];
    if (data != null) {
      for (var d in data) {
        items.add(ItemData.fromData(d));
      }
    }
  }

  Future<void> add({
    required String key,
    required dynamic data,
    required Plugin plugin,
  }) async {
    for (var it in items) {
      if (it.key == key && plugin.id == it.pluginID) return;
    }
    ItemData item = ItemData(
      key: key,
      pluginID: plugin.id,
      date: DateTime.now().millisecondsSinceEpoch,
      data: data,
    );
    items.add(item);

    notifyListeners();
    await synchronize();
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

  Future<void> synchronize() async {
    await _favoritesRecord.put(database, items.map((e) => e.toData()).toList(), merge: false);
  }
}