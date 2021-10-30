
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kumav/widgets/video_inner.dart';
import 'package:neo_video_player/neo_video_player.dart' as neo;

class Fullscreen extends StatefulWidget {

  final neo.VideoPlayerController controller;

  Fullscreen({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FullscreenState();
}

class _FullscreenState extends State<Fullscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("title"),
      ),
      body: VideoInner(
        controller: widget.controller,
      ),
    );
  }
}