
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kumav/widgets/video_player.dart';

class Video extends StatefulWidget {
  ScrollPhysics physics;

  Video({
    Key? key,
    required this.physics,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VideoState();
}

class _VideoState extends State<Video> {
  late ScrollController controller;
  Widget? append;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: widget.physics,
      controller: controller,
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            height: 180,
            color: Colors.black,
            child: VideoPlayer(
              dataSource: 'https://bitdash-a.akamaihd.net/content/sintel/hls/video/250kbit.m3u8',
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return ListTile(
                title: Text("title $index"),
              );
            },
            childCount: 3
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    controller = ScrollController();
    controller.addListener(_onScroll);
    Future.delayed(Duration(milliseconds: 30), _onScroll);
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  void _onScroll() {
    var position = controller.position;
    print(position);
  }
}