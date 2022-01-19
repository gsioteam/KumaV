
import 'package:flutter/cupertino.dart';
import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:kumav/extensions/js_utils.dart';
import 'package:kumav/utils/get_ready.dart';
import 'package:kumav/utils/plugin.dart';
import 'package:sembast/sembast.dart';
import 'package:path/path.dart' as path;

class ProcessorItem {
  String title;
  String subtitle;
  String key;
  dynamic data;
  bool present = false;

  ProcessorItem({
    required this.title,
    required this.subtitle,
    required this.key,
    this.data,
  });

  ProcessorItem.fromData(Map data) :
        title = data["title"],
        subtitle = data["subtitle"],
        key = data["key"],
        data = data["data"];

  Map toData() {
    return {
      "title": title,
      "subtitle": subtitle,
      "key": key,
      "data": data,
    };
  }
}

class ProcessorValue {
  String key;

  bool loading;
  String title;
  String subtitle;
  String description;
  String link;

  List<ProcessorItem> items;

  ProcessorValue({
    required this.key,
    this.loading = false,
    this.title = "",
    this.subtitle = "",
    this.description = "",
    this.link = "",
    this.items = const [],
  });

  ProcessorValue copy({
    bool? loading,
    String? title,
    String? subtitle,
    String? description,
    String? link,
    List<ProcessorItem>? items,
  }) {
    return ProcessorValue(
      key: key,
      loading: loading ?? this.loading,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      link: link ?? this.link,
      items: items ?? this.items,
    );
  }

  Map toData() {
    return {
      "key": key,
      "loading": loading,
      "title": title,
      "subtitle": subtitle,
      "description": description,
      "link": link,
      "items": items.map((e) => e.toData()).toList(),
    };
  }

  ProcessorValue copyWithData(JsValue data) {
    return copy(
      loading: data["loading"],
      title: data["title"],
      subtitle: data["subtitle"],
      description: data["description"],
      link: data["link"],
      items: _makeItems(data["items"]),
    );
  }

  ProcessorValue copyWithMap(Map data) {
    return copy(
      loading: data["loading"],
      title: data["title"],
      subtitle: data["subtitle"],
      description: data["description"],
      link: data["link"],
      items: (data["items"] as List).map((e) => ProcessorItem.fromData(e)).toList(),
    );
  }

  List<ProcessorItem>? _makeItems(dynamic value) {
    if (value is JsValue) {
      if (value.isArray) {
        List<ProcessorItem> items = [];
        int length = value["length"];
        for (int i = 0; i < length; ++i) {
          var item = value[i];
          items.add(ProcessorItem(
            title: item["title"] ?? "",
            subtitle: item["subtitle"] ?? "",
            key: item["key"] ?? "",
            data: jsValueToDart(item["data"])
          ));
        }
        return items;
      }
    }
  }
}

class Processor extends ValueNotifier<ProcessorValue> {
  static StoreRef _cacheRecord = StoreRef("video_cache");
  JsScript script;
  String source;

  Processor(this.script, this.source, String key) : super(ProcessorValue(
    key: key
  ));

  @override
  void dispose() {
    super.dispose();
  }

  dynamic getValue() {
    return value.toData();
  }

  void setValue(JsValue jsValue) {
    value = value.copyWithData(jsValue);
    }

    Future<dynamic> loadCache(Plugin plugin) async {
      var data = await _cacheRecord.record(value.key).get(plugin.database);
      if (data != null)
        value = value.copyWithMap(data["data"]);
      return data;
    }

    Future<void> saveCache(Plugin plugin, Map data) async {
      data["data"] = value.toData();
      await _cacheRecord.record(value.key).put(
        plugin.database,
        data,
        merge: true,
      );
    }

    String relativePath(String src) => path.normalize(path.join(source, '..', src));

    String? loadString(String src) {
      String path = relativePath(src);
      if (path[0] != '/')
        path = "/$path";
      return script.fileSystems.loadCode(path);
    }
}

ClassInfo processorClass = ClassInfo<Processor>(
  newInstance: (_, __) => throw Exception("This is a abstract class"),
  fields: {
    "value": JsField.ins(
      get: (obj) => obj.getValue(),
      set: (obj, value) => obj.setValue(value),
    ),
    "key": JsField.ins(
      get: (obj) => obj.value.key,
    ),
  },
  functions: {
    "loadString": JsFunction.ins((obj, argv) => obj.loadString(argv[0])),
    "dispose": JsFunction.ins((obj, argv) => obj.dispose()),
  },
);