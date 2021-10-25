
import 'package:flutter/widgets.dart';
import 'package:kumav/utils/get_ready.dart';
import 'package:sembast/sembast.dart';

import 'plugin.dart';
import 'video_item.dart';

class Histories extends GetReady with ChangeNotifier {
  StoreRef _historiesStore = StoreRef("histories");

  final Database database;

  Histories(this.database);

  @override
  Future<void> setup() async {
//    var data = await _historiesStore.find(database, finder: Finder(
//      sortOrders: [
//        SortOrder("date", false),
//      ],
//    ));
    _historiesStore.addOnChangesListener(database, (transaction, changes) {
      notifyListeners();
    });
  }

  Future<void> add({
    required String key,
    required dynamic data,
    required Plugin plugin,
  }) async {
    var history = await _historiesStore.find(database, finder: Finder(
      filter: Filter.and([
        Filter.equals("key", key),
        Filter.equals("pluginID", plugin.id),
      ]),
      limit: 1,
    ));
    if (history.length > 0) {
      var item = history.first;
      ItemData itemData = ItemData.fromData(item.value);
      itemData.key = key;
      itemData.data = data;
      itemData.pluginID = plugin.id;
      await _historiesStore.record(item.key).update(database, itemData.toData());
    } else {
      var itemData = ItemData(
        key: key,
        data: data,
        pluginID: plugin.id,
        date: DateTime.now().millisecondsSinceEpoch,
      );
      await _historiesStore.add(database, itemData.toData());
    }
  }

  Future<void> clear() async {
    await _historiesStore.drop(database);
  }

  Future<List<ItemData>> find({
    int page = 0,
    int limit = 20,
  }) async {
    var data = await _historiesStore.find(database, finder: Finder(
      sortOrders: [
        SortOrder("date", false),
      ],
      offset: page * limit,
      limit: limit,
    ));

    List<ItemData> items = [];
    for (var d in data) {
      items.add(ItemData.fromData(d.value)..customer = d.key);
    }
    return items;
  }
}