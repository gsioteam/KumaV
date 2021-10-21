
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../localizations/localizations.dart';

class Settings extends StatefulWidget {

  Settings({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(kt('settings')),
      ),
      body: Container(),
    );
  }
}