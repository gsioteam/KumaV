
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:neo_video_player/src/video_player_controller.dart';

class VideoPlayer extends StatefulWidget {

  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;
  final VideoPlayerController controller;

  VideoPlayer({
    Key? key,
    this.gestureRecognizers,
    required this.controller,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  @override
  Widget build(BuildContext context) {
    Map params = {
      "id": widget.controller.id
    };
    if (Platform.isAndroid) {
      // return PlatformViewLink(
      //   viewType: 'neo_player_view',
      //   surfaceFactory:
      //       (BuildContext context, PlatformViewController controller) {
      //     return AndroidViewSurface(
      //       controller: controller as AndroidViewController,
      //       gestureRecognizers: widget.gestureRecognizers ?? const <Factory<OneSequenceGestureRecognizer>>{},
      //       hitTestBehavior: PlatformViewHitTestBehavior.opaque,
      //     );
      //   },
      //   onCreatePlatformView: (PlatformViewCreationParams platformParams) {
      //     return PlatformViewsService.initSurfaceAndroidView(
      //       id: platformParams.id,
      //       viewType: 'neo_player_view',
      //       layoutDirection: TextDirection.ltr,
      //       creationParams: params,
      //       creationParamsCodec: StandardMessageCodec(),
      //     )
      //       ..addOnPlatformViewCreatedListener(platformParams.onPlatformViewCreated)
      //       ..create();
      //   },
      // );
      return AndroidView(
        viewType: 'neo_player_view',
        layoutDirection: TextDirection.ltr,
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
        gestureRecognizers: widget.gestureRecognizers,
      );
    } else if (Platform.isIOS) {
      return UiKitView(
        viewType: 'neo_player_view',
        layoutDirection: TextDirection.ltr,
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
        gestureRecognizers: widget.gestureRecognizers,
      );
    } else {
      throw Exception("Not support platform");
    }
  }
}