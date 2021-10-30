

Duration? parseDuration(double? time) {
  if (time != null) {
    return Duration(milliseconds: (time * 1000).toInt());
  }
}