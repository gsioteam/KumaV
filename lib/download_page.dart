
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/project.dart';
import 'package:kuma_player/video_downloader.dart';
import 'package:kumav/configs.dart';
import 'package:kumav/utils/video_notification.dart';
import 'utils/download_manager.dart';
import 'localizations/localizations.dart';
import 'widgets/better_snack_bar.dart';

import 'widgets/home_widget.dart';

class CollectionListData {
  DownloadItemData data;

  List<DownloadQueueItem> items = [];
}

enum _CellType {
  Book,
  Chapter
}

class CellData {
  _CellType type;
  bool extend = false;
  dynamic data;

  CellData({
    this.type,
    this.data
  });
}

class ChapterCell extends StatefulWidget {

  final DownloadQueueItem item;
  final void Function() onTap;
  final bool editMode;

  ChapterCell(this.item, {
    key,
    this.onTap,
    this.editMode = false
  }):super(key: key);

  @override
  State<StatefulWidget> createState() => _ChapterCellState();
}

class _ChapterCellState extends State<ChapterCell> {
  String errorStr;

  Widget controlButton(DownloadQueueItem queueItem) {
    if (queueItem.isDownloading) {
      return IconButton(
          icon: Icon(Icons.pause),
          onPressed: () {
            setState(() {
              queueItem.stop();
            });
          }
      );
    } else {
      if (queueItem.state == DownloadState.Complete) {
        return null;
      } else {
        return IconButton(
            icon: Icon(Icons.play_arrow),
            onPressed: () {
              setState(() {
                errorStr = null;
                queueItem.start();
              });
            }
        );
      }
    }
  }

  Widget extendButtons(BuildContext context, DownloadQueueItem queueItem) {
    if (widget.editMode) {
      return IconButton(
        icon: Icon(Icons.delete_outline),
        onPressed: () {

        },
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            child: controlButton(queueItem),
          ),
          Icon(Icons.chevron_right)
        ],
      );
    }

  }

  String stateString(DownloadQueueItem item) {
    if (item.state == DownloadState.Downloading) {
      String unit = 'KB/s';
      double speed = item.speed / 1024;
      if (speed > 1024) {
        unit = 'MB/s';
        speed = speed / 1024;
      }
      return "${speed.toStringAsFixed(2)} $unit";
    } else if (item.isWaiting) {
      return kt("waiting");
    } else if (errorStr != null) {
      return errorStr;
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    DownloadQueueItem queueItem = widget.item;
    DataItem item = queueItem.item;
    ThemeData theme = Theme.of(context);
    return Column(
      children: [
        Container(
          color: Colors.grey.withOpacity(0.1),
          padding: EdgeInsets.only(left: 10, right: 10),
          child: ListTile(
            title: Text(queueItem.info.displayTitle),
            subtitle: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: BoxConstraints(
                    minWidth: 40,
                  ),
                  child: Text("(${(queueItem.progress * 100).toStringAsFixed(2)}%)", style: theme.textTheme.caption,),
                  margin: EdgeInsets.only(right: 6),
                ),
                Text(stateString(queueItem), style: theme.textTheme.caption,)
              ],
            ),
            trailing: extendButtons(context, queueItem),
            onTap: widget.onTap,
          ),
        ),
        Divider(height: 1,)
      ],
    );
  }

  onProgress() {
    setState(() {});
  }

  onState() {
    setState(() {});
  }

  onError(Error err) {
    setState(() {
      errorStr = err.toString();
    });
  }

  @override
  void initState() {
    widget.item.onProgress = onProgress;
    widget.item.onState = onState;
    widget.item.onError = onError;
    widget.item.onSpeed = onProgress;
    super.initState();
  }

  @override
  void dispose() {
    widget.item.onProgress = null;
    widget.item.onState = null;
    widget.item.onError = null;
    widget.item.onSpeed = null;
    super.dispose();
  }
}

class DownloadPage extends HomeWidget {
  DownloadPage() : super(key: GlobalKey<_DownloadPageState>(), title: "download_list");

  @override
  State<StatefulWidget> createState() => _DownloadPageState();

}

class _NeedRemove {
  CellData mainData;
  DownloadQueueItem downloadItem;

  _NeedRemove(this.mainData, this.downloadItem);
}

class _DownloadKey extends GlobalObjectKey {
  _DownloadKey(Object value) : super(value);

}

class _DownloadPageState extends State<DownloadPage> {
  List<CellData> data;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  List<_NeedRemove> needRemove = List();
  List<BetterSnackBar<bool>> snackBars = List();

  _DownloadPageState();

  void clickBookCell(int index) async {
    CellData cdata = data[index];
    switch (cdata.type) {
      case _CellType.Book: {
        CollectionListData bookData = cdata.data;
        if (cdata.extend) {
          int start = index + 1;
          for (int i = start; i < data.length;) {
            CellData ndata = data[i];
            if (ndata.type != _CellType.Chapter) {
              break;
            }
            data.removeAt(i);
            _listKey.currentState.removeItem(i, (context, animation) {
              DownloadQueueItem queueItem = ndata.data;
              return SizeTransition(
                sizeFactor: animation,
                child: ChapterCell(queueItem),
              );
            });
          }
        } else {
          if (bookData.items.length > 0) {
            List<CellData> list = List(bookData.items.length);
            for (int i = 0, t = bookData.items.length; i < t; ++i) {
              list[i] = CellData(
                  type: _CellType.Chapter,
                  data: bookData.items[i]
              );
            }
            list.sort((d1, d2) {
              DownloadQueueItem item1 = d1.data, item2 = d2.data;
              return item1.info.displayTitle.compareTo(item2.info.displayTitle);
            });
            data.insertAll(index + 1, list);
            for (int offset = 0; offset < list.length; offset++) {
              _listKey.currentState.insertItem(index + 1 + offset);
            }
          }
        }
        cdata.extend = !cdata.extend;
        break;
      }
      case _CellType.Chapter: {
        DownloadQueueItem queueItem = cdata.data;
        DataItem item = queueItem.item;
        Project project = Project.allocate(item.projectKey).release();
        DataItem detailItem = DataItem();
        detailItem.allocate([]);
        var info = queueItem.info;
        detailItem.link = info.link;
        detailItem.title = info.title;
        detailItem.subtitle = info.subtitle;
        detailItem.picture = info.picture;
        Context ctx = project.createCollectionContext(DETAIL_INDEX, detailItem);
        detailItem.release();

        VideoNotification(ctx, project, link: queueItem.info.indexLink, videoUrl: info.videoUrl).dispatch(context);

        break;
      }
    }
  }

  removeItem(_NeedRemove item) {
    if (needRemove.contains(item)) {
      DownloadManager().removeItem(item.downloadItem);
      needRemove.remove(item);
    }
  }

  reverseItem(_NeedRemove item) {
    if (needRemove.contains(item)) {
      if (item.mainData.extend) {
        CollectionListData bookData = item.mainData.data;
        int i, t = bookData.items.length;
        for (i = 0; i < t; ++i) {
          DownloadQueueItem cItem = bookData.items[i];
          if (cItem.item.title.compareTo(item.downloadItem.item.title) >= 0) {
            break;
          }
        }
        bookData.items.insert(i, item.downloadItem);
        int cIndex = data.indexOf(item.mainData);
        int listIndex = cIndex + i + 1;
        data.insert(listIndex, CellData(
            type: _CellType.Chapter,
            data: item.downloadItem
        ));
        _listKey.currentState.insertItem(listIndex);
      } else {
        CollectionListData bookData = item.mainData.data;
        int i, t = bookData.items.length;
        for (i = 0; i < t; ++i) {
          DownloadQueueItem cItem = bookData.items[i];
          if (item.downloadItem.item.title.compareTo(cItem.item.title) >= 0) {
            break;
          }
        }
        bookData.items.insert(i, item.downloadItem);
      }
      needRemove.remove(item);
    }
  }

  Widget cellWithData(int index) {
    CellData cdata = data[index];
    switch (cdata.type) {
      case _CellType.Book: {
        CollectionListData downloadData = cdata.data;
        return Column(
          key: _DownloadKey(cdata),
          children: <Widget>[
            ListTile(
              title: Text(downloadData.data.title),
              subtitle: Text(downloadData.data.subtitle),
              leading: Image(
                key: ObjectKey(downloadData.data.picture),
                image: CachedNetworkImageProvider(downloadData.data.picture),
                fit: BoxFit.cover,
                width: 56,
                height: 56,
                gaplessPlayback: true,
              ),
              trailing: AnimatedCrossFade(
                  firstChild: Icon(Icons.keyboard_arrow_up),
                  secondChild: Icon(Icons.keyboard_arrow_down),
                  crossFadeState: cdata.extend ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  duration: Duration(milliseconds: 300)
              ),
              onTap: () {
                clickBookCell(index);
              },
            ),
            Divider(
              height: 1,
            )
          ],
        );
      }
      case _CellType.Chapter: {
        DownloadQueueItem queueItem = cdata.data;
        return Dismissible(
          background: Container(color: Colors.red,),
          key: _DownloadKey(cdata),
          child: ChapterCell(
            queueItem,
            onTap: () {
              clickBookCell(index);
            },
          ),
          onDismissed: (DismissDirection direction) async {
            BetterSnackBar<bool> snackBar;
            snackBar = BetterSnackBar(
              title: kt("confirm"),
              subtitle: kt("delete_item").replaceAll("{0}", queueItem.info.title).replaceAll("{1}", queueItem.item.title),
              trailing: TextButton(
                child: Text(kt("undo"), style: Theme.of(context).textTheme.bodyText2.copyWith(color: Colors.white, fontWeight: FontWeight.bold),),
                onPressed: () {
                  snackBar.dismiss(true);
                },
              ),
              duration: Duration(seconds: 5),
            );

            snackBars.add(snackBar);

            int index = data.indexOf(cdata);
            CellData mainData;
            for (int i = index - 1; i >= 0; --i) {
              CellData cellData = data[i];
              if (cellData.type == _CellType.Book) {
                mainData = cellData;
                CollectionListData bookData = mainData.data;
                bookData.items.remove(queueItem);
                break;
              }
            }

            _NeedRemove item = _NeedRemove(mainData, queueItem);
            needRemove.add(item);
            data.removeAt(index);
            _listKey.currentState.removeItem(index, (context, animation) {
              return SizeTransition(
                sizeFactor: animation,
                child: Container(),
              );
            });

            bool result = await snackBar.show(context);
            if (result == true) {
              reverseItem(item);
            } else {
              removeItem(item);
            }

            snackBars.remove(snackBar);
          },
        );
      }
    }
  }

  Widget animationItem(int idx, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: cellWithData(idx),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedList(
        key: _listKey,
        initialItemCount: data.length,
        itemBuilder: (context, index, Animation<double> animation) {
          return animationItem(index, animation);
        },
      ),
    );
  }

  @override
  void initState() {
    data = [];
    List<DownloadQueueItem> items = DownloadManager().items;
    Map<String, CollectionListData> cache = Map();
    for (int i = 0, t = items.length; i < t; ++i) {
      DownloadQueueItem item = items[i];
      CollectionListData downloadItem;
      if (cache.containsKey(item.info.link)) {
        downloadItem = cache[item.info.link];
      }
      if (downloadItem == null) {
        downloadItem = CollectionListData();
        downloadItem.data = item.info;
        cache[item.info.link] = downloadItem;
        data.add(CellData(
            type: _CellType.Book,
            data: downloadItem
        ));
      }
      downloadItem.items.add(item);
    }
    for (int i = 0, t = data.length; i < t; ++i) {
      CellData cdata = data[i];
      CollectionListData downloadItem = cdata.data;
      downloadItem.items.sort((item1, item2) => item1.item.title.compareTo(item2.item.title));
    }

    super.initState();
  }

  @override
  void dispose() {
    snackBars.forEach((element)=>element.dismiss(false));
    snackBars.clear();
    super.dispose();
  }
}