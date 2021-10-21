

import 'package:flutter/material.dart';
import 'package:js_script/js_script.dart';
import 'package:js_script/types.dart';

import 'dwidget.dart';
import 'js_wrap.dart';

class Controller {
  DWidgetState? state;
  JsScript script;

  Controller(this.script);

  void setState(JsValue func) {
    if (state != null) {
      func.retain();
      state!.updateData(() {
        func.call();
        func.release();
      });
    }
  }

  Future navigateTo(String src, JsValue ops) async {
    if (state != null) {
      ops.retain();
      var ret = await state!.navigateTo(
        src,
        data: ops["data"],
      );
      ops.release();
      return ret;
    }
  }
}

ClassInfo controllerClass = ClassInfo<Controller>(
  name: "_Controller",
  newInstance: (_,__) => throw Exception("This is a abstract class"),
  fields: {
  },
  functions: {
    "setState": JsFunction.ins((obj, argv) => obj.setState(argv[0])),
    "navigateTo": JsFunction.ins((obj, argv) => obj.navigateTo(argv[0], argv[1]))
  }
);