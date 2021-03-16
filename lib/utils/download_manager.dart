
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:glib/core/array.dart';
import 'package:glib/main/collection_data.dart';
import 'package:glib/main/data_item.dart';
import 'package:crypto/crypto.dart';
import 'package:glib/main/models.dart';
import 'package:glib/main/project.dart';
import 'package:kuma_player/video_downloader.dart';
import 'package:kumav/utils/video_load_item.dart';
import '../configs.dart';

class DownloadItemData {
  String title;
  String picture;
  String link;
  String subtitle;
  String videoUrl;
  String displayTitle;
  String indexLink;

  DownloadItemData({
    this.title,
    this.subtitle,
    this.picture,
    this.link,
    this.videoUrl,
    this.displayTitle,
    this.indexLink,
  });
}

String generateMd5(String input) {
  return md5.convert(utf8.encode(input)).toString();
}

enum DownloadStatus {
  None,
  PendingStart,
  Ready,
  Destroy,
}

class DownloadQueueItem {
  CollectionData data;
  DataItem item;

  VideoDownloader downloader;

  double get progress => downloader.progress;
  int get speed => downloader.speed;

  VoidCallback _onState;

  set onProgress(VoidCallback cb) => downloader.onProgress = cb;
  set onSpeed(VoidCallback cb) => downloader.onSpeed = cb;
  set onState(VoidCallback cb) => _onState = cb;
  set onError(void Function(Error) cb) => downloader.onError = cb;

  DownloadItemData _info;
  DownloadItemData get info {
    if (_info == null) {
      if (data.data != null) {
        Map<String, dynamic> map = jsonDecode(data.data);
        _info = DownloadItemData(
          title: map["title"],
          picture: map["picture"],
          link: map["link"],
          subtitle: map["subtitle"],
          videoUrl: map["videoUrl"],
          displayTitle: map["displayTitle"],
          indexLink: map["indexLink"],
        );
      } else {
        _info = DownloadItemData();
      }
    }
    return _info;
  }

  DownloadState get state => downloader.state;

  DownloadManager _manager;

  factory DownloadQueueItem(CollectionData data, DownloadManager manager) {
    if (data == null) return null;
    DataItem item = DataItem.fromCollectionData(data);
    if (item == null) {
      return null;
    }
    return DownloadQueueItem._(data.control(), item.control(), manager);
  }

  DownloadQueueItem._(this.data, this.item, this._manager) {
    downloader = VideoDownloader(info.videoUrl);
    downloader.onState = () {
      if (state == DownloadState.Stop || state == DownloadState.Complete) {
        _manager.downloading.remove(this);
        _manager.checkQueue();
      }
      _onState?.call();
    };
  }

  void start() {
    if (!isDownloading) {
      if (_manager.downloading.length < _manager.queueLimit) {
        _manager.downloading.add(this);
        downloader.start();
      } else {
        if (!_manager.waiting.contains(this))
          _manager.waiting.add(this);
      }
    }
  }

  void stop() {
    if (isDownloading) {
      downloader.stop();
      _manager.waiting.remove(this);
    }
  }

  void destroy() {
    data.release();
    item.release();
    downloader.dispose();
  }

  bool get isWaiting {
    return _manager.waiting.contains(this);
  }

  bool get isDownloading {
    return _manager.waiting.contains(this) || _manager.downloading.contains(this);
  }

  bool get canReload {
    String handler = item.data["handler"];
    return handler != null && handler.isNotEmpty;
  }

  Future<void> reload() async {
    Project project = Project.allocate(item.projectKey);
    if (!project.isValidated) {
      project.release();
      throw "No project found!";
    }

    String key = "${item.projectKey}:${item.link}";
    Completer<void> completer = Completer();
    VideoLoadItem loadItem;
    try {
      DataItem dataItem = DataItem.allocate().release();
      dataItem.link = info.indexLink;
      loadItem = VideoLoadItem(
        dataItem,
        project,
        onComplete: (data, index) async {
          if (index == null) {
            String str = KeyValue.get("$video_select_key:$key");
            index = int.tryParse(str) ?? 0;
          }
          var loadData = data[index];
          try {
            String url = await loadData.load();
            if (info.videoUrl != url) {
              item.data['url'] = url;
              loadItem.context.saveData();
              info.videoUrl = url;
              this.data.release();
              this.data = item.saveToCollection(collection_download, {
                "title": info.title,
                "picture": info.picture,
                "link": info.link,
                "subtitle": info.subtitle,
                "videoUrl": info.videoUrl,
                "displayTitle": info.displayTitle,
                "indexLink": info.indexLink,
              }).control();
              downloader.dispose();
              downloader = VideoDownloader(info.videoUrl);
            }

            completer.complete();
          } catch (e) {
            completer.completeError(e);
          }
        },
        onError: (e) {
          completer.completeError(e);
        },
        readCache: false,
        videoUrl: info.videoUrl
      );
      await completer.future;
    } catch (e) {
      loadItem.finish();
      project.release();
      rethrow;
    }
    loadItem.finish();
    project.release();
  }

  int get size => downloader.size;
}

class DownloadManager {
  static DownloadManager _instance;

  List<DownloadQueueItem> _items = [];
  List<DownloadQueueItem> get items => _items;

  int queueLimit = 3;

  Set<DownloadQueueItem> downloading = Set();
  Queue<DownloadQueueItem> waiting = Queue();

  DownloadManager._() {
    Array arr = CollectionData.all(collection_download);
    for (CollectionData data in arr) {
      DownloadQueueItem queueItem = DownloadQueueItem(data, this);
      if (queueItem != null)
        items.add(queueItem);
    }
  }

  factory DownloadManager() {
    if (_instance == null) {
      _instance = DownloadManager._();
    }
    return _instance;
  }

  void checkQueue() {
    while (downloading.length < queueLimit && waiting.length > 0) {
      var item = waiting.removeFirst();
      item.start();
    }
  }

  DownloadQueueItem add(DataItem item, DownloadItemData input) {
    if (!item.isInCollection(collection_download)) {
      CollectionData data = item.saveToCollection(collection_download, {
        "title": input.title,
        "picture": input.picture,
        "link": input.link,
        "subtitle": input.subtitle,
        "videoUrl": input.videoUrl,
        "displayTitle": input.displayTitle,
        "indexLink": input.indexLink,
      });
      DownloadQueueItem queueItem = DownloadQueueItem(data, this);
      if (queueItem != null)
        items.add(queueItem);
      return queueItem;
    }
    return null;
  }

  void remove(int idx) {
    if (idx < items.length) {
      DownloadQueueItem item = items[idx];
      item.stop();
      item.data.remove();
      item.destroy();
      items.removeAt(idx);
    }
  }

  void removeItem(DownloadQueueItem item) {
    item.stop();
    item.data.remove();
    item.destroy();
    items.remove(item);
  }

  DownloadQueueItem find(DataItem item) {
    for (int i = 0, t = items.length; i < t; ++i) {
      String link = items[i].item.link;
      if (item.link == link) {
        return items[i];
      }
    }
    return null;
  }
}