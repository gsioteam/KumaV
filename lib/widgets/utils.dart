

String _toString(int t) {
  if (t < 10 && t >= 0) {
    return "0$t";
  }else return "$t";
}

String calculateTime(Duration duration) {
  if (duration == null) return "00:00";
  return duration.inHours == 0 ?
  "${_toString(duration.inMinutes%60)}:${_toString(duration.inSeconds%60)}" :
  "${duration.inHours}:${_toString(duration.inMinutes%60)}:${_toString(duration.inSeconds%60)}";
}
