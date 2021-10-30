import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neo_video_player/neo_video_player.dart';

void main() {
  const MethodChannel channel = MethodChannel('neo_video_player');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await NeoVideoPlayer.platformVersion, '42');
  });
}
