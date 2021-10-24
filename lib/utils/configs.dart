
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:kumav/utils/plugin.dart';
import 'package:path_provider/path_provider.dart' as platform;

import 'dart:io';

const String env_git_url = "https://github.com/gsioteam/glib_env.git";
const String env_git_branch = "master";

const String language_key = "language";
const String disclaimer_key = "disclaimer";

class Configs {
  static Configs? _instance;

  static Configs get instance {
    if (_instance == null) {
      _instance = Configs();
    }
    return _instance!;
  }

  late Directory root;
  late JsCompiled bundle;

  Future<void> setup(BuildContext context) async {
    root = await platform.getApplicationSupportDirectory();
    var bundleJS = await rootBundle.loadString('res/js/bundle.js');
    JsScript script = JsScript();
    bundle = script.compile(bundleJS);
  }

  Plugin? currentPlugin;
}