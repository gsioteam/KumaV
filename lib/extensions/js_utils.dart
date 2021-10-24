
import 'package:flutter/widgets.dart';
import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:kumav/pages/video.dart';
import 'package:kumav/utils/configs.dart';
import 'package:kumav/utils/plugin.dart';

import 'js_request.dart';
import 'js_storage.dart';


dynamic jsValueToDart(dynamic value) {
  if (value is JsValue) {
    if (value.isArray) {
      List list = [];
      for (int i = 0, t = value["length"]; i< t; ++i) {
        list.add(jsValueToDart(value[i]));
      }
      return list;
    } else {
      Map map = {};
      var keys = value.getOwnPropertyNames();
      for (var key in keys) {
        map[key] = jsValueToDart(value[key]);
      }
      return map;
    }
  } else {
    return value;
  }
}

void setupJS(JsScript script, Plugin plugin) {
  script.addClass(requestClass);
  script.addClass(storageClass);

  Storage storage = Storage(plugin);
  JsValue jsStorage = script.bind(storage, classInfo: storageClass);
  script.global['_storage'] = jsStorage;

  script.loadCompiled(Configs.instance.bundle);
}