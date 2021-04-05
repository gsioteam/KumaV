library flutter_svg_provider;

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui show Image, Picture;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Rasterizes given svg picture for displaying in [Image] widget:
///
/// ```dart
/// Image(
///   width: 32,
///   height: 32,
///   image: Svg('assets/my_icon.svg'),
/// )
/// ```
abstract class Svg extends ImageProvider<SvgImageKey> {
  final String src;

  /// Size in logical pixels to render.
  /// Useful for [DecorationImage].
  /// If not specified, will use size from [Image].
  /// If [Image] not specifies size too, will use default size 100x100.
  final Size size; // nullable

  /// Width and height can also be specified from [Image] constrictor.
  /// Default size is 100x100 logical pixels.
  /// Different size can be specified in [Image] parameters
  const Svg(this.src, {this.size}) : assert(src != null);

  factory Svg.asset(String asset, {Size size}) => SvgAsset(asset, size: size);
  factory Svg.network(String url, {Size size, BaseCacheManager cacheManager, Map<String, String> headers}) => SvgNetwork(url, size: size, cacheManager: cacheManager, headers: headers);
  factory Svg.file(String path, {Size size}) => SvgFile(path, size: size);

  @override
  Future<SvgImageKey> obtainKey(ImageConfiguration configuration) {
    final double logicWidth = size?.width ?? configuration.size?.width ?? 0;
    final double logicHeight = size?.height ?? configuration.size?.width ?? 0;
    final double scale = configuration.devicePixelRatio ?? 1.0;
    return SynchronousFuture<SvgImageKey>(
      SvgImageKey(
        assetName: src,
        pixelWidth: (logicWidth * scale).round(),
        pixelHeight: (logicHeight * scale).round(),
        scale: scale,
      ),
    );
  }

  @override
  ImageStreamCompleter load(SvgImageKey key, nil) {
    return OneFrameImageStreamCompleter(
      _loadAsync(key),
    );
  }

  Future<ImageInfo> _loadAsync(SvgImageKey key) async {
    final String rawSvg = await loadResource(key);
    final DrawableRoot svgRoot = await svg.fromSvgString(rawSvg, key.assetName);
    final ui.Picture picture = svgRoot.toPicture(
      size: Size(
        key.pixelWidth.toDouble(),
        key.pixelHeight.toDouble(),
      ),
      clipToViewBox: false,
    );
    final ui.Image image = await picture.toImage(
      key.pixelWidth,
      key.pixelHeight,
    );
    return ImageInfo(
      image: image,
      scale: key.scale,
    );
  }

  Future<String> loadResource(SvgImageKey key);

  // Note: == and hashCode not overrided as changes in properties
  // (width, height and scale) are not observable from the here.
  // [SvgImageKey] instances will be compared instead.

  @override
  String toString() => '$runtimeType(${describeIdentity(src)})';
}

@immutable
class SvgImageKey {
  const SvgImageKey({
    @required this.assetName,
    @required this.pixelWidth,
    @required this.pixelHeight,
    @required this.scale,
  })  : assert(assetName != null),
        assert(pixelWidth != null),
        assert(pixelHeight != null),
        assert(scale != null);

  /// Path to svg asset.
  final String assetName;

  /// Width in physical pixels.
  /// Used when raterizing.
  final int pixelWidth;

  /// Height in physical pixels.
  /// Used when raterizing.
  final int pixelHeight;

  /// Used to calculate logical size from physical, i.e.
  /// logicalWidth = [pixelWidth] / [scale],
  /// logicalHeight = [pixelHeight] / [scale].
  /// Should be equal to [MediaQueryData.devicePixelRatio].
  final double scale;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is SvgImageKey &&
        other.assetName == assetName &&
        other.pixelWidth == pixelWidth &&
        other.pixelHeight == pixelHeight &&
        other.scale == scale;
  }

  @override
  int get hashCode => hashValues(assetName, pixelWidth, pixelHeight, scale);

  @override
  String toString() => '${objectRuntimeType(this, 'SvgImageKey')}'
      '(assetName: "$assetName", pixelWidth: $pixelWidth, pixelHeight: $pixelHeight, scale: $scale)';
}

class SvgAsset extends Svg {
  const SvgAsset(String src, {Size size}) : super(src, size: size);

  Future<String> loadResource(SvgImageKey key) async {
    return rootBundle.loadString(key.assetName);
  }
}

class SvgNetwork extends Svg {
  final BaseCacheManager cacheManager;
  final Map<String, String> headers;

  const SvgNetwork(String src, {Size size,  this.cacheManager, this.headers}) : super(src, size: size);

  @override
  Future<String> loadResource(SvgImageKey key) async {
    BaseCacheManager cacheManager = this.cacheManager ?? DefaultCacheManager();
    File file = await cacheManager.getSingleFile(key.assetName, headers: this.headers);
    return file.readAsString();
  }
}

class SvgFile extends Svg {

  const SvgFile(String src, {Size size}) : super(src, size: size);

  @override
  Future<String> loadResource(SvgImageKey key) {
    return File(key.assetName).readAsString();
  }
}