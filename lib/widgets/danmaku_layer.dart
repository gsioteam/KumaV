
import 'package:flutter/cupertino.dart';
import 'package:gitissues/gitissues.dart';
import 'package:kuma_player/kuma_player.dart';
import 'package:kumav/widgets/danmaku_widget.dart';

class GitIssueDanmakuController extends DanmakuController {
  final GitIssue issue;
  bool disposed = false;
  DateTime lastDate = DateTime.fromMillisecondsSinceEpoch(0);
  List<int> _cacheComment = [];
  // void Function(List<DanmakuItem>) onInsertItems;

  GitIssueDanmakuController(KumaPlayerController videoController, {
    this.issue,
    // this.onInsertItems
  }) : super(videoController) {
    _run();
  }


  bool hasCache(Comment comment) {
    return _cacheComment.contains(comment.id);
  }

  void _run() async {
    while (true) {
      if (disposed) break;
      await _request();
      await Future.delayed(Duration(seconds: 5));
    }
  }

  Future<void> _request() async {
    const int PAGE_COUNT = 100;
    while (true) {
      print("Start req ${issue.identifier}");
      List<Comment> comments = await issue.fetch(
        since: lastDate,
        size: PAGE_COUNT,
      );
      print("after req ${issue.identifier}");
      if (disposed) return;

      List<DanmakuItem> items = [];
      for (var comment in comments) {
        if (hasCache(comment)) continue;
        items.add(
            DanmakuItem(comment.body, comment.id)
        );
      }
      _cacheComment.clear();
      if (comments.length > 0) {
        lastDate = comments.last.created.add(Duration(milliseconds: 1));
        addAll(items);
        // onInsertItems?.call(items);
      }
      if (comments.length < PAGE_COUNT) {
        break;
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    disposed = true;
  }

  void insertComment(Comment comment) {
    _cacheComment.add(comment.id);
    postComment(DanmakuItem(comment.body, comment.id));
  }
}