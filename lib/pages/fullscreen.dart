
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kumav/utils/video_downloader/proxy_server.dart';
import 'package:kumav/widgets/video_controller.dart';
import 'package:kumav/widgets/video_inner.dart';
import 'package:kumav/widgets/video_player.dart';
// import 'package:neo_video_player/neo_video_player.dart' as neo;
import 'package:video_player/video_player.dart' as neo;

class Fullscreen extends StatefulWidget {
  final neo.VideoPlayerController? controller;
  final ProxyItem? proxyItem;
  final List<VideoResolution> resolutions;
  final void Function(int index)? onSelectResolution;
  final VoidCallback? onReload;
  final int currentSelect;

  Fullscreen({
    Key? key,
    this.controller,
    this.proxyItem,
    this.resolutions = const [],
    this.onSelectResolution,
    this.currentSelect = 0,
    this.onReload,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FullscreenState();
}

class _FullscreenState extends State<Fullscreen> {
  @override
  Widget build(BuildContext context) {
    var padding = MediaQuery.of(context).padding;

    return Scaffold(
      body: Stack(
        children: [
          VideoInner(
            controller: widget.controller,
          ),
          Positioned.fill(
            child: SafeArea(
              child: VideoController(
                controller: widget.controller,
                proxyItem: widget.proxyItem,
                resolutions: widget.resolutions,
                currentSelect: widget.currentSelect,
                onSelectResolution: widget.onSelectResolution,
                onReload: widget.onReload,
                fullscreen: true,
              ),
            )
          )
        ],
      ),
      backgroundColor: Colors.black,
    );
  }
}