
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kumav/extensions/js_processor.dart';
import 'package:kumav/utils/favorites.dart';
import 'package:kumav/utils/manager.dart';
import 'package:kumav/utils/plugin.dart';
import 'package:kumav/widgets/player_wrap.dart';
import 'package:kumav/widgets/value_widget.dart';
import 'package:kumav/widgets/video_player.dart';
import 'package:kumav/widgets/video_sheet.dart';
import 'package:sembast/sembast.dart';

import '../localizations/localizations.dart';

enum _SortType {
  Reverse,
  Positive
}

class ResolutionData {
  String title;
  String subtitle;
  String videoUrl;
  Map? headers;
  String key;

  ResolutionData({
    required this.title,
    required this.subtitle,
    required this.videoUrl,
    required this.key,
    required this.headers,
  });
}

class OpenVideoNotification extends Notification {
  final String key;
  final dynamic data;
  final Plugin plugin;
  final ResolutionData? resolution;

  OpenVideoNotification({
    required this.key,
    required this.data,
    required this.plugin,
    this.resolution,
  });
}

class Video extends StatefulWidget {
  final ScrollPhysics physics;
  final ValueNotifier<RectValue> controller;

  Video({
    Key? key,
    required this.physics,
    required this.controller,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VideoState();
}

class _VideoHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double size;
  final dynamic key;

  _VideoHeaderDelegate({
    required this.key,
    required this.child,
    this.size = 270,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => size;

  @override
  double get minExtent => size;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    if (oldDelegate is _VideoHeaderDelegate) {
      return oldDelegate.key != key;
    }
    return true;
  }

}

class _VideoState extends State<Video> {
  late ScrollController controller;
  Widget? append;
  late VideoInfo _videoInfo;

  late Processor _processor;
  JsValue? _jsProcessor;

  ProcessorItem? _currentItem;
  _SortType _sortType = _SortType.Reverse;
  late DownloadController downloadController;

  bool loading = false;


  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      child: Scaffold(
        body: CustomScrollView(
          physics: widget.physics,
          controller: controller,
          slivers: [
            SliverPersistentHeader(
              delegate: _VideoHeaderDelegate(
                key: _currentItem,
                child: Container(
                  height: 270,
                  color: Colors.black,
                  child: PlayerWrap(
                    item: _currentItem,
                    processor: _jsProcessor,
                    controller: widget.controller,
                    title: _processor.value.title,
                    subtitle: _processor.value.subtitle,
                    downloadController: downloadController,
                  ),
                ),
                size: 270,
              ),
              pinned: true,
            ),
            ValueListenableBuilder<ProcessorValue>(
              valueListenable: _processor,
              builder: (context, value, child) {
                return SliverToBoxAdapter(
                  child: Material(
                    color: theme.canvasColor,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  value.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ValueListenableBuilder<bool>(
                                valueListenable: downloadController,
                                builder: (context, value, child) {
                                  return IconButton(
                                    icon: Icon(Icons.file_download),
                                    onPressed: value ? () {
                                      downloadController.download?.call(_videoInfo);
                                    } : null,
                                    color: theme.primaryColor,
                                    disabledColor: theme.disabledColor,
                                  );
                                },
                              ),
                              Manager.instance.favorites.contains(
                                key: _videoInfo.key,
                                plugin: _videoInfo.plugin,
                              ) ? IconButton(
                                icon: Icon(
                                  Icons.favorite,
                                ),
                                onPressed: () {
                                  setState(() {
                                    Manager.instance.favorites.remove(
                                        key: _videoInfo.key,
                                        plugin: _videoInfo.plugin
                                    );
                                  });
                                },
                                color: Colors.red,
                              ) : IconButton(
                                icon: Icon(Icons.favorite_border),
                                onPressed: () async {
                                  setState(() {
                                    _favoriteCheck(Manager.instance.favorites.add(
                                      key: _videoInfo.key,
                                      plugin: _videoInfo.plugin,
                                      data: _videoInfo.data,
                                    ));
                                  });
                                },
                                color: theme.disabledColor,
                              ),
                            ],
                          ),
                          if (value.subtitle.isNotEmpty) Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            child: Text(
                              value.subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.disabledColor,
                              ),
                            ),
                          ),
                          Text(value.description),
                        ],
                      ),
                    ),
                  )
                );
              },
            ),
            SliverPersistentHeader(
            delegate: _VideoHeaderDelegate(
                child: Material(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: theme.disabledColor.withOpacity(0.1),
                        ),
                        bottom: BorderSide(
                          color: theme.disabledColor.withOpacity(0.1),
                        ),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                    child: Center(
                      child: Row(
                        children: [
                          Icon(
                            Icons.list,
                            color: theme.disabledColor,
                          ),
                          Padding(padding: EdgeInsets.only(right: 6)),
                          Expanded(child: Text(loc("play_list"))),
                          PopupMenuButton<int>(
                            child: Icon(
                              Icons.sort,
                              color: theme.primaryColor,
                            ),
                            itemBuilder: (context) {
                              PopupMenuEntry<int> makeItem(String text, int value) {
                                return PopupMenuItem(
                                  child: Text.rich(TextSpan(
                                    children: [
                                      WidgetSpan(
                                        child: Icon(
                                          Icons.arrow_right,
                                          color: value == _sortType.index ?
                                          theme.primaryColor :
                                          Colors.transparent,
                                        ),
                                      ),
                                      TextSpan(
                                        text: text
                                      ),
                                    ]
                                  )),
                                  value: value,
                                );
                              }
                              return [
                                makeItem(loc('reverse_order'), 0),
                                makeItem(loc('order'), 1),
                              ];
                            },
                            onSelected: (index) {
                              setState(() {
                                _sortType = _SortType.values[index];
                                _oldList = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  color: theme.canvasColor,
                ),
                key: null,
                size: 48,
              ),
              pinned: true,
            ),
            ValueListenableBuilder<ProcessorValue>(
              valueListenable: _processor,
              builder: (context, value, child) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    var item = sorted[index];
                    return ListTile(
                      trailing: Icon(
                        Icons.play_circle_fill,
                        color: item == _currentItem ? theme.primaryColor : Colors.transparent,
                      ),
                      title: Text(item.title),
                      subtitle: Text(item.subtitle),
                      onTap: item.key == _videoInfo.key ? null : () {
                        setState(() {
                          _currentItem = item;
                        });
                      },
                      tileColor: item.present ? theme.colorScheme.background : theme.canvasColor,
                    );
                  },
                      childCount: sorted.length
                  ),
                );
              },
            ),
          ],
        ),
      ),
      value: SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    controller = ScrollController();

    downloadController = DownloadController();
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
    if (_jsProcessor != null)
      _jsProcessor?.invoke("dispose");
    else
      _processor.dispose();
    downloadController.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _videoInfo = ValueWidget.of<VideoInfo>(context)!;
    Manager.instance.histories.add(
      key: _videoInfo.key,
      data: _videoInfo.data,
      plugin: _videoInfo.plugin,
    );
    Manager.instance.favorites.clearNew(
      key: _videoInfo.key,
      plugin: _videoInfo.plugin,
    );
    _processor = Processor(
      _videoInfo.plugin.script!,
      _videoInfo.plugin.information!.processor,
      _videoInfo.key,
    );
    _processor.addListener(_update);
    try {
      _jsProcessor = _videoInfo.plugin.makeProcessor(_processor);
      _beginLoad();
    } catch (e) {
      Fluttertoast.showToast(msg: loc(e.toString()));
    }
  }

  void _beginLoad() async {
    var data = await _processor.loadCache(_videoInfo.plugin);
    int _oldTime = 0;
    if (data != null) {
      _oldTime = data["time"];
      _sortType = _SortType.values[data['sort_type'] ?? 0];
    }
    if (DateTime.now().millisecondsSinceEpoch - _oldTime > 3600 * 1000) {
      try {
        await _load();
      } catch (e) {
        Fluttertoast.showToast(msg: e.toString());
      }
    }
  }

  Future<void> _load() async {
    if (loading) return;
    loading = true;
    JsValue promise = _jsProcessor?.invoke("load", [_videoInfo.data]);
    await promise.asFuture;

    await _processor.saveCache(_videoInfo.plugin, {
      "time": DateTime.now().millisecondsSinceEpoch,
      "sort_type": _sortType.index,
    });
    loading = false;
  }

  List<VoidCallback> _onDataLoaded = [];

  void _update() {
    if (_currentItem == null && _processor.value.items.isNotEmpty) {
      for (var cb in _onDataLoaded) {
        cb();
      }
      _onDataLoaded.clear();
      setState(() {
        _currentItem = sorted[0];
      });
    }
  }

  List<ProcessorItem>? _oldList;
  List<ProcessorItem> _sorted = [];
  List<ProcessorItem> get sorted {
    if (_oldList != _processor.value.items) {
      _oldList = _processor.value.items;
      switch (_sortType) {
        case _SortType.Reverse: {
          _sorted = _oldList!.reversed.toList();
          break;
        }
        case _SortType.Positive: {
          _sorted = _oldList!;
          break;
        }
      }

      if (_videoInfo.resolution != null) {
        var res = _videoInfo.resolution!;
        _sorted.insert(0, ProcessorItem(
          title: res.title,
          subtitle: res.subtitle,
          key: res.key,
          data: {
            "videoUrl": res.videoUrl,
            "headers": res.headers,
          }
        )..present = true);
      }
    }
    return _sorted;
  }

  void _favoriteCheck(Future<FavoriteItem> future) async {
    var item = await future;
    if (_processor.value.items.isEmpty) {
      _onDataLoaded.add(() {
        var length = _processor.value.items.length;
        if (length > 0) {
          var last = _processor.value.items.last;
          item.itemsLength = length;
          item.lastKey = last.key;
          item.lastTitle = last.title;
          item.update();
        }
      });
    } else {
      var length = _processor.value.items.length;
      var last = _processor.value.items.last;
      item.itemsLength = length;
      item.lastKey = last.key;
      item.lastTitle = last.title;
      item.update();
    }
  }
}