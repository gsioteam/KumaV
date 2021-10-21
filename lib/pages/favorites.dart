
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../localizations/localizations.dart';

class Favorites extends StatefulWidget {

  Favorites({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(kt('favorites')),
      ),
      body: Container(),
    );
  }
}