
import 'package:glib/core/array.dart';
import 'package:glib/core/data.dart';

import '../core/core.dart';
import 'collection_data.dart';

enum DataItemType {
  Data,
  Header,
  Unkown
}

class DataItem extends Base {

  static reg() {
    Base.reg(DataItem, "gs::DataItem", Base)
        ..constructor = ((id)=>DataItem._().setID(id));
  }

  String get title => call("getTitle");
  set title(String v) => call("setTitle", argv: [v]);

  String get summary => call("getSummary");
  set summary(String v) => call("setSummary", argv: [v]);

  String get picture => call("getPicture");
  set picture(String v) => call("setPicture", argv: [v]);

  String get subtitle => call("getSubtitle");
  set subtitle(String v) => call("setSubtitle", argv: [v]);

  String get link => call("getLink");
  set link(String v) => call("setLink", argv: [v]);

  dynamic get data => call("getData");
  set data(v) => call("setData", argv: [v]);
  
  String get projectKey => call("getProjectKey");

  DataItemType get type {
    int type = call("getType");
    switch (type) {
      case 0: {
        return DataItemType.Data;
      }
      case 1: {
        return DataItemType.Header;
      }
    }
    return DataItemType.Unkown;
  }

  set type(DataItemType type) {
    int t = 0;
    switch (type) {
      case DataItemType.Data: {
        t = 0;
        break;
      }
      case DataItemType.Header: {
        t = 1;
        break;
      }
      default: {
        break;
      }
    }
    call("setType", argv: [t]);
  }

  Array getSubItems() => call("getSubItems");

  CollectionData saveToCollection(String type, [dynamic data]) => call("saveToCollection", argv: [type, data]);
  static Array loadCollectionItems(String type) => Base.s_call(DataItem, "loadCollectionItems", argv: [type]);
  bool isInCollection(String type) => call("isInCollection", argv: [type]);
  void removeFromCollection(String type) => call("removeFromCollection", argv: [type]);

  static DataItem fromCollectionData(CollectionData data) => Base.s_call(DataItem, "fromCollectionData", argv: [data]);

  static String toJSON(Array items) => Base.s_call(DataItem, "toJSON", argv: [items]);
  static Array fromJSON(String json) => Base.s_call(DataItem, "fromJSON", argv: [json]);

  DataItem._();
  DataItem.allocate() {
    super.allocate([]);
  }
}