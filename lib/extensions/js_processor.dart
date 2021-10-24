
import 'package:flutter/cupertino.dart';
import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:kumav/extensions/js_utils.dart';

class ProcessorItem {
  String title;
  String subtitle;
  String key;
  dynamic data;

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

  Processor(String key) : super(ProcessorValue(
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
    "dispose": JsFunction.ins((obj, argv) => obj.dispose()),
  },
);