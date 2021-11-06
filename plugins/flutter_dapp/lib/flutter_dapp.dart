library flutter_dapp;

import 'package:flutter/material.dart';
import 'package:flutter_dapp/dwidget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:js_script/js_script.dart';
import 'controller.dart';
import 'file_system.dart';
import 'setup_js/timer.dart';
import 'template.dart' as template;
import 'setup_js/file_system.dart' as setupJs;

export 'file_system.dart';
export 'dwidget.dart';

export 'package:js_script/js_script.dart';

Controller _defaultControllerBuilder(JsScript script, DWidgetState state) {
  return Controller(script)..state = state;
}

typedef DAppInitializeCallback = void Function(JsScript script);

class DApp extends StatefulWidget {

  final String entry;
  final List<DappFileSystem> fileSystems;
  final ControllerBuilder controllerBuilder;
  final ClassInfo? classInfo;
  final DAppInitializeCallback? onInitialize;

  DApp({
    Key? key,
    required this.entry,
    required this.fileSystems,
    this.controllerBuilder = _defaultControllerBuilder,
    this.classInfo,
    this.onInitialize,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => DAppState();
}

class DAppState extends State<DApp> {

  late JsScript script;

  @override
  void initState() {
    super.initState();
    _initScript();
    template.register();
  }

  @override
  void dispose() {
    super.dispose();
    script.dispose();
  }

  bool testSame(covariant DApp oldWidget) {
    if (oldWidget.entry != widget.entry) return false;
    if (oldWidget.fileSystems.length != widget.fileSystems.length) return false;
    for (int i = 0, t = widget.fileSystems.length; i < t; ++i) {
      if (oldWidget.fileSystems[i] != widget.fileSystems[i]) return false;
    }
    return true;
  }

  void _initScript() {
    script = JsScript(
        fileSystems: [
          setupJs.fileSystem,
        ]..addAll(widget.fileSystems)
    );
    script.addClass(widget.classInfo ?? controllerClass);
    script.addClass(timerClass);
    script.run("/setup.js");
    script.global["showToast"] = (String msg) {
      Fluttertoast.showToast(msg: msg);
    };
    widget.onInitialize?.call(script);
  }

  @override
  void didUpdateWidget(covariant DApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!(testSame(oldWidget))) {
      script.dispose();
      _initScript();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DWidget(
      key: ValueKey(script),
      script: script,
      file: widget.entry,
      controllerBuilder: widget.controllerBuilder,
    );
  }
}