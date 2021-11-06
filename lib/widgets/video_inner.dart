

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
// import 'package:neo_video_player/neo_video_player.dart' as neo;
import 'package:video_player/video_player.dart' as neo;

class VideoInner extends StatefulWidget {
  final BoxFit fit;
  final neo.VideoPlayerController? controller;
  final VoidCallback? onTap;

  VideoInner({
    Key? key,
    this.fit = BoxFit.contain,
    required this.controller,
    this.onTap,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VideoInnerState();
}

class _VideoInnerState extends State<VideoInner> {

  late Size size;

  @override
  Widget build(BuildContext context) {
    double width = 320, height = 180;
    if (size != Size.zero) {
      width = size.width;
      height = size.height;
    }
    return GestureDetector(
      child: Material(
        color: Colors.black,
        child: FittedBox(
          fit: widget.fit,
          child: SizedBox(
            width: width,
            height: height,
            child: widget.controller == null ? null : Hero(
              tag: widget.controller!,
              child: neo.VideoPlayer(
                widget.controller!,
              ),
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
    size = widget.controller?.value.size ?? Size.zero;
    widget.controller?.addListener(onUpdate);
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller?.removeListener(onUpdate);
  }

  void onUpdate() {
    if (size != widget.controller!.value.size) {
      setState(() {
        size = widget.controller!.value.size;
      });
    }
  }
}