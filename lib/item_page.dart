
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glib/core/array.dart';
import 'package:glib/core/callback.dart';
import 'package:glib/core/gmap.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/models.dart';
import 'package:glib/main/project.dart';
import 'package:kuma_player/kuma_player.dart';
import 'package:kumav/configs.dart';
import 'package:kumav/utils/controller.dart';
import 'package:kumav/utils/download_manager.dart';
import 'package:kumav/utils/history_manager.dart';
import 'package:kumav/utils/video_notification.dart';
import 'package:kumav/widgets/better_refresh_indicator.dart';
import 'package:kumav/widgets/fullscreen_player.dart';
import 'package:kumav/widgets/overlay_alert.dart';
import 'package:kumav/widgets/tap_detector.dart';
import 'utils/event_listener.dart';
import 'widgets/full_kuma_player.dart';
import 'dart:math' as math;
import 'package:glib/main/error.dart' as glib;

import 'widgets/overlay_menu.dart';
import 'widgets/player_controller.dart';
import 'widgets/video_widget.dart';
import 'localizations/localizations.dart';
import 'utils/favorites_manager.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'utils/video_load_item.dart';
// import 'package:flutter_anywhere_menus/flutter_anywhere_menus.dart';

const double MINI_SIZE = 68;
const double MINI_WIDTH = 120;

enum ItemPageStatus {
  Fullscreen,
  InPage,
  SmallWindow,
  Hidden
}

enum SortType {
  Default,
  Title,
  Subtitle
}

class ItemController {
  final EventListener<VideoNotification> onPlay = EventListener();
  Future<bool> Function() onWillPop;
  bool _isSetup = false;
  VoidCallback _onComplete;

  Future<void> _setup(BuildContext context) {
    _isSetup = true;
    Completer<void> completer = Completer();
    Overlay.of(context).insert(OverlayEntry(
        builder: (context) {
          return ItemPage(controller: this, size: MediaQuery.of(context).size);
        }
    ));
    _onComplete = () {
      completer.complete();
    };
    return completer.future;
  }

  void play(BuildContext context, VideoNotification notification) async {
    if (!_isSetup) {
      _isSetup = true;
      notification.context?.control();
      notification.project?.control();
      await _setup(context);
      onPlay.call(notification);
      notification.context?.release();
      notification.project?.release();
    } else {
      onPlay.call(notification);
    }
  }

  Future<bool> willPop() {
    return onWillPop == null ? SynchronousFuture(true) : onWillPop.call();
  }
}

class ItemPage extends StatefulWidget {
  final ItemController controller;
  final Size size;

  ItemPage({
    Key key,
    @required this.controller,
    @required this.size
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ItemPageState();
}

class Bound {
  final double left, right, top, bottom;

  Bound({
    this.left = 0,
    this.right = 0,
    this.top = 0,
    this.bottom = 0
  });

  static Bound mix(Bound from, Bound to, double p) {
    return Bound(
      left: from.left + (to.left - from.left) * p,
      right: from.right + (to.right - from.right) * p,
      top: from.top + (to.top - from.top) * p,
      bottom: from.bottom + (to.bottom - from.bottom) * p
    );
  }
}


class _ItemVideoData extends VideoData {

  _ItemVideoData(this.data) {
    list = List<String>.from(data.map((e) => e.name));
  }

  List<VideoLoadData> data;
  List<String> list;
  String currentUrl;
  int currentIndex;
  int initialIndex;

  @override
  Future<String> load(int index) async {
    currentUrl = null;
    currentUrl = await data[index].load();
    currentIndex = index;
    return currentUrl;
  }

  String key;

  DataItem get currentItem => data[currentIndex].dataItem;
}

class _DownloadItem {
  final int index;
  bool done = false;
  Error error;

  _DownloadItem(this.index);
}

class _SliverBar extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverBar(this.child);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.grey,
                blurRadius: 2
            )
          ]
      ),
      child: child,
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    if (oldDelegate is _SliverBar) {
      return child != oldDelegate.child;
    }
    return false;
  }

}

enum _DownloadStatus {
  None,
  Collect,
  Processing
}

class _ProcessResult {
  VideoLoadItem loader;
  VideoLoadData data;
  Error error;
  _DownloadItem item;
  String videoUrl;
}

class _ProcessPipe {
  Stream<_ProcessResult> stream;
  bool canceled = false;

  _ProcessPipe(this.stream);
}

class _ItemPageState extends State<ItemPage> with SingleTickerProviderStateMixin {
  AnimationController controller;
  Bound from = Bound();
  Bound to = Bound();
  Bound current;
  ItemPageStatus status = ItemPageStatus.Hidden;
  Context itemContext;
  Project project;
  BetterRefreshIndicatorController refreshController;
  String targetLink;
  String initialVideoUrl;
  AutoScrollController scrollController;

  int currentIndex = -1;
  SortType sortType = SortType.Default;
  _ItemVideoData videoData;
  bool hasError;

  int orderIndex = R_ORDER;
  GlobalKey menuKey = GlobalKey();

  static const String ORDER_TYPE = "order";

  static const int ORDER = 0;
  static const int R_ORDER = 1;

  static const String SORT_TYPE = "sort_type";

  Array data;

  Controller<MenuStatus, MenuEvent, void> menuController1 = Controller();
  Controller<MenuStatus, MenuEvent, void> menuController2 = Controller();
  Controller<MenuStatus, MenuEvent, void> menuController3 = Controller();

  OverlayDialog<bool> alertDialog;

  _DownloadStatus downloadStatus = _DownloadStatus.None;
  Map<int, _DownloadItem> downloadSelected = {};

  String get lastChapterKey {
    if (itemContext != null) {
      DataItem bookItem = itemContext.infoData;
      return "$last_video_key:${bookItem.projectKey}:${bookItem.link}";
    }
    return null;
  }

  Widget createItem(int index) {
    DataItem item = data[index];
    Widget buildTrailing() {
      const double circleSize = 18;
      switch (downloadStatus) {
        case _DownloadStatus.Collect: {
          return Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(circleSize/2)),
              border: Border.all(
                color: Colors.black54,
                width: 2
              )
            ),
            child: downloadSelected.containsKey(index) ? Icon(Icons.circle, size: 12) : null,
          );
        }
        case _DownloadStatus.Processing: {
          if (downloadSelected.containsKey(index)) {
            _DownloadItem item = downloadSelected[index];
            if (item.done) {
              return Icon(Icons.done, size: circleSize,);
            } else {
              return Container(
                width: circleSize,
                height: circleSize,
                child: SpinKitRing(
                  color: Colors.black54,
                  size: circleSize,
                  lineWidth: 2,
                ),
              );
            }
          }
          break;
        }
        default:
          break;
      }
      return null;
    }

    return AutoScrollTag(
      key: ValueKey(index),
      controller: scrollController,
      index: index,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.play_arrow, color: (currentIndex == index) ? Theme.of(context).primaryColor : Colors.transparent,),
            title: Text(item.title),
            subtitle: item.subtitle.isEmpty ? null : Text(item.subtitle),
            onTap: () {
              if (downloadStatus == _DownloadStatus.None) {
                setState(() {
                  currentIndex = index;
                  _readVideoAndPlay(this.data[currentIndex]);
                });
              } else if (downloadStatus == _DownloadStatus.Collect) {
                setState(() {
                  if (downloadSelected.containsKey(index)) {
                    downloadSelected.remove(index);
                  } else {
                    downloadSelected[index] = _DownloadItem(index);
                  }
                });
              }
            },
            trailing: buildTrailing(),
          ),
          Divider(height: 1,)
        ],
      )
    );
  }

  Future<_ProcessResult> _loadDownloadIndex(DataItem dataItem) async {
    Completer<_ProcessResult> completer = Completer();
    var temp = _ProcessResult();
    String key = "${dataItem.projectKey}:${dataItem.link}";
    temp.loader = VideoLoadItem(
      dataItem,
      project,
      onComplete: (items, idx) {
        String str = KeyValue.get("$video_select_key:$key");
        int idx = int.tryParse(str) ?? 0;
        if (idx < items.length) {
          temp.data = items[idx];
        } else {
          temp.data = items[0];
        }
        completer.complete(temp);
      },
      onError: (error) {
        temp.error = error;
        completer.complete(temp);
      },
      readCache: true,
    );

    return completer.future;
  }

  Stream<_ProcessResult> _startDownloadProcess() async* {
    List<_DownloadItem> items = List.from(downloadSelected.values);
    items.sort((item1, item2) => item1.index - item2.index);

    for (var item in items) {
      DataItem dataItem = this.data[item.index];
      var result = await _loadDownloadIndex(dataItem);
      result.item = item;
      if (result.error == null) {
        try {
          result.videoUrl = await result.data.load();
        } catch (e) {
          item.error = e;
        }
        item.done = true;
        yield result;
      } else {
        item.done = true;
        item.error = result.error;
        yield result;
      }
    }
  }

  _ProcessPipe currentPipe;

  void _runDownload(_ProcessPipe pipe) async {
    currentPipe = pipe;
    bool hasError = false;
    Set<_DownloadItem> readyItem = Set();
    bool first = true;
    await for (var result in pipe.stream) {
      if (pipe.canceled) {
        currentPipe = null;
        return;
      } else {
        if (first) {
          first = false;
        } else {
          await Future.delayed(Duration(seconds: 2));
        }
        if (result.error != null) {
          hasError = true;
          DataItem dataItem = data[result.data.index];
          Fluttertoast.showToast(
              msg: "${kt("can_not_download")} <${dataItem.title}>",
              toastLength: Toast.LENGTH_SHORT
          );
          await Future.delayed(Duration(seconds: 2));
          setState(() {
            downloadSelected.removeWhere((key, value) => readyItem.contains(value));
            downloadStatus = _DownloadStatus.Collect;
          });
          break;
        } else {
          DataItem detailItem = itemContext.infoData;
          DataItem chapterData = data[result.item.index];
          DataItem dataItem = result.data.dataItem;
          String displayTitle = dataItem.title.isEmpty ? chapterData.title : "${chapterData.title} (${dataItem.title})";
          var item = DownloadManager().add(dataItem, DownloadItemData(
            title: detailItem.title,
            subtitle: detailItem.subtitle,
            picture: detailItem.picture,
            link: detailItem.link,
            videoUrl: result.videoUrl,
            displayTitle: displayTitle,
            indexLink: chapterData.link,
          ));
          if (item != null) {
            item.start();
          } else {
            for (var item in DownloadManager().items) {
              if (item.item.link == dataItem.link && item.item.projectKey == dataItem.projectKey) {
                item.start();
                break;
              }
            }
          }
          readyItem.add(result.item);
          setState(() { });
        }
      }
    }
    if (!hasError) {
      setState(() {
        downloadSelected.clear();
        downloadStatus = _DownloadStatus.None;
      });
    }
    currentPipe = null;
  }

  Widget buildHeader(DataItem dataItem, ThemeData theme) {
    if (itemContext == null) return Container();
    return Row(
      children: [
        Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dataItem?.title ?? "",
                    style: theme.textTheme.bodyText2.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Padding(padding: EdgeInsets.only(top: 6)),
                  Text(dataItem?.subtitle ?? "",
                    style: theme.textTheme.bodyText2.copyWith(color: Colors.grey),
                  )
                ],
              ),
            )
        ),
        // IconButton(
        //     padding: EdgeInsets.all(5),
        //     onPressed: () {
        //       if (currentIndex >= 0 && videoData?.currentUrl != null && videoData?.currentItem != null) {
        //         DataItem detailItem = itemContext.infoData;
        //         DataItem chapterData = data[currentIndex];
        //         DataItem dataItem = videoData.currentItem;
        //         String displayTitle = dataItem.title.isEmpty ? chapterData.title : "${chapterData.title} (${dataItem.title})";
        //         var item = DownloadManager().add(dataItem, DownloadItemData(
        //           title: detailItem.title,
        //           subtitle: detailItem.subtitle,
        //           picture: detailItem.picture,
        //           link: detailItem.link,
        //           videoUrl: videoData?.currentUrl,
        //           displayTitle: displayTitle,
        //         ));
        //         if (item != null) {
        //           item.start();
        //         } else {
        //           for (var item in DownloadManager().items) {
        //             if (item.item == dataItem) {
        //               item.start();
        //               break;
        //             }
        //           }
        //         }
        //         Fluttertoast.showToast(
        //             msg: "${kt("start_download")} <$displayTitle>",
        //             toastLength: Toast.LENGTH_SHORT
        //         );
        //       } else {
        //         Fluttertoast.showToast(
        //             msg: kt("can_not_download"),
        //             toastLength: Toast.LENGTH_SHORT
        //         );
        //       }
        //     },
        //     icon: Icon(Icons.file_download, color: Theme.of(context).primaryColor,)
        // ),
        IconButton(
          padding: EdgeInsets.all(5),
          onPressed: () {
            setState(() {
              var manager = FavoritesManager();
              var data = itemContext.infoData;
              if (manager.isFavorite(data)) {
                manager.remove(data);
              } else {
                manager.add(data);
              }
            });
          },
          icon: FavoritesManager().isFavorite(itemContext.infoData) ?
          Icon(Icons.favorite, color: Colors.red,) :
          Icon(Icons.favorite_border, color: Theme.of(context).primaryColor,
          )
        )
      ],
    );
  }

  Widget menuItem(Widget widget, bool selected) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 6),
          child: selected ? Icon(Icons.check, size: 24, color: Colors.grey,) : Container(width: 24,),
        ),
        DefaultTextStyle(
          style: TextStyle(color: Colors.black87),
          child: widget
        )
      ],
    );
  }

  bool reloadData = false;

  @override
  Widget build(BuildContext context) {
    bool refuse = KeyValue.get("refuse_overlay") == "true";
    DataItem dataItem = itemContext?.infoData;
    var theme = Theme.of(context);

    SliverPersistentHeaderDelegate buildSliverBar() {
      List<Widget> children = [
        Icon(Icons.list, color: Theme.of(context).primaryColor,),
        Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: Text(kt("play_list")),
            )
        ),
      ];
      switch (downloadStatus) {
        case _DownloadStatus.Collect: {
          children.addAll([
            IconButton(
                icon: Icon(Icons.all_out, color: Theme.of(context).primaryColor),
                onPressed: () {
                  setState(() {
                    downloadSelected.clear();
                  });
                }
            ),
            IconButton(
                icon: Icon(Icons.adjust_sharp, color: Theme.of(context).primaryColor),
                onPressed: () {
                  setState(() {
                    for (int i =  0, t = this.data.length; i < t; ++i) {
                      if (!downloadSelected.containsKey(i)) {
                        downloadSelected[i] = _DownloadItem(i);
                      }
                    }
                  });

                }
            ),
            VerticalDivider(),
            IconButton(
                icon: Icon(Icons.done, color: Theme.of(context).primaryColor),
                onPressed: () {
                  setState(() {
                    if (downloadSelected.isEmpty) {
                      downloadStatus = _DownloadStatus.None;
                    } else {
                      downloadStatus = _DownloadStatus.Processing;
                      // Start
                      _runDownload(_ProcessPipe(_startDownloadProcess()));
                    }
                  });
                }
            ),
          ]);
          break;
        }
        case _DownloadStatus.Processing: {
          const double circleSize = 24;
          children.addAll([
            IconButton(
              icon: Icon(Icons.clear, color: Theme.of(context).primaryColor),
              onPressed: (){
                setState(() {
                  currentPipe?.canceled = true;
                  currentPipe = null;
                  downloadStatus = _DownloadStatus.None;
                });
              }
            ),
            VerticalDivider(),
            Container(
              margin: EdgeInsets.only(left: 6, right: 6),
              width: circleSize,
              height: circleSize,
              child: SpinKitRing(
                color: Colors.lightBlueAccent,
                size: 18,
                lineWidth: 2,
              ),
            )
          ]);
          break;
        }
        case _DownloadStatus.None: {
          children.addAll([
            OverlayMenu(
              builder: (context, onPressed) {
                return IconButton(icon: Icon(Icons.sort, color: Theme.of(context).primaryColor,), onPressed: onPressed);
              },
              items: [
                OverlayMenuItem(
                    child: menuItem(Text(kt("sort_default")), sortType == SortType.Default),
                    onPressed: () => onSortChanged(SortType.Default)
                ),
                OverlayMenuItem(
                    child: menuItem(Text(kt("sort_title")), sortType == SortType.Title),
                    onPressed: () => onSortChanged(SortType.Title)
                ),
                OverlayMenuItem(
                    child: menuItem(Text(kt("sort_subtitle")), sortType == SortType.Subtitle),
                    onPressed: () => onSortChanged(SortType.Subtitle)
                ),
              ],
              controller: menuController1,
            ),
            OverlayMenu(
              builder: (context, onPressed) {
                return IconButton(
                    icon: Icon(orderIndex == ORDER ? Icons.trending_up : Icons.trending_down, color: Theme.of(context).primaryColor),
                    onPressed: onPressed
                );
              },
              items: [
                OverlayMenuItem(
                    child: menuItem(Icon(Icons.trending_up, color: Colors.black87,), orderIndex == ORDER),
                    onPressed: () {
                      onOrderChanged(ORDER);
                    }
                ),
                OverlayMenuItem(
                    child: menuItem(Icon(Icons.trending_down, color: Colors.black87,), orderIndex == R_ORDER),
                    onPressed: () {
                      onOrderChanged(R_ORDER);
                    }
                )
              ],
              controller: menuController2,
            ),
            VerticalDivider(),
            IconButton(
                icon: Icon(Icons.download_sharp, color: Theme.of(context).primaryColor),
                onPressed: () {
                  setState(() {
                    downloadSelected.clear();
                    downloadStatus = _DownloadStatus.Collect;
                  });
                }
            )
          ]);
          break;
        }
      }

      return _SliverBar(
        Container(
          padding: EdgeInsets.only(left: 14, top: 2, right: 14, bottom: 2),
          child: Row(
            children: children,
          ),
        )
      );
    }

    return AnimatedBuilder(
      animation: CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
      builder: (context, child) {
        current = Bound.mix(from, to, controller.value);
        var media = MediaQuery.of(context);
        double fullHeight = media.size.height - current.top - current.bottom;
        double videoHeight, videoWidth, sizeHeight = 240 + media.padding.top;
        EdgeInsets padding;

        KumaState state;

        switch (status) {
          case ItemPageStatus.InPage:
            state = KumaState.Normal;
            break;
          case ItemPageStatus.SmallWindow:
            state = KumaState.Mini;
            break;
          case ItemPageStatus.Hidden:
            state = KumaState.Close;
            break;
          case ItemPageStatus.Fullscreen:
            state = KumaState.Fullscreen;
            break;
        }
        if (fullHeight > sizeHeight) {
          videoHeight = 240;
          padding = EdgeInsets.only(top: media.padding.top);
          videoWidth = 0;
        } else {
          videoHeight = fullHeight;
          padding = EdgeInsets.zero;
          double full = media.size.width - 60 - MINI_WIDTH;
          videoWidth = (1 - (fullHeight - MINI_SIZE)/(sizeHeight - MINI_SIZE)) * full;
          if (state == KumaState.Normal)
            state = KumaState.Mini;
        }

        DataItem dataItem = itemContext?.infoData;
        return Positioned(
          left: current.left,
          right: current.right,
          top: current.top,
          bottom: current.bottom,
          child: VideoInner(
            key: GlobalObjectKey(videoData),
            data: videoData,
            videoHeight: videoHeight,
            padding: padding,
            child: child,
            state: state,
            onDrag: onDrag,
            title: dataItem?.title ?? "",
            videoWidth: videoWidth,
            subtitle: dataItem?.subtitle ?? "",
            onClose: onClose,
            onTapWhenMini: onTapWhenMini,
            onMiniClicked: toMini,
            onEnterFullscreen: onRequireFullscreen,
            onExitFullscreen: exitFullscreen,
            onReload: () {
              reloadData = true;
              _readVideoAndPlay(this.data[currentIndex]);;
            },
            showAlert: refuse ? null : (context, complete) async {
              if (alertDialog == null) {
                alertDialog = OverlayDialog(
                    builder: (context) {
                      return AlertDialog(
                        title: Text(kt("confirm")),
                        content: Text(kt("need_overlay")),
                        actions: [
                          TextButton(
                            onPressed: () {
                              KeyValue.set("refuse_overlay", "true");
                              alertDialog.dismiss(false);
                            },
                            child: Text("no")
                          ),
                          TextButton(
                            onPressed: () {
                              alertDialog.dismiss(true);
                            },
                            child: Text("ok")
                          )
                        ],
                      );
                    }
                );
              }
              bool ret = await alertDialog.show(context);
              complete(ret == true);
            },
            switchController: menuController3,
          ),
        );
      },
      child: BetterRefreshIndicator(
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildHeader(dataItem, theme),
                    Padding(
                      padding: EdgeInsets.fromLTRB(14, 6, 14, 6),
                      child: Text(dataItem?.summary ?? "", style: theme.textTheme.bodyText2.copyWith(color: Colors.black87),),
                    ),
                    Divider(height: 1,),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: buildSliverBar(),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return createItem(index);
              },
                  childCount: data?.length ?? 0
              )
            )
          ],
        ),
        controller: refreshController
      ),
    );
  }

  OverlayEntry fullscreenOverlayEntry;
  Completer<void> fullscreenCompleter;
  ItemPageStatus fullscreenOldStatus;

  Future<void> onRequireFullscreen(WidgetBuilder builder) {
    if (status == ItemPageStatus.Fullscreen) return SynchronousFuture(null);
    fullscreenOldStatus = status;
    status = ItemPageStatus.Fullscreen;
    fullscreenCompleter = Completer();
    fullscreenOverlayEntry = OverlayEntry(
      builder: builder,
      maintainState: true
    );
    Overlay.of(context).insert(fullscreenOverlayEntry);
    return fullscreenCompleter.future;
  }

  void _releaseContext() {
    itemContext?.exitView();
    itemContext?.onDataChanged = null;
    itemContext?.onLoadingStatus = null;
    itemContext?.onError = null;

    itemContext?.release();
    project?.release();
    itemContext = null;
    project = null;

    data?.release();
    data = null;
  }

  void _onPlay(VideoNotification notification) {
    if (itemContext != notification.context) {
      _releaseContext();
      itemContext = notification.context.control();
      project = notification.project.control();
      targetLink = notification.link;
      initialVideoUrl = notification.videoUrl;

      HistoryManager().insert(itemContext.infoData);
      setState(() {
        videoData = null;
      });

      toInPage();

      itemContext.onDataChanged = Callback.fromFunction(_onDataChange).release();
      itemContext.onLoadingStatus = Callback.fromFunction(_onLoadingStatus).release();
      itemContext.onError = Callback.fromFunction(_onError).release();
      itemContext.enterView();
    }
  }

  void onOrderChanged(int value) {
    if (orderIndex == value) return;
    setState(() {
      KeyValue.set(ORDER_TYPE, value.toString());
      orderIndex = value;
      if (itemContext?.data != null) {
        _updateData(itemContext?.data);
      }
    });
  }

  void onSortChanged(SortType value) {
    if (sortType == value) return;
    setState(() {
      KeyValue.set(SORT_TYPE, value.index.toString());
      sortType = value;
      if (itemContext?.data != null) {
        _updateData(itemContext?.data);
      }
    });
  }

  void onClose() {
    currentPipe?.canceled = true;
    currentPipe = null;
    downloadStatus = _DownloadStatus.None;
    var size = MediaQuery.of(context).size;
    from = current;
    to = Bound(left: from.left, right: from.right, bottom: -MINI_SIZE, top: size.height);
    controller.forward(from: 0);
    setState(() {
      videoData = null;
      status = ItemPageStatus.Hidden;
    });

    _releaseContext();
  }

  double _speed = 0;
  void onDrag(TouchState state, Offset offset) {
    Size size = MediaQuery.of(context).size;
    switch (state) {
      case TouchState.Start: {
        from = current;
        switch (status) {
          case ItemPageStatus.InPage: {
            to = Bound(left: 30, right: 30, bottom: 10, top: size.height - 10 - MINI_SIZE);
            break;
          }
          case ItemPageStatus.SmallWindow: {
            to = Bound();
            break;
          }
          default: {
            throw "Wrong status";
          }
        }
        controller.reset();
        break;
      }
      case TouchState.Move: {
        var dis = to.top - from.top;
        var per = offset.dy / dis;
        _speed = offset.dy * 0.8 + _speed * 0.2;
        controller.value = math.max(0, math.min(1, controller.value + per));
        break;
      }
      case TouchState.End: {
        var dis = to.top - from.top;
        var per = offset.dy / dis;
        controller.value = math.max(0, math.min(1, controller.value + per));
        var top = dis * controller.value + from.top;
        var fullHeight = size.height - MINI_SIZE - 10;
        switch (status) {
          case ItemPageStatus.InPage: {
            if (top > fullHeight * 0.3 || _speed > 20) {
              controller.forward();
              status = ItemPageStatus.SmallWindow;
            } else {
              toInPage();
            }
            break;
          }
          case ItemPageStatus.SmallWindow: {
            if (top < fullHeight * 0.7 || _speed < -20) {
              controller.forward();
              status = ItemPageStatus.InPage;
            } else {
              toMini();
            }
            break;
          }
          default: {
            throw "Wrong status";
          }
        }
        break;
      }
    }
  }

  void onTapWhenMini() {
    toInPage();
  }

  @override
  void initState() {
    super.initState();
    from = to = Bound(left: from.left, right: from.right, bottom: -MINI_SIZE, top: widget.size.height);
    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    controller.addStatusListener(onStatus);
    controller.reset();

    widget.controller.onPlay.add(_onPlay);
    widget.controller.onWillPop = _willPop;

    refreshController = BetterRefreshIndicatorController();
    refreshController.onRefresh = () {
      itemContext?.reload();
      return true;
    };

    scrollController = AutoScrollController();

    String order = KeyValue.get(ORDER_TYPE);
    if (order != null && order.isNotEmpty) {
      try {
        orderIndex = int.parse(order);
      } catch (e) { }
    }

    String sortType = KeyValue.get(SORT_TYPE);
    if (sortType != null && sortType.isNotEmpty) {
      try {
        this.sortType = SortType.values[int.parse(sortType)];
      } catch (e) { }
    }

    widget.controller._onComplete?.call();
  }

  void onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (this.status == ItemPageStatus.InPage) {
        int idx = currentIndex - 4;
        if (idx >= 0) {
          scrollController.scrollToIndex(currentIndex);
        } else {
          scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
        }
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
    loadItem?.finish();
    widget.controller.onPlay.remove(_onPlay);
    widget.controller.onWillPop = null;
    scrollController.dispose();
    _releaseContext();
  }

  @override
  void didUpdateWidget(ItemPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.onPlay.remove(_onPlay);
      widget.controller.onPlay.add(_onPlay);

      oldWidget.controller.onWillPop = null;
      widget.controller.onWillPop = _willPop;
    }
  }

  void _updateData(Array newData) {
    String link = targetLink;
    if (link == null) {
      link = KeyValue.get(lastChapterKey);
    }
    if ((link == null || link.isEmpty) && currentIndex >= 0 && (data?.length ?? 0) > currentIndex) {
      link = data[currentIndex]?.link;
    }
    currentIndex = 0;

    data?.release();
    data = newData.copy().control();

    switch (sortType) {
      case SortType.Default: {
        if (orderIndex == ORDER) {

        } else {
          int total = data.length, half = (total / 2).floor();
          for (int i = 0; i < half; ++i) {
            DataItem tmp = data[i];
            data[i] = data[total - i - 1];
            data[total - i - 1] = tmp;
          }
        }
        break;
      }
      case SortType.Title: {
        data.sort((v1, v2) {
          DataItem d1 = v1, d2 = v2;
          if (orderIndex == ORDER) {
            int ret = d1.title.compareTo(d2.title);
            if (ret == 0) {
              ret = d1.subtitle.compareTo(d2.subtitle);
            }
            return ret;
          } else {
            int ret = d2.title.compareTo(d1.title);
            if (ret == 0) {
              ret = d2.subtitle.compareTo(d1.subtitle);
            }
            return ret;
          }
        });
        break;
      }
      case SortType.Subtitle: {
        data.sort((v1, v2) {
          DataItem d1 = v1, d2 = v2;
          if (orderIndex == ORDER) {
            int ret = d1.subtitle.compareTo(d2.subtitle);
            if (ret == 0) {
              ret = d1.title.compareTo(d2.title);
            }
            return ret;
          } else {
            int ret = d2.subtitle.compareTo(d1.subtitle);
            if (ret == 0) {
              ret = d2.title.compareTo(d1.title);
            }
            return ret;
          }
        });
        break;
      }
    }


    if (link != null && link.isNotEmpty) {
      for (int i = 0, t = this.data.length; i < t; ++i) {
        DataItem item = this.data[i];
        if (item.link == link) {
          currentIndex = i;
          break;
        }
      }
    }
  }

  void _onDataChange(int type, Array data, int idx) {
    if (data != null) {
      if (videoData == null && data.length > 0) {
        _updateData(data);

        _readVideoAndPlay(this.data[currentIndex]);
      }
      setState(() {});
    }
  }

  void _onLoadingStatus(bool isLoading) {
    if (isLoading) {
      refreshController.startLoading();
    } else {
      refreshController.stopLoading();
    }
  }


  void _onError(glib.Error error) {
    Fluttertoast.showToast(
      msg: error.msg,
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  void exitFullscreen() {
    if (status != ItemPageStatus.Fullscreen) return;
    fullscreenOverlayEntry.remove();
    fullscreenOverlayEntry = null;
    fullscreenCompleter.complete();
    status = fullscreenOldStatus;
  }

  Future<bool> _willPop() async {
    if (menuController1.status == MenuStatus.Showing) {
      menuController1.send(MenuEvent.Miss);
      return false;
    }
    if (menuController2.status == MenuStatus.Showing) {
      menuController2.send(MenuEvent.Miss);
      return false;
    }
    if (menuController3.status == MenuStatus.Showing) {
      menuController3.send(MenuEvent.Miss);
      return false;
    }
    if (alertDialog?.display == true) {
      alertDialog.dismiss(false);
      return false;
    }
    switch (status) {
      case ItemPageStatus.InPage: {
        toMini();
        return false;
      }
      case ItemPageStatus.Fullscreen: {
        exitFullscreen();
        return false;
      }
      default: break;
    }
    return true;
  }

  void toMini() {
    from = current;
    Size size = MediaQuery.of(context).size;
    to = Bound(left: 30, right: 30, bottom: 10, top: size.height - 10 - MINI_SIZE);
    controller.forward(from: 0);
    if (status != ItemPageStatus.SmallWindow) {
      setState(() {
        status = ItemPageStatus.SmallWindow;
      });
    }
  }

  void toInPage() {
    from = current;
    to = Bound();
    controller.forward(from: 0);
    if (status != ItemPageStatus.InPage) {
      setState(() {
        status = ItemPageStatus.InPage;
      });
    }
  }

  VideoLoadItem loadItem;

  void _readVideoAndPlay(DataItem dataItem) async {
    String link = dataItem.link;
    KeyValue.set(lastChapterKey, link);
    loadItem?.finish();
    setState(() {
      videoData = null;
    });
    loadItem = VideoLoadItem(
      dataItem,
      project,
      videoUrl: initialVideoUrl,
      onComplete: (items, idx) {
        setState(() {
          DataItem bookItem = itemContext.infoData;
          videoData = _ItemVideoData(items)
            ..key = "${bookItem.projectKey}:$link"
            ..initialIndex = idx;
        });
      },
      onError: (error) {
        print("error $error");
        Fluttertoast.showToast(msg: "${dataItem.link} failed: ${error.toString()}");
      },
      readCache: !reloadData
    );
    initialVideoUrl = null;

    if (reloadData) {
      reloadData = false;
    }
  }
}