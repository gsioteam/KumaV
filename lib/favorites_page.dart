

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:glib/core/array.dart';
import 'package:glib/main/context.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/project.dart';
import 'package:kumav/utils/video_notification.dart';
import 'configs.dart';
import 'widgets/home_widget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'localizations/localizations.dart';
import 'utils/favorites_manager.dart';
import 'widgets/better_snack_bar.dart';

class _FavKey extends GlobalObjectKey {
  _FavKey(value) : super(value);
}

class FavoriteItem extends StatefulWidget {
  void Function() onTap;
  FavCheckItem item;
  Animation<double> animation;
  void Function() onDismiss;

  FavoriteItem({
    Key key,
    this.onTap,
    this.item,
    this.animation,
    this.onDismiss
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FavoriteItemState();
}

class _FavoriteItemState extends State<FavoriteItem> {
  String title;
  String subtitle;
  String picture;

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: widget.animation,
      child: Dismissible(
        background: Container(color: Colors.red,),
        key: ObjectKey(widget.item),
        child: ListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          leading: Image(
            image: CachedNetworkImageProvider(picture),
            fit: BoxFit.cover,
            width: 56,
            height: 56,
            gaplessPlayback: true,
          ),
          onTap: () {
            setState(() {
              widget.onTap();
            });
          },
          trailing: widget.item.hasNew ? Icon(Icons.fiber_new, color: Colors.red,) : null,
        ),
        onDismissed: (direction) {
          widget.onDismiss?.call();
        },
      ),
    );
  }

  onStateChanged() {
    setState(() { });
  }

  @override
  void initState() {
    super.initState();
    widget.item.onStateChanged = onStateChanged;
    title = widget.item.item.title;
    subtitle = widget.item.item.subtitle;
    picture = widget.item.item.picture;
  }

  @override
  void dispose() {
    super.dispose();
    widget.item.onStateChanged = null;
  }

  @override
  void didUpdateWidget(FavoriteItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.item.onStateChanged = onStateChanged;
  }
}

class FavoritesPage extends HomeWidget {
  @override
  String get title => "favorites";

  @override
  State<StatefulWidget> createState() {
    return _FavoritesPageState();
  }
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<FavCheckItem> items;
  List<BetterSnackBar<bool>> snackBars = List();
  GlobalKey<AnimatedListState> _listKey = GlobalKey();

  itemClicked(int idx) async {
    FavCheckItem checkItem = items[idx];
    DataItem item = checkItem.item;
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
    } else {
      Fluttertoast.showToast(msg: kt("can_not_determine_the_context_type"));
      project.release();
      return;
    }
    
    VideoNotification(ctx, project).dispatch(context);
    
    project.release();
  }

  void onRemoveItem(FavCheckItem item) async {
    int index = items.indexOf(item);
    if (index >= 0) {
      setState(() {
        items.removeAt(index);
      });
      _listKey.currentState.removeItem(index, (context, animation) {
        return Container();
      }, duration: Duration(milliseconds: 0));

      BetterSnackBar<bool> snackBar;
      snackBar = BetterSnackBar<bool>(
        title: kt("confirm"),
        subtitle: kt("delete_item_2").replaceAll("{0}", item.item.title),
        trailing: TextButton(
          child: Text(kt("undo"), style: Theme.of(context).textTheme.bodyText2.copyWith(color: Colors.white, fontWeight: FontWeight.bold),),
          onPressed: () {
            snackBar.dismiss(true);
          },
        ),
        duration: Duration(seconds: 5)
      );


      snackBars.add(snackBar);

      bool result = await snackBar.show(context);
      print("dismiss ${item.item.title}");
      if (result == true) {
        reverseItem(item, index);
      } else {
        removeItem(item);
      }

      snackBars.remove(snackBar);
    }
  }

  void reverseItem(FavCheckItem item, int index) {
    setState(() {
      if (index < items.length) {
        items.insert(index, item);
      } else {
        index = items.length;
        items.add(item);
      }
    });
    _listKey.currentState.insertItem(index, duration: Duration(milliseconds: 300));
  }

  void removeItem(FavCheckItem item) {
    FavoritesManager().remove(item);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      initialItemCount: items.length,
      itemBuilder: (context, index, animation) {
        FavCheckItem item = items[index];
        return FavoriteItem(
          key: _FavKey(item),
          animation: animation,
          item: item,
          onTap: () {
            itemClicked(index);
          },
          onDismiss: () {
            onRemoveItem(item);
          },
        );
      },
    );
  }

  @override
  void initState() {
    items = List<FavCheckItem>.from(FavoritesManager().items);
    super.initState();
  }

  @override
  void dispose() {
    snackBars.forEach((element) {
      element.dismiss(false);
    });
    snackBars.clear();
    super.dispose();
  }
}