
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:neo_video_player/src/video_player_value.dart';

import 'utils.dart';

int _idCounter = 0x38001;
bool _inited = false;
const MethodChannel _channel = const MethodChannel('neo_player');
Map<int, VideoPlayerController> _controllers = {};

class VideoPlayerController extends ValueNotifier<VideoPlayerValue> {
  late Future<void> _ready;
  Future<void> get ready => _ready;

  int _id = _idCounter++;
  int get id => _id;

  /// [mode] is only work on iOS mode 0 for AVPlayer 1 for SGPlayer.
  VideoPlayerController(Uri src, {
    int mode = 0,
    Map<String, dynamic> headers = const {},
  }) : super(VideoPlayerValue(duration: Duration.zero)) {
    if (!_inited) {
      _channel.setMethodCallHandler(_methodHandler);
    }
    _controllers[_id] = this;
    _ready = _setup(src,
      mode: mode,
      headers: headers
    );
  }

  VideoPlayerController.network(String dataSource) : this(Uri.parse(dataSource));

  static Future<dynamic> _methodHandler(MethodCall call) async {
    switch (call.method) {
      case 'update': {
        dynamic id = call.arguments['id'];
        var controller = _controllers[id];
        if (controller != null) {
          List? sizeList = call.arguments['size'];
          controller.value = controller.value.copyWith(
            duration: parseDuration(call.arguments['duration']),
            position: parseDuration(call.arguments['position']),
            isPlaying: call.arguments['isPlaying'],
            isLooping: call.arguments['isLooping'],
            isBuffering: call.arguments['isBuffering'],
            pipActive: call.arguments['pipActive'],
            volume: call.arguments['volume'],
            playbackSpeed: call.arguments['playbackSpeed'],
            errorDescription: call.arguments['errorDescription'],
            size: sizeList == null ? null : Size(sizeList[0], sizeList[1]),
          );
        }
        break;
      }
    }
  }

  Future<void> _setup(Uri src, {
    required int mode,
    required Map<String, dynamic> headers,
  }) async {
    await _channel.invokeMethod('init', {
      'id': _id,
      "src": src.toString(),
      "mode": mode,
      "headers": headers,
    });
  }

  Future<void> play() async {
    await _channel.invokeMethod("play", {
      'id': _id
    });
  }

  Future<void> pause() async {
    await _channel.invokeMethod("pause", {
      'id': _id
    });
  }

  Future<void> seekTo(Duration duration) async {
    await _channel.invokeMethod("seek", {
      'id': _id,
      "time": duration.inMilliseconds,
    });
  }

  Future<void> setLooping(bool looping) async {
    await _channel.invokeMethod('loop', {
      'id': _id,
      'loop': looping,
    });
  }

  Future<void> setPlaybackSpeed(double speed) async {
    await _channel.invokeMethod("setPlaybackSpeed", {
      'id': _id,
      'speed': speed,
    });
  }

  static Future<bool> canPictureInPicture() async {
    return await _channel.invokeMethod("canPictureInPicture");
  }

  Future<void> startPictureInPicture() async {
    await _channel.invokeMethod('startPictureInPicture', {
      'id': _id
    });
  }

  Future<void> stopPictureInPicture() async {
    await _channel.invokeMethod('stopPictureInPicture', {
      'id': _id
    });
  }

  Future<void> setAutoPip(bool value) async {
    await _channel.invokeMethod('setAutoPip', {
      'id': _id,
      'value': value,
    });
  }

  Future<void> setVolume(double value) async {
    await _channel.invokeMethod('setVolume', {
      'id': _id,
      'value': value,
    });
  }

  @override
  void dispose() {
    super.dispose();
    _channel.invokeMethod('dispose', {
      'id': _id
    });
    _controllers.remove(_id);
  }
}