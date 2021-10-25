
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dapp/widgets/dimage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kumav/pages/video.dart';
import 'package:kumav/utils/manager.dart';
import 'package:kumav/utils/plugin.dart';

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
      body: ReorderableListView.builder(
        itemBuilder: (context, index) {
          var item = Manager.instance.favorites.items[index];
          return ListTile(
            key: ValueKey(item.key),
            title: Text(item.title),
            subtitle: Text(item.subtitle),
            leading: DImage(
              src: item.picture,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
            onTap: () async {
              Plugin plugin = await Manager.instance.plugins[item.pluginID];
              if (plugin.isValidate) {
                OpenVideoNotification(
                  key: item.key,
                  data: item.data,
                  plugin: plugin,
                ).dispatch(context);
              } else {
                Fluttertoast.showToast(msg: kt('no_plugin'));
              }
            },
          );
        },
        itemCount: Manager.instance.favorites.items.length,
        onReorder: (int oldIndex, int newIndex) {
          var items = Manager.instance.favorites.items;
          var item = items.removeAt(oldIndex);
          if (newIndex >= items.length) items.add(item);
          else items.insert(newIndex, item);
          Manager.instance.favorites.synchronize();
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    Manager.instance.favorites.addListener(_update);
  }

  @override
  void dispose() {
    super.dispose();

    Manager.instance.favorites.removeListener(_update);
  }

  void _update() {
    setState(() {
    });
  }
}