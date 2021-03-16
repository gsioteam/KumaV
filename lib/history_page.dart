
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glib/core/array.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/collection_data.dart';
import 'package:glib/main/project.dart';
import 'package:kumav/utils/video_notification.dart';
import 'item_page.dart';
import 'configs.dart';
import 'localizations/localizations.dart';

import 'utils/history_manager.dart';
import 'widgets/home_widget.dart';

class HistoryPage extends HomeWidget {
  HistoryPage() : super(key: GlobalKey<_HistoryPageState>(), title: "history");

  @override
  State<StatefulWidget> createState() => _HistoryPageState();

  @override
  List<Widget> buildActions(BuildContext context, void Function() changed) {
    return [
      IconButton(
          icon: Icon(Icons.clear_all),
          onPressed: () async {
            bool ret = await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(kt(context, "confirm")),
                  content: Text(kt(context, "clear_history")),
                  actions: [
                    TextButton(
                      child: Text(kt(context, "no")),
                      onPressed: ()=> Navigator.of(context).pop(false),
                    ),
                    TextButton(
                      child: Text(kt(context, "yes")),
                      onPressed:()=> Navigator.of(context).pop(true),
                    ),
                  ],
                );
              }
            );
            if (ret == true)
              HistoryManager().clear();
          }
      )
    ];
  }
}

class _HistoryPageState extends State<HistoryPage> {

  void onChange() async {
    await Future.delayed(Duration(milliseconds: 100));
    setState(() { });
  }

  @override
  void initState() {
    super.initState();
    HistoryManager().onChange = onChange;
  }

  @override
  void dispose() {
    super.dispose();
    HistoryManager().onChange = null;
  }

  @override
  Widget build(BuildContext context) {
    List<HistoryItem> items = HistoryManager().items;
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        HistoryItem item = items[index];
        DataItem data = item.item;
        return Column(
          children: [
            ListTile(
              title: Text(data.title),
              subtitle: Text(data.subtitle),
              leading: Image(
                image: CachedNetworkImageProvider(data.picture),
                fit: BoxFit.cover,
                width: 56,
                height: 56,
                gaplessPlayback: true,
              ),
              onTap: () {
                enterPage(item);
              },
            ),
            Divider(height: 1,)
          ],
        );
      }
    );
  }

  void enterPage(HistoryItem historyItem) async {
    DataItem item = historyItem.item;
    Project project = Project.allocate(item.projectKey);
    if (!project.isValidated) {
      Fluttertoast.showToast(msg: kt("no_project_found"));
      project.release();
      return;
    }
    DataItemType type = item.type;
    Context ctx;
    if (type == DataItemType.Data) {
      ctx = project.createCollectionContext(DETAIL_INDEX, item);
      VideoNotification(ctx, project).dispatch(context);
    } else {
      Fluttertoast.showToast(msg: kt("can_not_determine_the_context_type"));
    }
    project.release();
  }
}