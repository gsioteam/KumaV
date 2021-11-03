
import 'package:flutter/cupertino.dart';
import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kumav/extensions/js_processor.dart';
import 'package:kumav/utils/manager.dart';

import 'video_player.dart';
import 'video_sheet.dart';
import '../localizations/localizations.dart';

class DownloadController extends ValueNotifier<bool> {
  void Function(VideoInfo videoInfo)? download;

  DownloadController() : super(false);
}

abstract class Resolution with VideoResolution {

  String get title;
  String? get url;

  void dispose();
}

class JsResolution extends Resolution with JsProxy {
  JsValue value;

  JsResolution(this.value) {
    value.retain();
  }

  @override
  void dispose() {
    value.release();
  }

  @override
  String get title => value["title"];

  @override
  String? get url => value["url"];
}

class PresentResolution extends Resolution {

  String title;

  String url;

  PresentResolution({
    required this.title,
    required this.url,
  });

  @override
  void dispose() {
  }

}

class PlayerWrap extends StatefulWidget {
  final JsValue? processor;
  final ProcessorItem? item;
  final ValueNotifier<RectValue> controller;
  final String title;
  final String subtitle;
  final DownloadController downloadController;

  PlayerWrap({
    Key? key,
    this.item,
    this.processor,
    required this.controller,
    required this.title,
    required this.subtitle,
    required this.downloadController,
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

    widget.downloadController.value = false;
    getVideo();
    widget.downloadController.download = _onDownload;
  }

  void getVideo() async {
    var item = widget.item;
    if (item?.present == true) {
      resolutions.add(PresentResolution(
        title: item!.title,
        url: item.data["videoUrl"]
      ));
      setState(() {
        _current = resolutions[0];
      });
      widget.downloadController.value = false;
    } else {
      var processor = widget.processor;
      if (item != null && processor != null) {
        JsValue promise = processor.invoke("getVideo", [item.key, item.data]);
        try {
          JsValue list =  await promise.asFuture;
          for (int i = 0, t = list["length"]; i < t; ++i) {
            resolutions.add(JsResolution(list[i]));
          }
          if (resolutions.isNotEmpty) {
            setState(() {
              _current = resolutions[0];
            });
            widget.downloadController.value = true;
          }
        } catch (e) {
          Fluttertoast.showToast(msg: e.toString());
        }
      }
    }
  }

  @override
  void dispose() {
    super.dispose();

    clearResolutions();
    if (widget.downloadController.download == _onDownload)
      widget.downloadController.download = null;
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

  void _onDownload(VideoInfo videoInfo) async {
    var resolution = _current;
    if (resolution is JsResolution && resolution.url != null) {
      var ret = await Manager.instance.downloads.add(
        key: videoInfo.key,
        data: videoInfo.data,
        plugin: videoInfo.plugin,
        videoUrl: resolution.url!,
        title: widget.item!.title,
        subtitle: widget.item!.subtitle,
        videoKey: videoInfo.key,
      );
      if (ret != null) {
        await ret.resume();
        Fluttertoast.showToast(msg: loc("start_download"));
      } else {
        Fluttertoast.showToast(msg: loc("already_downloaded"));
      }
    } else {
      Fluttertoast.showToast(msg: loc("no_video_data"));
    }
  }
}