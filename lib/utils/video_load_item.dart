

import 'package:glib/main/context.dart';
import 'package:glib/core/gmap.dart';
import 'package:glib/core/callback.dart';
import 'package:glib/core/array.dart';
import 'package:glib/main/data_item.dart';
import 'dart:async';

import 'package:glib/main/project.dart';
import 'package:kumav/widgets/video_widget.dart';

import '../configs.dart';

class VideoLoadData {
  int index;
  VideoLoadItem loadItem;
  String name;

  DetailData fromMap(GMap data) {
    DetailData detail = DetailData();
    String url = data["url"];
    var headers = data["headers"];
    if (headers is GMap) {
      detail.headers = Map();
      headers.forEach((key, value) {
        if (value is String)
          detail.headers[key] = value;
      });
    }
    var query = data["query"];
    if (query is GMap) {
      var uri = Uri.parse(url);
      Map<String, String> map = {};
      uri.queryParameters?.forEach((key, value) {
        map[key] = value;
      });
      query.forEach((key, value) {
        map[key] = value.toString();
      });
      var newUri = uri.replace(
        queryParameters: map
      );
      url = newUri.toString();
    }
    detail.url = url;
    return detail;
  }

  Future<DetailData> load() async {
    var data = loadItem.context.data[index].data;
    if (data is GMap) {
      var url = data["url"];
      if (url is String && Uri.tryParse(url)?.hasScheme == true) {
        return fromMap(data);
      } else {
        var handler = data["handler"];
        if (handler is String) {
          Completer<String> completer = Completer();
          Callback success = Callback.fromFunction((String url) {
            completer.complete(url);
          });
          Callback failed = Callback.fromFunction((String msg) {
            completer.completeError(new Exception(msg));
          });
          data.control();
          loadItem.context.applyFunction(handler, Array.allocate([
            data,
            success,
            failed
          ]).release());
          try {
            String url = await completer.future;
            data["url"] = url;
            loadItem.context.saveData();
            data.release();
            success.release();
            failed.release();
            return fromMap(data);
          } catch (e) {
            data.release();
            success.release();
            failed.release();
            throw e;
          }
        }
      }
    }
    return null;
  }

  DataItem get dataItem {
    return loadItem.context.data[index];
  }
}

class VideoLoadItem {
  Context context;
  void Function(List<VideoLoadData> datas, int index) onComplete;
  void Function(Error error) onError;
  bool loading = false;
  bool readCache;
  String videoUrl;

  VideoLoadItem(DataItem dataItem, Project project, {
    this.onComplete,
    this.onError,
    this.readCache = true,
    this.videoUrl,
  }) {
    context = project.createCollectionContext(VIDEO_INDEX, dataItem).control();
    context.onReloadComplete = Callback.fromFunction(_onReloadComplete).release();
    context.onDataChanged = Callback.fromFunction(_onDataChange).release();
    context.onLoadingStatus = Callback.fromFunction(_onLoadStates).release();
    context.enterView();
    if (context != null) {
      if (readCache) {
        Array data = context.data;
        if (!_processData(data) && !loading) {
          context.reload();
        }
      } else {
        context.reload();
      }
    }
  }

  void finish() {
    if (context == null) return;
    context.onDataChanged = null;
    context.onReloadComplete = null;
    context.onLoadingStatus = null;
    context.exitView();
    context.release();
    context = null;
  }

  void _onDataChange(int type, Array data, int idx) {}

  void _onLoadStates(bool loading) {
    this.loading = loading;
  }

  void _onReloadComplete() {
    Array data = context.data;
    if (!_processData(data)) {
      onError?.call(StateError("no_state"));
    }
  }

  int compareUrl(String url1, String url2) {
    if (url1 == null || url2 == null) return 0;
    Uri uri1 = Uri.parse(url1), uri2 = Uri.parse(url2);
    int score = 0;
    if (uri1.host == uri2.host) {
      ++score;
    }
    if (uri1.path == uri2.path) {
      ++score;
    }
    if (uri1.query == uri2.query) {
      ++score;
    }
    return score;
  }

  bool _processData(Array data) {
    if (data != null && data.length > 0) {
      List<VideoLoadData> datas = [];
      int index;
      int score = 0;
      for (int i = 0, t = data.length; i < t; ++i) {
        DataItem dataItem = data[i];
        String url;
        var infoData = dataItem.data;
        if (infoData is GMap) {
          url = infoData["url"];
        }
        if (videoUrl != null) {
          int ns = compareUrl(videoUrl, url);
          if (ns > score) index = i;
        }
        datas.add(
            VideoLoadData()
              ..index = i
              ..name = dataItem.title
              ..loadItem = this
        );
      }
      onComplete?.call(datas, index);
      return true;
    } else {
      return false;
    }
  }

}
