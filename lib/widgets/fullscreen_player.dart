

import 'package:flutter/material.dart';
import 'package:kuma_player/kuma_player.dart';
import 'package:kumav/widgets/danmaku_layer.dart';
import 'package:kumav/widgets/full_kuma_player.dart';

class FullscreenPlayer extends StatefulWidget {

  final KumaPlayerController controller;
  final VoidCallback onExitFullscreen;
  final String videoKey;
  final VoidCallback onReload;
  final VoidCallback onTurnMini;
  final GitIssueDanmakuController danmakuController;

  FullscreenPlayer({
    @required this.controller,
    this.onExitFullscreen,
    this.videoKey,
    this.onReload,
    this.onTurnMini,
    this.danmakuController
  });

  @override
  State<StatefulWidget> createState() => _FullscreenPlayerState();
}

class _FullscreenPlayerState extends State<FullscreenPlayer> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: SafeArea(
          child: FullKumaPlayer(
            key: GlobalObjectKey(widget.controller),
            controller: widget.controller,
            state: KumaState.Fullscreen,
            topBar: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.keyboard_arrow_left),
                  color: Colors.white,
                  onPressed: widget.onExitFullscreen
                )
              ],
            ),
            onToggleFullscreen: widget.onExitFullscreen,
            videoKey: widget.videoKey,
            onReload: widget.onReload,
            onTurnMini: widget.onTurnMini,
            danmakuController: widget.danmakuController,
          ),
        ),
      ),
    );
  }
}