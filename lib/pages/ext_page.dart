
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:kumav/extensions/js_utils.dart';
import 'package:kumav/utils/plugin.dart';

import 'video.dart';

class ExtPage extends StatelessWidget {
  final Plugin plugin;
  final String entry;

  ExtPage({
    Key? key,
    required this.plugin,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    String entry = this.entry;
    if (entry[0] != '/') {
      entry = '/' + entry;
    }
    return DApp(
        entry: entry,
        fileSystems: [plugin.fileSystem],
        onInitialize: (script) {
          setupJS(script, plugin);

          script.global['openVideo'] = script.function((argv) {
            OpenVideoNotification(
                key: argv[0],
                data: jsValueToDart(argv[1]),
                plugin: plugin
            ).dispatch(context);
          });
        }
    );
  }
}