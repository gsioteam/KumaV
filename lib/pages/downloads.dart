
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dapp/widgets/dimage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kumav/utils/downloads.dart';
import 'package:kumav/utils/manager.dart';
import 'package:kumav/utils/plugin.dart';
import 'package:vector_math/vector_math_64.dart';

import '../localizations/localizations.dart';
import 'video.dart';

class DownloadCell extends StatefulWidget {
  final DownloadItem item;
  final VoidCallback? onTap;

  DownloadCell({
    Key? key,
    required this.item,
    this.onTap,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DownloadCellState();

}

class _DownloadCellState extends State<DownloadCell> {
  GlobalKey _tileKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ListTile(
        key: _tileKey,
        title: Text.rich(TextSpan(
            children: [
              TextSpan(text: widget.item.title),
              TextSpan(
                text: "(${widget.item.videoTitle})",
                style: TextStyle(
                  color: Theme.of(context).disabledColor,
                  fontSize: 12,
                ),
              )
            ]
        )),
        subtitle: _buildSubtitle(),
        leading: DImage(
          src: widget.item.picture,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
        trailing: _buildActions(),
        onTap: widget.onTap,
        onLongPress: () async {
          var render = _tileKey.currentContext?.findRenderObject();
          var transform = render?.getTransformTo(null);
          var rect = render?.semanticBounds;
          if (transform != null && rect != null) {
            var off = rect.centerRight;
            var vec3 = transform.transform3(Vector3(off.dx, off.dy, 0));
            var ret = await showMenu<int>(
                context: context,
                position: RelativeRect.fromLTRB(
                    vec3.x - 100, vec3.y-10,
                    vec3.x - 10, vec3.y+10),
                items: [
                  PopupMenuItem(
                    child: Text(loc("refresh")),
                    value: 0,
                  ),
                ]
            );
            switch (ret) {
              case 0: {

                break;
              }
              default: break;
            }
          }
        },
      ),
      color: Theme.of(context).canvasColor,
    );
  }

  String speedToString(int speed) {
    String unit = "kb";
    double sp = speed / 1024;
    if (sp > 1024) {
      unit = "mb";
      sp = sp / 1024;
    }
    return "${sp.toStringAsFixed(2)} $unit/s";
  }

  Widget _buildSubtitle() {
    return Padding(
      padding: EdgeInsets.only(
        top: 8,
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: "${(widget.item.progress * 100).toStringAsFixed(1)}%"
            ),
            WidgetSpan(child: Padding(padding: EdgeInsets.only(left: 20),)),
            if (widget.item.state == DownloadItemState.Downloading) TextSpan(
              text: speedToString(widget.item.speed.value)
            ),
          ],
        ),
        style: TextStyle(
          fontWeight: FontWeight.normal,
          color: Theme.of(context).disabledColor
        ),
      ),
    );
  }

  Widget? _buildActions() {
    switch (widget.item.state) {
      case DownloadItemState.Stop: {
        return IconButton(
            onPressed: () {
              widget.item.resume();
            },
            icon: Icon(Icons.play_arrow)
        );
      }
      case DownloadItemState.Complete: {
        return IconButton(
            onPressed: () {

            },
            icon: Icon(Icons.save)
        );
      }
      case DownloadItemState.Downloading: {
        return IconButton(
            onPressed: () {
              widget.item.stop();
            },
            icon: Icon(Icons.pause)
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();

    widget.item.addListener(_update);
    widget.item.speed.addListener(_update);
  }

  @override
  dispose() {
    super.dispose();

    widget.item.removeListener(_update);
    widget.item.speed.removeListener(_update);
  }

  _update() {
    setState(() {});
  }
}

class Downloads extends StatefulWidget {
  Downloads({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DownloadsState();
}

class _DownloadsState extends State<Downloads> {

  @override
  Widget build(BuildContext context) {
    var items = Manager.instance.downloads.items;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc('download_list')),
      ),
      body: ListView.builder(
        itemBuilder: (context, index) {
          var item = items[index];
          return Dismissible(
            key: ValueKey(item),
            child: DownloadCell(
              item: item,
              onTap: () async {
                Plugin? plugin = await Manager.instance.plugins.loadPlugin(item.pluginID);
                if (plugin.isValidate) {
                  OpenVideoNotification(
                    key: item.key,
                    data: item.data,
                    plugin: plugin,
                    resolution: ResolutionData(
                      title: item.videoTitle,
                      subtitle: item.videoSubtitle,
                      videoUrl: item.videoUrl,
                      key: item.videoKey,
                    ),
                  ).dispatch(context);
                } else {
                  Fluttertoast.showToast(msg: loc('no_plugin'));
                }
              },
            ),
            confirmDismiss: (_) {
              return showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(loc("confirm")),
                    content: Text(loc("delete_item").replaceFirst("{1}", item.title).replaceFirst("{0}", item.subtitle)),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        child: Text(loc("no"))
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        child: Text(loc("yes"))
                      ),
                    ],
                  );
                },
              );
            },
            onDismissed: (_) {
              setState(() {
                Manager.instance.downloads.remove(item);
              });
            },
          );
        },
        itemCount: items.length,
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    // Manager.instance.downloads.addListener(_update);
  }

  @override
  void dispose() {
    super.dispose();
    // Manager.instance.downloads.removeListener(_update);
  }

}