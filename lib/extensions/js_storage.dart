
import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:kumav/utils/plugin.dart';

class Storage {

  Plugin plugin;

  Storage(this.plugin);

  void set(String key, String value) {
    plugin.storage[key] = value;
    plugin.synchronize();
  }

  String? get(String key) {
    return plugin.storage[key];
  }

  void remove(String key) {
    var ret = plugin.storage.remove(key);
    if (ret != null) {
      plugin.synchronize();
    }
  }

  void clear() {
    plugin.storage.clear();
    plugin.synchronize();
  }
}

ClassInfo storageClass = ClassInfo<Storage>(
  newInstance: (_, __) => throw Exception(["This is a abstract class"]),
  functions: {
    "set": JsFunction.ins((obj, argv) => obj.set(argv[0], argv[1])),
    "get": JsFunction.ins((obj, argv) => obj.get(argv[0])),
    "remove": JsFunction.ins((obj, argv) => obj.remove(argv[0])),
    "clear": JsFunction.ins((obj, argv) => obj.clear()),
  }
);