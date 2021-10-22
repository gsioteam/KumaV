
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:kumav/utils/video_downloader/proxy_server.dart';
import 'package:kumav/widgets/video_controller.dart';

import 'video_sheet.dart';

class _VideoInner extends StatefulWidget {
  final BoxFit fit;
  final VlcPlayerController controller;
  final VoidCallback? onTap;

  _VideoInner({
    Key? key,
    this.fit = BoxFit.contain,
    required this.controller,
    this.onTap,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VideoInnerState();
}

class _VideoInnerState extends State<_VideoInner> {
  late Size size;

  @override
  Widget build(BuildContext context) {
    bool hasSize = size != Size.zero;
    return GestureDetector(
      child: Material(
        color: Colors.black,
        child: FittedBox(
          fit: widget.fit,
          child: SizedBox(
            width: hasSize ? size.width : 320,
            height: hasSize ? size.height : 180,
            child: VlcPlayer(
              controller: widget.controller,
              aspectRatio: hasSize ? size.width / size.height : 16 / 9,
            ),
          ),
        ),
      ),
      onTap: widget.onTap,
    );
  }

  @override
  void initState() {
    super.initState();
    var value = widget.controller.value;
    size = value.size;
    widget.controller.addListener(_update);
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.removeListener(_update);
  }

  void _update() {
    var newSize = widget.controller.value.size;
    if (size != newSize) {
      setState(() {
        size = newSize;
      });
    }
  }
}

class VideoPlayer extends StatefulWidget {

  final ValueNotifier<RectValue> controller;
  final String dataSource;

  VideoPlayer({
    Key? key,
    required this.dataSource,
    required this.controller,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VideoPlayerState();
}

const double MinWidth = 120;

class _VideoPlayerState extends State<VideoPlayer> {

  late VlcPlayerController controller;
  late ProxyItem proxyItem;
  double aspectRatio = 16 / 9;

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
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text("hello"),
                                      ),
                                    ),
                                    onTap: () {
                                      VideoSheetOpenNotification().dispatch(context);
                                    },
                                  ),
                                ),
                                ValueListenableBuilder<VlcPlayerValue>(
                                  valueListenable: controller,
                                  builder: (context, value, child) {
                                    return IconButton(
                                      onPressed: () {
                                        if (value.isPlaying) {
                                          controller.pause();
                                        } else {
                                          controller.play();
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
              child: _VideoInner(
                controller: controller,
                onTap: () {
                  VideoSheetOpenNotification().dispatch(context);
                },
              ),
            ),
            ValueListenableBuilder<RectValue>(
              valueListenable: widget.controller,
              builder: (context, value, child) {
                return Visibility(
                    visible: value.top < padding.top,
                    child: child!
                );
              },
              child: Padding(
                padding: EdgeInsets.only(
                    top: padding.top
                ),
                child: VideoController(
                  controller: controller,
                  proxyItem: proxyItem,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    proxyItem = ProxyServer.instance.get(widget.dataSource);
    proxyItem.retain();
    controller = VlcPlayerController.network(proxyItem.localServerUri.toString());
    controller.addListener(_update);
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
    proxyItem.release();
  }

  void _update() {
    var size = controller.value.size;
    if (size != Size.zero) {
      double ratio = size.width / size.height;
      if (aspectRatio != ratio) {
        setState(() {
          aspectRatio = ratio;
        });
      }
    }
  }

}