
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:neo_video_player/neo_video_player.dart' as neo;
import 'package:video_player/video_player.dart' as neo;
import 'package:kumav/utils/video_downloader/proxy_server.dart';
import 'package:kumav/widgets/video_controller.dart';

import 'video_inner.dart';
import 'video_sheet.dart';

class DataSource {
  String src;
  Map<String, dynamic>? headers;

  DataSource(this.src, [this.headers]);
}

abstract class VideoResolution {
  String get title;
}

class VideoPlayer extends StatefulWidget {

  final ValueNotifier<RectValue> controller;
  final DataSource? dataSource;
  final List<VideoResolution> resolutions;
  final void Function(int index)? onSelectResolution;
  final int currentSelect;
  final String title;
  final String subtitle;

  VideoPlayer({
    Key? key,
    required this.dataSource,
    required this.controller,
    this.resolutions = const [],
    this.onSelectResolution,
    this.currentSelect = 0,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VideoPlayerState();
}

const double MinWidth = 120;

class _VideoPlayerState extends State<VideoPlayer> {

  neo.VideoPlayerController? controller;
  ProxyItem? proxyItem;

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context);
    var padding = media.padding;
    var size = media.size;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            ValueListenableBuilder<RectValue>(
              valueListenable: widget.controller,
              builder: (context, value, child) {
                return Visibility(
                    visible: value.top > padding.top,
                    child: child!
                );
              },
              child: Positioned.fill(
                child: Material(
                  color: Colors.white,
                  child: ValueListenableBuilder<RectValue>(
                    valueListenable: widget.controller,
                    builder: (context, value, child) {
                      double top = math.max(0, padding.top - value.top);
                      double height = constraints.maxHeight - top;
                      double displayHeight = size.height - value.top - value.bottom;
                      double per = 1 - (displayHeight - value.barSize) / (height * 3/4 - value.barSize);
                      return Opacity(
                        opacity: math.max(0, per),
                        child: child!
                      );
                    },
                    child: Stack(
                      children: [
                        Positioned(
                            left: MinWidth,
                            top: 0,
                            height: widget.controller.value.barSize,
                            right: 20 + 5,
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    child: Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      padding: EdgeInsets.only(left: 8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            widget.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Padding(padding: EdgeInsets.only(
                                            top: 2
                                          )),
                                          Text(
                                            widget.subtitle,
                                            style: TextStyle(
                                              color: Theme.of(context).disabledColor
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    onTap: () {
                                      VideoSheetOpenNotification().dispatch(context);
                                    },
                                  ),
                                ),
                                if (controller != null) ValueListenableBuilder<neo.VideoPlayerValue>(
                                  valueListenable: controller!,
                                  builder: (context, value, child) {
                                    return IconButton(
                                      onPressed: () {
                                        if (value.isPlaying) {
                                          controller!.pause();
                                        } else {
                                          controller!.play();
                                        }
                                      },
                                      icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
                                    );
                                  }
                                ),
                                IconButton(
                                    onPressed: () {
                                      VideoSheetCloseNotification().dispatch(context);
                                    },
                                    icon: Icon(Icons.clear)
                                ),
                              ],
                            )
                        )
                      ],
                    ),
                  )
                ),
              ),
            ),
            ValueListenableBuilder<RectValue>(
              valueListenable: widget.controller,
              builder: (context, value, child) {
                double top = math.max(0, padding.top - value.top);
                double height = constraints.maxHeight - top;
                double displayHeight = size.height - value.top - value.bottom;
                if (height < displayHeight) {
                  return Positioned(
                      top: top,
                      left: 0,
                      right: 0,
                      height: height,
                      child: child!
                  );
                } else {
                  double per = (displayHeight - value.barSize) / (height - value.barSize);
                  return Positioned(
                      top: top,
                      left: 0,
                      width: size.width * per + MinWidth * (1 - per),
                      height: displayHeight,
                      child: child!
                  );
                }
              },
              child: VideoInner(
                controller: controller,
                onTap: () {
                  VideoSheetOpenNotification().dispatch(context);
                },
              ),
            ),
            ValueListenableBuilder<RectValue>(
              valueListenable: widget.controller,
              builder: (context, value, child) {
                return IgnorePointer(
                  ignoring: value.top > padding.top,
                  child: Opacity(
                      opacity: math.min(1, math.max(0, (1 - value.top / padding.top))),
                      child: child!
                  )
                );
              },
              child: Padding(
                padding: EdgeInsets.only(
                  top: padding.top,
                ),
                child: VideoController(
                  controller: controller,
                  proxyItem: proxyItem,
                  resolutions: widget.resolutions,
                  currentSelect: widget.currentSelect,
                  onSelectResolution: widget.onSelectResolution,
                  onReload: _onReload,
                  fullscreen: false,
                ),
              ),
            )
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    var dataSource = widget.dataSource;
    if (dataSource != null) {
      try {
        Uri uri = Uri.parse(dataSource.src);
        if (uri.hasScheme) {
          proxyItem = ProxyServer.instance.get(dataSource.src, headers: dataSource.headers);
          proxyItem!.retain();
          _enableVideo();
        } else {
          Fluttertoast.showToast(msg: "The url is not validate");
        }
      } catch (e) {
        Fluttertoast.showToast(msg: "The url is not validate " + e.toString());
      }
    }
  }

  void _enableVideo() {
    controller = neo.VideoPlayerController.network(
      proxyItem!.localServerUri.toString(),
    );
    controller!.initialize().then((value) => controller!.play());

    // controller = neo.VideoPlayerController(
    //   proxyItem!.localServerUri,
    // );
    // controller!.play();
    controller!.addListener(_update);
  }

  @override
  void dispose() {
    super.dispose();
    _clearVideo();
    proxyItem?.release();
  }

  void _clearVideo() async {
    controller?.dispose();
  }

  void _update() {
//    if (controller!.value.isInitialized && _waitForPlay) {
//      controller!.play();
//      _waitForPlay = false;
//    }
  }

  void _onReload() async {
    if (controller != null) {
      setState(() {
        controller?.dispose();
        controller = null;
      });
      await Future.delayed(Duration(milliseconds: 100));
      setState(() {
        _enableVideo();
      });
    }
  }
}