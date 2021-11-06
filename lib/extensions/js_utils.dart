
import 'package:flutter/widgets.dart';
import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:kumav/pages/video.dart';
import 'package:kumav/utils/configs.dart';
import 'package:kumav/utils/plugin.dart';

import 'js_hidden_webview.dart';
import 'js_request.dart';
import 'js_storage.dart';
import 'script_context.dart';


dynamic jsValueToDart(dynamic value, [Map? cache]) {
  if (value is JsValue) {
    if (cache == null) cache = {};
    var ret = cache[value];
    if (ret != null) return ret;
    if (value.isArray) {
      List list = [];
      cache[value] = list;
      for (int i = 0, t = value["length"]; i< t; ++i) {
        list.add(jsValueToDart(value[i], cache));
      }
      return list;
    } else {
      Map map = {};
      cache[value] = map;
      var keys = value.getOwnPropertyNames();
      for (var key in keys) {
        map[key] = jsValueToDart(value[key], cache);
      }
      return map;
    }
  } else {
    return value;
  }
}

dynamic dartToJsValue(JsScript script, dynamic data, [Map? cache]) {
  if (cache == null) cache = {};
  var ret = cache[data];
  if (ret != null) return ret;
  if (data is Map) {
    JsValue value = script.newObject();
    cache[data] = value;
    for (var key in data.keys) {
      value[key] = dartToJsValue(script, data[key], cache);
    }
    return value;
  } else if (data is List) {
    JsValue value = script.newArray();
    cache[data] = value;
    for (int i = 0, t = data.length; i < t; ++i) {
      value[i] = dartToJsValue(script, data[i], cache);
    }
    return value;
  } else {
    return data;
  }
}

void setupJS(JsScript script, [Plugin? plugin]) {
  script.addClass(requestClass);
  script.addClass(storageClass);
  script.addClass(scriptContextClass);
  script.addClass(webViewClass);

  if (plugin != null) {
    Storage storage = Storage(plugin);
    JsValue jsStorage = script.bind(storage, classInfo: storageClass);
    script.global['_storage'] = jsStorage;
  }

  script.loadCompiled(Configs.instance.bundle);
}