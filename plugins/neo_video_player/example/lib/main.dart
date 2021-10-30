import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:neo_video_player/neo_video_player.dart';
import 'package:page_transition/page_transition.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late VideoPlayerController controller;

  @override
  void initState() {
    super.initState();

    // https://bitdash-a.akamaihd.net/content/sintel/hls/video/250kbit.m3u8
    // https://test-streams.mux.dev/x36xhzz/url_6/193039199_mp4_h264_aac_hq_7.m3u8
    controller = VideoPlayerController(Uri.parse("https://test-streams.mux.dev/x36xhzz/url_6/193039199_mp4_h264_aac_hq_7.m3u8"));
    controller.play();
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: VideoTest(controller),
      ),
    );
  }
}

class VideoTest extends StatelessWidget {

  final VideoPlayerController controller;

  VideoTest(this.controller);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 320,
            height: 180,
            child: VideoPlayer(
                controller: controller
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                  onPressed: () {
                    controller.play();
                  },
                  child: Text("play")
              ),
              TextButton(
                  onPressed: () {
                    controller.pause();
                  },
                  child: Text("pause")
              ),
              TextButton(
                  onPressed: () async {
                    SystemChrome.setPreferredOrientations([
                      DeviceOrientation.landscapeLeft,
                      DeviceOrientation.landscapeRight,
                    ]);
                    await Navigator.of(context).push(PageTransition(
                      child: Scaffold(
                        appBar: AppBar(
                          title: Text('Fullscreen'),
                        ),
                        body: VideoPlayer(
                          controller: controller,
                        ),
                      ),
                      type: PageTransitionType.fade,
                    ));
                    SystemChrome.setPreferredOrientations([
                      DeviceOrientation.portraitUp,
                    ]);
                  },
                  child: Text("fullscreen")
              )
            ],
          )
        ],
      ),
    );
  }
}