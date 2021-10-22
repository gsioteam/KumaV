
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kumav/widgets/video_player.dart';
import 'package:kumav/widgets/video_sheet.dart';

class OpenVideoNotification extends Notification {
  final dynamic data;
  OpenVideoNotification(this.data);
}

class Video extends StatefulWidget {
  final ScrollPhysics physics;
  final ValueNotifier<RectValue> controller;

  Video({
    Key? key,
    required this.physics,
    required this.controller,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VideoState();
}

class _VideoState extends State<Video> {
  late ScrollController controller;
  Widget? append;

  @override
  Widget build(BuildContext context) {
    // var size = MediaQuery.of(context).size;
    return AnnotatedRegion<SystemUiOverlayStyle>(
        child: Scaffold(
          body: CustomScrollView(
            physics: widget.physics,
            controller: controller,
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  height: 270,
                  color: Colors.black,
                  child: VideoPlayer(
                    dataSource: 'https://bitdash-a.akamaihd.net/content/sintel/hls/video/250kbit.m3u8',
                    controller: widget.controller,
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
          ),
        ),
        value: SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
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