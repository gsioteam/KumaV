
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kumav/utils/video_downloader/proxy_server.dart';
import 'package:kumav/widgets/video_controller.dart';
import 'package:kumav/widgets/video_inner.dart';
import 'package:kumav/widgets/video_player.dart';
// import 'package:neo_video_player/neo_video_player.dart' as neo;
import 'package:video_player/video_player.dart' as neo;

class Fullscreen extends StatefulWidget {
  final ProxyItem? proxyItem;
  final List<VideoResolution> resolutions;
  final void Function(int index)? onSelectResolution;
  final int currentSelect;
  final VoidCallback? onReload;
  final ValueNotifier<neo.VideoPlayerController?> controller;

  Fullscreen({
    Key? key,
    required this.controller,
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

    return Scaffold(
      body: ValueListenableBuilder<neo.VideoPlayerController?>(
        valueListenable: widget.controller,
        builder: (context, value, child) {
          return _FullscreenInner(
            key: ValueKey(value),
            controller: value,
            proxyItem: widget.proxyItem,
            resolutions: widget.resolutions,
            onSelectResolution: widget.onSelectResolution,
            currentSelect: widget.currentSelect,
            onReload: widget.onReload,
          );
        },
      ),
      backgroundColor: Colors.black,
    );
  }

}

class _FullscreenInner extends StatelessWidget {
  final neo.VideoPlayerController? controller;
  final VoidCallback? onReload;
  final ProxyItem? proxyItem;
  final List<VideoResolution> resolutions;
  final void Function(int index)? onSelectResolution;
  final int currentSelect;

  _FullscreenInner({
    Key? key,
    this.controller,
    this.onReload,
    this.proxyItem,
    this.resolutions = const [],
    this.onSelectResolution,
    this.currentSelect = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: VideoInner(
            controller: controller,
          ),
        ),
        Positioned.fill(
            child: SafeArea(
              child: VideoController(
                controller: controller,
                proxyItem: proxyItem,
                resolutions: resolutions,
                currentSelect: currentSelect,
                onSelectResolution: onSelectResolution,
                onReload: onReload,
              ),
            )
        )
      ],
    );
  }
}