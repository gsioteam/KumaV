

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/project.dart';

Widget makeItemWidget(BuildContext context, Project project, DataItem item, void Function() onTap) {
  if (item.type == DataItemType.Header) {
    ImageProvider provider;
    if (item.picture.isNotEmpty && item.picture[0] == "/") {
      File file = File(project.fullpath + item.picture);
      if (file.existsSync()) {
        provider = FileImage(file);
      }
    }else if (item.picture.isNotEmpty){
      provider = CachedNetworkImageProvider(item.picture);
    }
    var children = <Widget>[];
    if (provider != null) {
      children.add(Image(
        image: provider,
        width: 26,
        height: 26,
      ));
      children.add(Padding(padding: EdgeInsets.all(5)));
    }
    children.add(Text(item.title, style: Theme.of(context).textTheme.subtitle1,));
    return Container(
      padding: EdgeInsets.fromLTRB(5, 2, 5, 2),
      height: 30,
      child: Row(
        children: children,
      ),
    );
  } else {
    return ListTile(
      title: Text(item.title),
      subtitle: Text(item.subtitle),
      leading: Image(
        image: CachedNetworkImageProvider(item.picture),
        fit: BoxFit.cover,
        width: 56,
        height: 56,
      ),
      onTap: onTap,
    );
  }
}