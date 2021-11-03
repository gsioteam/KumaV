
import 'package:flutter/material.dart';
import 'package:kumav/utils/get_ready.dart';
import 'package:sembast/sembast.dart';

import 'plugin.dart';
import 'video_downloader/proxy_server.dart';
import 'video_downloader/video_downloader.dart';
import 'video_item.dart';

enum DownloadItemState {
  Stop,
  Downloading,
  Complete
}

class DownloadItem extends ItemData with ChangeNotifier {

  Downloads? _manager;

  DownloadItem({
    required String key,
    required dynamic data,
    required String pluginID,
    required int date,
    required String videoUrl,
    required String title,
    required String subtitle,
    required String videoKey,
    Map? headers,
  }) : super(
    key: key,
    data: data,
    pluginID: pluginID,
    date: date,
    customer: {
      "videoKey": videoKey,
      "videoUrl": videoUrl,
      "title": title,
      "subtitle": subtitle,
      "headers": headers,
    }
  );
  DownloadItem.fromData(Map data) : super.fromData(data);

  String get videoUrl => customer["videoUrl"];
  String get videoTitle => customer["title"];
  String get videoSubtitle => customer["subtitle"];
  String get videoKey => customer["videoKey"];
  Map? get headers => customer["headers"];

  double get progress => customer["progress"] ?? 0;
  set progress(double v) => customer["progress"] = v;

  int get flag => customer["flag"] ?? 0;
  set flag(int v) => customer["flag"] = v;

  VideoDownloader? _downloader;
  VideoDownloader newVideoDownloader() {
    if (_downloader == null) {
      _downloader = VideoDownloader(videoUrl, headers:headers == null ? null : Map<String, dynamic>.from(headers!));
      _downloader!.onState = _onState;
      _downloader!.onProgress = _onProgress;
      _downloader!.onSpeed = _onSpeed;
    }
    return _downloader!;
  }

  Future<void> resume() async {
    newVideoDownloader();
    _state = DownloadItemState.Downloading;
    await _downloader!.ready;
    _downloader!.start();
  }

  Future<void> stop() async {
    if (_downloader != null) {
      _downloader!.stop();
      _downloader!.dispose();
      _downloader = null;
      _state = DownloadItemState.Stop;
    }
  }

  void _onState() {
    _state = DownloadItemState.values[_downloader!.state.index];
    notifyListeners();
    if (_downloader!.state == DownloadState.Complete) {
      flag = 1;
      _manager?.update(this);
    }
  }

  void _onProgress() {
    progress = _downloader!.progress;
    _manager?.update(this);
    notifyListeners();
  }

  void _onSpeed() {
    speed.value = _downloader!.speed;
  }

  DownloadItemState? _state;
  DownloadItemState get state {
    if (_state == null) {
      if (flag == 1) {
        _state = DownloadItemState.Complete;
      } else {
        _state = DownloadItemState.Stop;
      }
    }
    return _state!;
  }

  final ValueNotifier<int> speed = ValueNotifier<int>(0);
}

class Downloads extends GetReady with ChangeNotifier {

  static StoreRef<String, dynamic> _downloadsStoreRef = StoreRef("downloads");

  final Database database;

  List<DownloadItem> _items = [];
  List<DownloadItem> get items => List.unmodifiable(_items);

  Downloads(this.database);

  @override
  Future<void> setup() async {
    var list = await _downloadsStoreRef.find(database, finder: Finder(
      sortOrders: [
        SortOrder("date"),
      ],
    ));
    for (var data in list) {
      var downloadItem = DownloadItem.fromData(data.value);
      downloadItem.customer = Map.from(downloadItem.customer);
      downloadItem._manager = this;
      _items.add(downloadItem);
    }
    _downloadsStoreRef.addOnChangesListener(database, (transaction, changes) {
      notifyListeners();
    });
  }

  Future<DownloadItem?> add({
    required String key,
    required dynamic data,
    required Plugin plugin,
    required String videoUrl,
    required String title,
    required String subtitle,
    required String videoKey,
  }) async {
    String saveKey = ProxyServer.instance.keyFromURL(videoUrl);
    for (var item in _items) {
      if (item.videoUrl == videoUrl) return null;
    }
    var record = _downloadsStoreRef.record(saveKey);

    DownloadItem newItem = DownloadItem(
      key: key,
      data: data,
      pluginID: plugin.id,
      date: DateTime.now().millisecondsSinceEpoch,
      videoUrl: videoUrl,
      title: title,
      subtitle: subtitle,
      videoKey: videoUrl,
    );
    newItem._manager = this;
    _items.insert(0, newItem);
    await record.put(database, newItem.toData(), merge: false);
    return newItem;
  }

  Future<void> remove(DownloadItem item) async {
    _items.remove(item);
    item._manager = null;
    String saveKey = ProxyServer.instance.keyFromURL(item.videoUrl);
    var record = _downloadsStoreRef.record(saveKey);
    await record.delete(database);
  }

  Future<void> update(DownloadItem item) async {
    String saveKey = ProxyServer.instance.keyFromURL(item.videoUrl);
    var record = _downloadsStoreRef.record(saveKey);
    await record.update(database, item.toData());
  }
}