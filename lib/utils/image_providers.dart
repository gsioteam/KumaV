
import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:kumav/utils/plugin.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

String _generateMd5(String str) =>
    hex.encode(md5.convert(utf8.encode(str)).bytes);

ImageProvider pluginImageProvider(Plugin? plugin) {
  if (plugin?.isValidate == true) {
    if (plugin!.information!.icon != null) {
      String icon = plugin.information!.icon!;
      Uri uri = Uri.parse(icon);
      if (uri.hasScheme) {
        return CachedNetworkImageProvider(
          uri.toString(),
        );
      } else {
        if (icon[0] != '/') {
          icon = '/' + icon;
        }
        if (plugin.fileSystem.exist(icon)) {
          return MemoryImage(Uint8List.fromList(plugin.fileSystem.readBytes(icon)!));
        }
      }
    }
    if (plugin.fileSystem.exist("/icon.png")) {
      return MemoryImage(plugin.fileSystem.readBytes("/icon.png")!);
    }
  }
  return CachedNetworkImageProvider(
      "https://www.tinygraphs.com/squares/${_generateMd5(plugin?.uri.toString() ?? "null")}?theme=bythepool&numcolors=3&size=180&fmt=jpg",
  );
}