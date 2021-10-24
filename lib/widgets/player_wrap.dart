
import 'package:flutter/cupertino.dart';
import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kumav/extensions/js_processor.dart';

import 'video_player.dart';
import 'video_sheet.dart';

class Resolution with JsProxy, VideoResolution {

  JsValue value;

  String get title => value["title"];
  String? get url => value["url"];

  Resolution(this.value) {
    value.retain();
  }

  void dispose() {
    value.release();
  }
}

class PlayerWrap extends StatefulWidget {
  final JsValue? processor;
  final ProcessorItem? item;
  final ValueNotifier<RectValue> controller;
  final String title;
  final String subtitle;

  PlayerWrap({
    Key? key,
    this.item,
    this.processor,
    required this.controller,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PlayerWrapState();
}

class _PlayerWrapState extends State<PlayerWrap> {

  List<Resolution> resolutions = [];
  Resolution? _current;

  @override
  Widget build(BuildContext context) {
    DataSource? dataSource;
    int current = 0;
    if (_current?.url != null) {
      dataSource = DataSource(_current!.url!);
      current = resolutions.indexOf(_current!);
    }
    return VideoPlayer(
      key: ValueKey(_current),
      dataSource: dataSource,
      controller: widget.controller,
      resolutions: resolutions,
      currentSelect: current,
      onSelectResolution: (index) {
        if (index != current) {
          setState(() {
            _current = resolutions[index];
          });
        }
      },
      title: widget.title,
      subtitle: widget.item?.title ?? widget.subtitle,
    );
  }

  @override
  void initState() {
    super.initState();

    getVideo();
  }

  void getVideo() async {
    var item = widget.item;
    var processor = widget.processor;
    if (item != null && processor != null) {
      JsValue promise = processor.invoke("getVideo", [item.key, item.data]);
      try {
        JsValue list =  await promise.asFuture;
        for (int i = 0, t = list["length"]; i < t; ++i) {
          resolutions.add(Resolution(list[i]));
        }
        if (resolutions.isNotEmpty) {
          setState(() {
            _current = resolutions[0];
          });
        }
      } catch (e) {
        Fluttertoast.showToast(msg: e.toString());
      }
    }
  }

  @override
  void dispose() {
    super.dispose();

    clearResolutions();
  }

  @override
  void didUpdateWidget(covariant PlayerWrap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      clearResolutions();
      _current = null;
      getVideo();
    }
  }

  void clearResolutions() {
    for (var resolution in resolutions) {
      resolution.dispose();
    }
    resolutions.clear();
  }
}