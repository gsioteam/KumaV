
import 'dart:ui';

class VideoPlayerValue {

  final Duration duration;
  final Duration position;
  final bool isPlaying;
  final bool isLooping;
  final bool isBuffering;
  final bool pipActive;
  final double volume;
  final double playbackSpeed;
  final String? errorDescription;
  final Size size;

  const VideoPlayerValue({
    required this.duration,
    this.position = Duration.zero,
    this.isPlaying = false,
    this.isLooping = false,
    this.isBuffering = false,
    this.pipActive = false,
    this.volume = 1.0,
    this.playbackSpeed = 1.0,
    this.errorDescription,
    this.size = Size.zero,
  });

  VideoPlayerValue copyWith({
    Duration? duration,
    Duration? position,
    bool? isPlaying,
    bool? isLooping,
    bool? isBuffering,
    bool? pipActive,
    double? volume,
    double? playbackSpeed,
    String? errorDescription,
    Size? size,
  }) => VideoPlayerValue(
    duration:  duration??this.duration,
    position: position??this.position,
    isPlaying: isPlaying??this.isPlaying,
    isLooping: isLooping??this.isLooping,
    isBuffering: isBuffering??this.isBuffering,
    pipActive: pipActive??this.pipActive,
    volume: volume??this.volume,
    playbackSpeed: playbackSpeed??this.playbackSpeed,
    errorDescription: errorDescription??this.errorDescription,
    size: size??this.size,
  );

  bool get hasError => errorDescription != null;
}