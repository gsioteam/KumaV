import 'package:flutter/material.dart';
import 'package:kuma_player/kuma_player.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  KumaPlayerController controller;

  @override
  void initState() {
    super.initState();
    // Hls Video
    // String url = "https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa_video_270_400000.m3u8";
    // Mp4 Video
    String url = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
    controller = KumaPlayerController.network(url);
    controller.prepared().then((value) {
      controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Container(
            width: double.infinity,
            height: 360,
            color: Colors.black,
            child: KumaPlayer(
              controller: controller,
              overlay: true,
            ),
          ),
        ),
      ),
    );
  }
}
