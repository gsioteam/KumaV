
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../localizations/localizations.dart';

class Downloads extends StatefulWidget {
  Downloads({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DownloadsState();
}

class _DownloadsState extends State<Downloads> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(kt('download_list')),
      ),
      body: Container(),
    );
  }
}