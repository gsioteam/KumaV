
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PluginsWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _PluginsState();
}

class _PluginsState extends State<PluginsWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('test'),
      ),
    );
  }
}