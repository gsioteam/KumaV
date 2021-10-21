import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:js_script/js_script.dart';

class AssetFileSystem extends DappFileSystem {
  final String prefix;
  Map<String, Uint8List> map = {};
  late Future<void> _ready;
  Future<void> get ready => _ready;

  AssetFileSystem({
    required BuildContext context,
    required this.prefix,
  }) {
    _ready = _setup(context);
  }

  Future<void> _setup(BuildContext context) async {
    final manifestJson = await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
    final list = json.decode(manifestJson).keys.where((String key) => key.startsWith(prefix));
    for (String path in list) {
      String str = path.replaceFirst(prefix, '');
      if (str[0] != '/') str = '/' + str;
      var data = await rootBundle.load(path);
      map[str] = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    }
  }

  @override
  bool exist(String filename) {
    return map.containsKey(filename);
  }

  @override
  String? read(String filename) {
    var data = map[filename];
    if (data != null) {
      return utf8.decode(data);
    } else {
      return null;
    }
  }

  @override
  Uint8List? readBytes(String filename) {
    return map[filename];
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  Future<AssetFileSystem> _loadData(BuildContext context) async {
    AssetFileSystem fileSystem = AssetFileSystem(
      context: context,
      prefix: 'assets/test'
    );
    await fileSystem.ready;
    return fileSystem;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AssetFileSystem>(
      future: _loadData(context),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return DApp(
              entry: '/main',
              fileSystems: [
                snapshot.requireData,
              ]
          );
        } else {
          return Container();
        }
      }
    );
  }
}
