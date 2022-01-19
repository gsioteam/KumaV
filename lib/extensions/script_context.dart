
import 'package:flutter_dapp/flutter_dapp.dart';
import 'js_utils.dart';

class ScriptContext implements JsDispose {
  JsScript script;
  JsValue? _onEvent;

  ScriptContext() : script = JsScript() {
    setupJS(script);
    script.global["postMessage"] = script.function((argv) => _onPostMessage(argv[0]));
  }

  eval(String str) {
    var ret = script.eval(str);
    if (ret is JsValue) {
      ret = jsValueToDart(ret);
    }
    return ret;
  }

  dispose() {
    script.dispose();
    _onEvent?.release();
  }

  _onPostMessage(dynamic data) {
    if (_onEvent != null)
      _onEvent!.call([dartToJsValue(_onEvent!.script, jsValueToDart(data))]);
  }

  JsValue? get onEvent {
    return _onEvent;
  }

  set onEvent(JsValue? val) {
    _onEvent?.release();
    _onEvent = val?..retain();
  }
  
  postMessage(data) {
    script.global.invoke("onmessage", [dartToJsValue(script, jsValueToDart(data))]);
  }
}

ClassInfo scriptContextClass = ClassInfo<ScriptContext>(
  newInstance: (_, __) => ScriptContext(),
  functions: {
    "eval": JsFunction.ins((obj, argv) => obj.eval(argv[0])),
    "postMessage": JsFunction.ins((obj, argv) => obj.postMessage(argv[0])),
  },
  fields: {
    "onmessage": JsField.ins(
      set: (obj, val) => obj.onEvent = val,
      get: (obj) => obj.onEvent,
    )
  }
);