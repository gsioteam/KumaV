

import 'dart:async';
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:kuma_player/kuma_player.dart';
import 'dart:math' as math;
import 'package:yaml/yaml.dart';

enum DanmakuType {
  RightLeft,
  LeftRight,
  Script
}

class _FlyingItem {
  DanmakuItem data;
  bool initialized = false;
  double x = 0;
  double y = 0;
  double speed;
  Size size;
  bool border = false;

  _FlyingItem(this.data);

  void init(Size screenSize, DanmakuController controller) {
    assert(!initialized);
    initialized = true;
    textPainter.layout();
    size = textPainter.size;
    switch (data.type) {
      case DanmakuType.RightLeft: {
        speed = 30 + size.width / 10;
        x = screenSize.width;
        y = controller.calculateRow(x, screenSize);
        break;
      }
      case DanmakuType.LeftRight: {
        speed = 30 + size.width / 10;
        x = -size.width;
        y = controller.calculateRow(0, screenSize);
        break;
      }
      default: break;
    }
  }

  bool process(Duration step, Size screenSize) {
    switch (data.type) {
      case DanmakuType.RightLeft: {
        x -= (step.inMilliseconds / 1000) * speed;
        return x > -size.width;
      }
      case DanmakuType.LeftRight: {
        x += (step.inMilliseconds / 1000) * speed;
        return x < screenSize.width;
      }
      default: break;
    }
    return false;
  }

  Rect get rect => Rect.fromLTWH(x, y, size.width, size.height);

  TextPainter _textPainter;
  TextPainter get textPainter {
    if (_textPainter == null) {
      _textPainter = TextPainter(
        text: TextSpan(
          text: data.label,
          style: TextStyle(
            color: data.color ?? Colors.white,
            fontSize: data.size ?? 18,
          ),
        ),
        textDirection: TextDirection.ltr
      );
    }
    return _textPainter;
  }
}

class DanmakuController {
  List<_FlyingItem> flying = [];
  LinkedList<DanmakuItem> data = LinkedList();
  KumaPlayerController _videoController;
  DateTime _offsetDate;
  Duration _offsetPosition = Duration.zero;
  Duration position;
  DanmakuItem current;
  Set<int> _postComments = Set();

  bool _waitForInit = true;
  Size screenSize;

  DanmakuController(this._videoController) {
    _offsetDate = DateTime.now();
    _addListeners();
  }

  void _addListeners() {
    videoController?.addListener(_onEvent);
    videoController?.addOnSeek(_onSeek);
  }
  void _removeListeners() {
    videoController?.removeListener(_onEvent);
    videoController?.removeOnSeek(_onSeek);
  }

  void dispose() {
    _removeListeners();
  }

  KumaPlayerController get videoController => _videoController;
  set videoController(KumaPlayerController n) {
    _removeListeners();
    _videoController = n;
    _addListeners();
  }

  void addAll(Iterable<DanmakuItem> data) {
    bool firstTime = this.data.length == 0;
    List<DanmakuItem> list = List.of(data);
    list.sort((d1, d2) => d1.time.compareTo(d2.time));

    var cur = this.data.isEmpty ? null : this.data.first;
    for (var item in list) {
      while (true) {
        if (cur == null) {
          this.data.add(item);
          break;
        } else {
          if (cur.time.compareTo(item.time) < 0) {
            cur = cur.next;
          } else {
            cur.insertBefore(item);
            break;
          }
        }
      }
    }

    if (firstTime) {
      _waitForInit = true;
    }
  }

  void _checkStart(Duration position) {
    if (videoController != null && videoController.ready && this.data.length > 0) {
      var next = this.data.first;
      bool set = false;
      while (next != null) {
        if (position.compareTo(next.time) < 0) {
          current = next.previous;
          set = true;
          break;
        }
        next = next.next;
      }
      if (!set) {
        current = this.data.last;
      }
    }
  }

  void _onEvent() {
    _offsetPosition = videoController.value.position;
    _offsetDate = DateTime.now();
  }

  List<DanmakuWidgetState> links = [];
  DanmakuWidgetState _current;

  void touch(DanmakuWidgetState state) {
    links.add(state);
    _process(state);
  }

  void untouch(DanmakuWidgetState state) {
    links.remove(state);
    if (state == _current) {
      _process(links.isEmpty ? null : links.last);
    }
  }

  void _process(DanmakuWidgetState state) {
    if (_current?.onTicker == _onTicker)
      _current?.onTicker = null;
    _current = state;
    _current?.onTicker = _onTicker;
  }

  int scanOverlayPoint(Offset point) {
    int ret = 0;
    for (var item in flying) {
      if (item.initialized) {
        if (item.rect.contains(point)) {
          ++ret;
        }
      }
    }
    return ret;
  }

  static const double RowHeight = 20;
  double calculateRow(double x, Size size) {
    int rowCount = (size.height / RowHeight).floor();
    List<int> nums = List.filled(rowCount, 0);

    for (int i = 0; i < rowCount; ++i) {
      double pos = i * RowHeight;
      int num = scanOverlayPoint(Offset(x, pos));
      if (num == 0) {
        return pos;
      } else {
        nums[i] = num;
      }
    }

    if (rowCount > 0) {
      int ret = 0;
      int min = nums[0];
      for (int i = 1; i < rowCount; ++i) {
        if (min > nums[i]) {
          ret = i;
          min = nums[i];
        }
      }
      return ret * RowHeight;
    }
    return 0;
  }

  int oldState = 0;
  void _onTicker(void Function(VoidCallback) setState) {
    if (videoController.value?.isPlaying != true || screenSize == null) {
      oldState = 0;
      return;
    } else {
      if (oldState == 0) {
        _offsetPosition = videoController.value.position;
        _offsetDate = DateTime.now();
      }
      oldState = 1;
    }
    Duration newPosition = _offsetPosition + DateTime.now().difference(_offsetDate);
    if (_waitForInit) {
      _checkStart(newPosition);
      _waitForInit = false;
    } else {
    }
    if (position == null) {
      position = newPosition;
      return;
    }
    Duration delta = newPosition - position;
    position = newPosition;
    setState(() {
      for (int i = 0, t = flying.length; i < t; ++i) {
        var item = flying[i];
        if (!item.initialized) {
          item.init(screenSize, this);
        }
        if (!item.process(delta, screenSize)) {
          flying.removeAt(i);
          --i;
          --t;
        }
      }

      // collection items
      var next = current == null ? (data.isEmpty ? null : data.first) : current.next;
      while (next != null && next.time.compareTo(position) <= 0) {
        if (!_postComments.contains(next.id)) {
          flying.add(_FlyingItem(next));
        }

        current = next;
        next = next.next;
      }
    });
  }

  void postComment(DanmakuItem newItem) async {
    bool insert = false;
    for (var item in data) {
      if (newItem.time.compareTo(item.time) < 0) {
        item.insertBefore(newItem);
        insert = true;
        break;
      }
    }
    if (!insert) data.add(newItem);
    _postComments.add(newItem.id);

    flying.add(
        _FlyingItem(newItem)
          ..border = true
    );
  }

  Completer<void> _onSeek(Duration duration) {
    Completer<void> completer = Completer();
    _wait(completer.future, () {
      flying.clear();
      _postComments.clear();
      _offsetPosition = duration;
      _offsetDate = DateTime.now();
      current = null;
      _waitForInit = true;
    });
    return completer;
  }

  void _wait(Future<void> future, VoidCallback cb) async {
    await future;
    cb();
  }
}

class DanmakuItem extends LinkedListEntry<DanmakuItem> {
  String label;
  Duration time;
  DanmakuType type = DanmakuType.RightLeft;
  Color color;
  double size;
  int id;

  DanmakuItem.empty();

  DanmakuItem(String content, this.id) {
    var node = loadYaml(content);
    label = node["label"];
    time = Duration(milliseconds: node["time"]);
    String type = node["type"];
    switch (type) {
      case 'rl': {
        this.type = DanmakuType.RightLeft;
        break;
      }
      case 'lr': {
        this.type = DanmakuType.LeftRight;
        break;
      }
      case 'script': {
        this.type = DanmakuType.Script;
        break;
      }
    }
    int c = node["color"];
    color = c == null ? Colors.white : Color(c);
    size = node["size"] ?? 16;
  }

  static String typeStr(DanmakuType type) {
    switch (type) {
      case DanmakuType.RightLeft:
        return 'rl';
      case DanmakuType.LeftRight:
        return 'lr';
      case DanmakuType.Script:
        return 'script';
    }
    return "rl";
  }

  @override
  String toString() {
    List<String> lines = [];
    lines.add("label: $label");
    lines.add("time: ${time.inMilliseconds}");
    lines.add("type: ${typeStr(type)}");
    if (color != null)
      lines.add("color: ${color.value}");
    if (size != null)
      lines.add("size: $size");
    return lines.join("\n");
  }
}

class DanmakuPainter extends CustomPainter {
  final DanmakuController controller;

  Paint _borderPaint;
  Paint get borderPaint {
    if (_borderPaint == null) {
      _borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    }
    return _borderPaint;
  }

  DanmakuPainter({
    this.controller,
  });

  @override
  void paint(Canvas canvas, Size size) {
    controller.screenSize = size;

    for (int i = 0, t = controller.flying.length; i < t; ++i) {
      var item = controller.flying[i];
      if (item.initialized) {
        Rect rect = item.rect;
        if (item.border) {
          canvas.drawRect(rect, borderPaint);
        }
        item.textPainter.paint(canvas, rect.topLeft);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class DanmakuWidget extends StatefulWidget {

  final DanmakuController controller;

  DanmakuWidget({
    Key key,
    this.controller,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => DanmakuWidgetState();
}

typedef DanmakuOnTicker = void Function(void Function(VoidCallback));

class DanmakuWidgetState extends State<DanmakuWidget> with SingleTickerProviderStateMixin {

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DanmakuPainter(
        controller: widget.controller
      ),
      child: Container(),
      willChange: true,
    );
  }

  Ticker _ticker;

  @override
  void initState() {
    super.initState();

    _ticker = createTicker(_onTick);
    _ticker.start();
    _ticker.muted = _onTicker == null;

    widget.controller?.touch(this);
  }

  @override
  void dispose() {
    widget.controller?.untouch(this);
    _ticker.stop(canceled: true);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DanmakuWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.untouch(this);
      widget.controller?.touch(this);
    }
  }

  void _onTick(Duration duration) {
    onTicker?.call(setState);
  }
  DanmakuOnTicker _onTicker;
  DanmakuOnTicker get onTicker {
    return _onTicker;
  }
  set onTicker(DanmakuOnTicker onTicker) {
    _onTicker = onTicker;
    _ticker?.muted = _onTicker == null;
  }

}