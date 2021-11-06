
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dapp/widgets/dimage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kumav/utils/manager.dart';
import 'package:kumav/utils/plugin.dart';
import 'package:kumav/utils/video_item.dart';
import 'package:kumav/widgets/no_data.dart';

import '../localizations/localizations.dart';
import 'video.dart';

class History extends StatefulWidget {

  History({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HistoryState();
}

class _HistoryState extends State<History> {

  List<ItemData> items = [];
  int page = 0;
  bool _disposed = false;
  bool loading = false;
  bool hasMore = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(loc('history')),
        actions: [
          IconButton(
            onPressed: () async {
              var ret = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(loc('confirm')),
                    content: Text(loc('clear_history')),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        child: Text(loc('no')),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        child: Text(loc('yes')),
                      ),
                    ],
                  );
                }
              );
              if (ret == true) {
                await Manager.instance.histories.clear();
                setState(() { });
              }
            },
            icon: Icon(Icons.clear_all)
          ),
        ],
      ),
      body: items.length == 0 ? NoData() : NotificationListener<ScrollUpdateNotification>(
        child: ListView.builder(
          itemBuilder: (context, index) {
            var item = items[index];
            return ListTile(
              title: Text(item.title),
              subtitle: Text(item.subtitle),
              leading: DImage(
                src: item.picture,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
              onTap: () async {
                Plugin plugin = await Manager.instance.plugins.loadPlugin(item.pluginID);
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
              tileColor: Theme.of(context).canvasColor,
            );
          },
          itemCount: items.length,
        ),
        onNotification: (notification) {
          if (notification.metrics.maxScrollExtent - notification.metrics.pixels < 20 && hasMore && !loading) {
            loadData(page + 1);
          }
          return true;
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    loadData(page);
    Manager.instance.histories.addListener(_update);
  }

  @override
  void dispose() {
    super.dispose();
    _disposed = true;
    Manager.instance.histories.removeListener(_update);
  }

  Future<void> loadData(int page) async {
    loading = true;
    var data = await Manager.instance.histories.find(
      page: page,
      limit: 50,
    );
    if (data.length > 0) {
      items.addAll(data);
      if (!_disposed) {
        setState(() { });
      }
      this.page = page;
    } else {
      hasMore = false;
    }
    loading = false;
  }

  void _update() {
    setState(() {
      items.clear();
      hasMore = true;
      loadData(0);
    });
  }
}