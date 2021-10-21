
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../localizations/localizations.dart';

class History extends StatefulWidget {

  History({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(kt('history')),
      ),
      body: Container(),
    );
  }
}