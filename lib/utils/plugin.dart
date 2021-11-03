
import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dapp/file_system.dart';
import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:glib/utils/git_repository.dart';
import 'package:kumav/extensions/js_processor.dart';
import 'package:kumav/extensions/js_utils.dart';
import 'package:kumav/utils/assets_filesystem.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:xml_layout/status.dart';
import 'package:xml_layout/template.dart';
import 'package:xml_layout/xml_layout.dart';
import 'package:xml/xml.dart' as xml;

import 'io_filesystem.dart';
import 'message_exception.dart';

class GitActionValue {
  GitAction? action;
  String label;
  int loaded;
  int total;
  String? error;

  GitActionValue({
    required this.action,
    required this.label,
    required this.loaded,
    required this.total,
    this.error,
  });

  GitActionValue copyWith({
    String? label,
    int? loaded,
    int? total,
    String? error,
  }) => GitActionValue(
    action: this.action,
    label: label ?? this.label,
    loaded: loaded ?? this.loaded,
    total: total ?? this.total,
    error: error ?? this.error,
  );

  bool get hasError => error != null;
}

class FakeNodeControl with NodeControl {

}

class Extension {
  String icon;
  String index;

  Extension(this.icon, this.index);

  IconData? _iconData;

  IconData? getIconData() {
    if (_iconData == null) {
      Status status = Status({});
      NodeControl nodeControl = FakeNodeControl();
      Template template = Template(xml.XmlText(icon));
      var iter = template.generate(status, nodeControl);
      NodeData node = iter.first;
      _iconData = node.t<IconData>();
    }
    return _iconData;
  }
}

class PluginInformation {
  late String name;
  late String index;
  String? icon;
  late String processor;
  double? appBarElevation;
  late List<Extension> extensions;

  PluginInformation.fromData(dynamic json) {
    name = json['name'];
    index = json['index'];
    icon = json['icon'];
    extensions = [];
    var exs = json['extensions'];
    if (exs != null) {
      for (var ex in exs) {
        extensions.add(Extension(ex['icon'], ex['index']));
      }
    }
    processor = json['processor'];
    if (json['appbar_elevation'] is num)
      appBarElevation = (json['appbar_elevation'] as num).toDouble();
  }
}

class Plugin {
  static late Directory _root;
  static late Directory _cacheRoot;

  RecordRef _storageRecordRed = StoreRef.main().record('storage');

  late String id;

  late Database database;
  late Map storage;
  late DappFileSystem fileSystem;

  bool _test = false;
  bool get isTest => _test;

  late Future<void> _ready;
  Future<void> get ready => _ready;

  GitRepository? repository;

  PluginInformation? _information;
  PluginInformation? get information => _information;

  bool get isValidate => _information != null;


  Plugin(this.id) {
    _test = false;
    _ready = _setup(null, false);
  }

  Plugin.test(BuildContext context) {
    id = 'test';
    _test = true;
    _ready = _setup(context, true);
  }

  Future<void> _setup(BuildContext? context, bool test) async {
    database = await databaseFactoryIo.openDatabase("${_cacheRoot.path}/$id.db");
    dynamic data = await _storageRecordRed.get(database);
    if (data == null) {
      storage = {};
    } else {
      storage = Map.from(data);
    }
    if (test) {
      AssetsFileSystem fileSystem = AssetsFileSystem(context: context!, prefix: 'res/test/');
      await fileSystem.ready;
      this.fileSystem = fileSystem;
    } else {
      var dir = Directory("${_root.path}/$id");
      if (!await dir.exists()) await dir.create(recursive: true);
      this.fileSystem = IOFileSystem(dir);
    }
    try {
      var str = fileSystem.read('/config.json')!;
      var json = jsonDecode(str);

      _information = PluginInformation.fromData(json);
    } catch (e) {
    }
  }

  Future<void> synchronize() async {
    await _storageRecordRed.put(database, storage, merge: false);
  }

  static Future<void> setup() async {
    var dir = await path_provider.getApplicationSupportDirectory();
    _root = Directory("${dir.path}/plugins");
    if (!await _root.exists()) {
      _root.create(recursive: true);
    }
    _cacheRoot = Directory("${dir.path}/cache");
    if (!await _cacheRoot.exists()) {
      _cacheRoot.create(recursive: true);
    }
  }

  JsScript? _script;
  JsScript? get script {
    if (_script == null && isValidate) {
      _script = JsScript(
          fileSystems: [
            fileSystem,
          ],
      );
      setupJS(_script!, this);
      _script!.addClass(processorClass);
    }
    return _script;
  }

  JsValue makeProcessor(Processor processor) {
    if (isValidate) {
      String processorStr = information!.processor;
      if (processorStr[0] != '/') {
        processorStr = "/$processorStr";
      }
      JsValue clazz = script!.run(processorStr + ".js");
      if (clazz.isConstructor) {
        JsValue jsProcessor = script!.bind(processor, classFunc: clazz)..retain();
        return jsProcessor;
      } else {
        throw MessageException("wrong_script");
      }
    } else {
      throw MessageException("no_plugin");
    }
  }

  GitRepository? _gitRepository;
  GitRepository? getRepository(String branch) {
    if (_gitRepository == null) {
      if (isValidate) {
        var dir = Directory("${_root.path}/$id");
        _gitRepository = GitRepository.allocate(dir.path, branch)..retain();
      }
    }
    return _gitRepository;
  }

  Future<void> delete() async {
    var dir = Directory("${_root.path}/$id");
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Stream<GitActionValue> clone(String remoteUrl, String branch) async* {
    var dir = Directory("${_root.path}/$id");
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);

    GitRepository repo = GitRepository.allocate(dir.path, branch)..retain();
    var action = repo.cloneFromRemote(remoteUrl)..retain();

    StreamController<GitActionValue> streamController = StreamController();
    action.setOnProgress((String string, int loaded, int total) {
      streamController.add(GitActionValue(
        action: action,
        label: string,
        loaded: loaded,
        total: total,
      ));
    });
    action.setOnComplete(() {
      streamController.close();
    });

    yield* streamController.stream;

    if (action.hasError()) {
      yield GitActionValue(
        action: action,
        label: "",
        loaded: 0,
        total: 0,
        error: action.getError(),
      );
    }

    action.release();
    repo.release();

  }

  Stream<GitActionValue> fetchAndCheckout(String branch) async* {
    GitRepository? repo = getRepository(branch);

    if (repo?.isOpen() == true) {
      var action = repo!.fetch();
      StreamController<GitActionValue> streamController = StreamController();
      action.setOnProgress((String string, int loaded, int total) {
        streamController.add(GitActionValue(
          action: action,
          label: string,
          loaded: loaded,
          total: total,
        ));
      });
      action.setOnComplete(() {
        streamController.close();
      });
      yield* streamController.stream;

      if (action.hasError()) {
        yield GitActionValue(
          action: action,
          label: "",
          loaded: 0,
          total: 0,
          error: action.getError(),
        );
        return;
      }

      streamController = StreamController();
      action = repo.checkout();
      action.setOnProgress((String string, int loaded, int total) {
        streamController.add(GitActionValue(
          action: action,
          label: string,
          loaded: loaded,
          total: total,
        ));
      });
      action.setOnComplete(() {
        streamController.close();
      });
      yield* streamController.stream;

      if (action.hasError()) {
        yield GitActionValue(
          action: action,
          label: "",
          loaded: 0,
          total: 0,
          error: action.getError(),
        );
        return;
      }

    } else {
      yield GitActionValue(
        action: null,
        label: "",
        loaded: 0,
        total: 0,
        error: "Can not open git repository."
      );
    }
  }
}