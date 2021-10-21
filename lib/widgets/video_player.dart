
import 'package:flutter/cupertino.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class VideoPlayer extends StatefulWidget {

  final String dataSource;

  VideoPlayer({
    Key? key,
    required this.dataSource,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {

  late VlcPlayerController controller;
  double aspectRatio = 16 / 9;

  @override
  Widget build(BuildContext context) {
    return VlcPlayer(
      controller: controller,
      aspectRatio: aspectRatio
    );
  }

  @override
  void initState() {
    super.initState();
    controller = VlcPlayerController.network(widget.dataSource);
    controller.addListener(_update);
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
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