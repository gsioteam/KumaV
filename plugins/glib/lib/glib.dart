
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'core/binds.dart';

import 'core/callback.dart';

import 'core/core.dart';
import 'core/array.dart';
import 'core/gmap.dart';
import 'core/data.dart';
import 'utils/git_repository.dart';
import 'utils/platform.dart';
import 'utils/bit64.dart';
import 'utils/secp256k1.dart';

class _LifecycleEventHandler extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      Glib.destroy();
    }
  }
}

class Glib {
  static MethodChannel channel = MethodChannel("glib");
  static bool _isStatic = false;

  static setup(String rootPath) async {
    if (_isStatic) return;
    _isStatic = true;
    channel.setMethodCallHandler(onMethod);

    Base.reg(Base, "gc::Object", Base).constructor = (ptr) => Base().setID(ptr);
    Platform.reg();
    Array.reg();
    GMap.reg();
    Callback.reg();
    GitRepository.reg();
    GitAction.reg();
    GitRepository.reg();
    Bit64.reg();
    Data.reg();
    BufferData.reg();
    Secp256k1.reg();

    postSetup();

    File file = File(rootPath + '/cacert.pem');
    if (!await file.exists()) {
      ByteData data = await rootBundle.load("packages/glib/res/cacert.pem");
      await file.writeAsBytes(data.buffer.asUint8List());
    }
    Pointer<Utf8> pstr = file.path.toNativeUtf8();
    setCacertPath(pstr);
    malloc.free(pstr);

    WidgetsBinding.instance?.addObserver(_LifecycleEventHandler());
  }

  static destroy() {
    Platform.clearPlatform();
    destroyLibrary();
    GitRepository.shutdown();
    Base.setuped = false;
  }

  static Future<dynamic> onMethod(MethodCall call) async {
    switch (call.method) {
      case "sendSignal": {
        runOnMainThread();
        break;
      }
    }
  }
}


