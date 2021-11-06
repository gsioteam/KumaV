
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dapp/widgets/dimage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kumav/pages/video.dart';
import 'package:kumav/utils/favorites.dart';
import 'package:kumav/utils/manager.dart';
import 'package:kumav/utils/plugin.dart';
import 'package:kumav/widgets/hint_point.dart';
import 'package:kumav/widgets/no_data.dart';

import '../localizations/localizations.dart';

class FavoriteCell extends StatefulWidget {
  final FavoriteItem item;
  final VoidCallback? onTap;

  FavoriteCell({
    Key? key,
    required this.item,
    this.onTap,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FavoriteCellState();
}

class _FavoriteCellState extends State<FavoriteCell> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.item.title),
      subtitle: Text(widget.item.subtitle),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          DImage(
            src: widget.item.picture,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
          ),
          if (widget.item.hasNew) Positioned(
            right: -2,
            top: -2,
            child: HintPoint(
              size: 12,
            ),
          ),
        ],
      ),
      onTap: widget.onTap,
      tileColor: Theme.of(context).canvasColor,
    );
  }

  @override
  void initState() {
    super.initState();
    widget.item.addListener(_onUpdate);
  }

  @override
  void dispose() {
    super.dispose();
    widget.item.removeListener(_onUpdate);
  }

  void _onUpdate() {
    setState(() {
    });
  }
}

class Favorites extends StatefulWidget {

  Favorites({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites> {
  @override
  Widget build(BuildContext context) {
    int length = Manager.instance.favorites.items.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc('favorites')),
      ),
      body: length == 0 ? NoData() : ReorderableListView.builder(
        itemBuilder: (context, index) {
          var item = Manager.instance.favorites.items[index];
          return Dismissible(
            key: ValueKey(item.key),
            child: FavoriteCell(
              item: item,
              onTap: () async {
                Plugin? plugin = await Manager.instance.plugins.loadPlugin(item.pluginID);
                if (plugin.isValidate) {
                  OpenVideoNotification(
                    key: item.key,
                    data: item.data,
                    plugin: plugin,
                  ).dispatch(context);
                } else {
                  Fluttertoast.showToast(msg: loc('no_plugin'));
                }
              },
            ),
            confirmDismiss: (_) async {
              return showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(loc('confirm')),
                      content: Text(loc('remove_favorite', arguments: {
                        0: item.title
                      })),
                      actions: [
                        TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                            child: Text(loc('no'))
                        ),
                        TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(true);
                            },
                            child: Text(loc('yes'))
                        ),
                      ],
                    );
                  }
              );
            },
            onDismissed: (_) {
              setState(() {
                Manager.instance.favorites.items.remove(item);
                Manager.instance.favorites.synchronize();
              });
            },
          );
        },
        itemCount: length,
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