library flutter_dapp;

import 'package:flutter/material.dart';
import 'package:flutter_dapp/dwidget.dart';
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
    required this.entry,
    required this.fileSystems,
    this.controllerBuilder = _defaultControllerBuilder,
    this.classInfo,
    this.onInitialize,
  });

  @override
  State<StatefulWidget> createState() => DAppState();
}

class DAppState extends State<DApp> {

  late JsScript script;

  @override
  void initState() {
    super.initState();
    script = JsScript(
      fileSystems: [
        setupJs.fileSystem,
      ]..addAll(widget.fileSystems)
    );
    script.addClass(widget.classInfo ?? controllerClass);
    script.addClass(timerClass);
    script.run("/setup.js");
    widget.onInitialize?.call(script);
    template.register();
  }

  @override
  void dispose() {
    super.dispose();
    script.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DWidget(
      script: script,
      file: widget.entry,
      controllerBuilder: widget.controllerBuilder,
    );
  }
}