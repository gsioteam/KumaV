

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glib/core/array.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/context.dart';
import 'package:glib/core/callback.dart';
import 'package:glib/main/error.dart' as glib;
import 'package:glib/main/project.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:xml_layout/xml_layout.dart';
import '../configs.dart';
import 'better_refresh_indicator.dart';
import 'item_widget.dart';
import '../utils/proxy_collections.dart';
import '../item_page.dart';
import '../utils/video_notification.dart';

class ItemListPage extends StatefulWidget {
  final Project project;
  final Context context;
  ItemListPage(this.project, this.context);

  @override
  State<StatefulWidget> createState()=>_ItemListPageState();

}

class _ItemListPageState extends State<ItemListPage> {
  Array books;
  BetterRefreshIndicatorController controller = BetterRefreshIndicatorController();
  bool cooldown = true;
  GlobalKey _nullKey = GlobalKey();

  void itemClicked(int idx) {
    openItem(books[idx]);
  }

  void openItem(DataItem item) async {
    Context ctx = widget.project.createCollectionContext(DETAIL_INDEX, item);

    VideoNotification(ctx, widget.project).dispatch(context);
  }

  bool onPullDownRefresh() {
    widget.context.reload();
    return false;
  }

  void onDataChanged(int type, Array data, int idx) {
    if (data != null) {
      setState(() {});
    }
  }

  void onLoadingStatus(bool isLoading) {
    if (isLoading) {
      controller.startLoading();
    } else {
      controller.stopLoading();
    }
  }

  void onError(glib.Error error) {
    Fluttertoast.showToast(
      msg: error.msg,
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  @override
  void initState() {
    widget.context.control();
    widget.context.onDataChanged = Callback.fromFunction(onDataChanged).release();
    widget.context.onLoadingStatus = Callback.fromFunction(onLoadingStatus).release();
    widget.context.onError = Callback.fromFunction(onError).release();
    controller.onRefresh = onPullDownRefresh;
    widget.context.enterView();
    books = widget.context.data.control();
    super.initState();
  }

  Widget cellWithData(DataItem item, int idx) {
    return makeItemWidget(context, widget.project, item, () {
      itemClicked(idx);
    });
  }

  Widget buildItem(DataItem item, int idx) {
    String itemTemp = widget.context.itemTemp;
    if (itemTemp != null) {
      return cellWithData(item, idx);
    } else {
      return XmlLayout(
        template: itemTemp,
        objects: {
          "data": _itemMap(item),
          "onClick": () {
            itemClicked(idx);
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollUpdateNotification>(
      child: BetterRefreshIndicator(
        child: buildMain(context),
        controller: controller,
      ),
      onNotification: (ScrollUpdateNotification notification) {
        if (notification.metrics.maxScrollExtent - notification.metrics.pixels < 20 && cooldown) {
          widget.context.loadMore();
          cooldown = false;
          Future.delayed(Duration(seconds: 2)).then((value) => cooldown = true);
        }
        return false;
      },
    );
  }

  Widget buildMain(BuildContext context) {
    String temp = widget.context.temp;
    if (temp.isEmpty) {
      return Stack(
        children: <Widget>[
          ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (BuildContext context, int idx) {
              if (idx < books.length) {
                DataItem book = books[idx];
                return cellWithData(book, idx);
              } else {
                return Container(height: 10,);
              }
            },
            separatorBuilder: (BuildContext context, int index) => const Divider(),
            itemCount: books.length + 1,
          ),
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: books.length == 0 ? 1 : 0,
              duration: Duration(milliseconds: 300),
              child: Center(
                child: Text("No data!", style: TextStyle(
                    color: Color.fromRGBO(0xee, 0xee, 0xee, 1),
                    shadows: [
                      Shadow(
                          offset: Offset(-1, -1),
                          blurRadius: 0,
                          color: Colors.black26
                      ),
                      Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 0,
                          color: Colors.white
                      )
                    ],
                    fontSize: 26,
                    fontFamily: "DancingScript",
                    fontWeight: FontWeight.bold
                ),),
              ),
            ),
          ),
        ],
      );
    } else {
      dynamic info_data = widget.context.infoData;
      return XmlLayout(
        template: temp,
        objects: {
          "info_data": info_data,
          "books": proxyObject(books),
          "openBook": (List args) {
            if (args.length >= 1) {
              openItem(args[0]);
            }
          },
          "buildChapterItem": (List args) {
            if (args.length >= 1) {
              int idx = args[0];
              return cellWithData(books[idx], idx);
            } else {
              print("Wrong item $args");
              return Container();
            }
          },
          "refreshController": controller
        },
        apply: (String name, List args) {
          return widget.context.applyFunction(name, args);
        }
      );
    }
  }

  @override
  void dispose() {
    widget.context.onDataChanged = null;
    widget.context.onLoadingStatus = null;
    widget.context.onError = null;
    widget.context.exitView();
    books.release();
    widget.context.release();
    data?.release();
    super.dispose();
  }

  DataItem data;
  Map<String, dynamic> _itemMap(DataItem item) {
    data?.release();
    data = item.data?.control();
    return {
      "title": item.title,
      "data": proxyObject(data),
      "summary": item.summary,
      "picture": item.picture,
      "subtitle": item.subtitle,
      "link": item.link,
      "type": item.type
    };
  }
}