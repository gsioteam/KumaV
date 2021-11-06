
import 'package:browser_webview/browser_webview.dart';
import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:kumav/extensions/js_utils.dart';

class HiddenWebView implements JsDispose {

  late BrowserWebViewController controller;
  JsValue? _onMessage;

  JsValue? get onMessage => _onMessage;
  set onMessage(JsValue? val) {
    _onMessage?.release();
    _onMessage = val?..retain();
  }

  HiddenWebView(JsValue? options) {
    List<ResourceReplacement>? replacements;
    JsValue? rr = options?["resourceReplacements"];
    if (rr != null && rr.isArray == true) {
      replacements = [];
      for (int i = 0, t = rr["length"]; i < t; ++i) {
        var replacement = rr[i];
        replacements.add(ResourceReplacement(
          replacement["test"],
          replacement["resource"],
          replacement["mimeType"],
        ));
      }
    }

    controller = BrowserWebViewController(
      resourceReplacements: replacements,
    );
    controller.addEventHandler("message", (data) {
      if (_onMessage != null) {
        _onMessage?.call([dartToJsValue(_onMessage!.script, data)]);
      }
    });
    // controller.ready.then((value) {
    //   controller.makeOffscreen();
    // });
  }

  void load(String url) => controller.loadUrl(url: url);

  @override
  void dispose() {
    _onMessage?.release();
    controller.dispose();
  }

}

ClassInfo webViewClass = ClassInfo<HiddenWebView>(
  newInstance: (_, argv) => HiddenWebView(argv[0]),
  functions: {
    "load": JsFunction.ins((obj, argv) => obj.load(argv[0])),
  },
  fields: {
    "onmessage": JsField.ins(
      get: (obj) => obj.onMessage,
      set: (obj, val) => obj.onMessage = val,
    )
  }
);