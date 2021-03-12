
import 'package:flutter/widgets.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/project.dart';

class VideoNotification extends Notification {
  final Context context;
  final Project project;
  final String link;
  final String videoUrl;

  VideoNotification(
    this.context,
    this.project, {
    this.link,
    this.videoUrl
  });
}