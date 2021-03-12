
import 'package:flutter/material.dart';
import 'package:glib/core/array.dart';
import 'package:glib/core/core.dart';
import 'package:glib/core/gmap.dart';
import 'package:glib/main/models.dart';
import 'package:glib/main/project.dart';
import 'package:glib/utils/git_repository.dart';
import 'widgets/item_list.dart';
import 'package:glib/main/context.dart';
import 'search_page.dart';
import 'settings_page.dart';
import 'widgets/home_widget.dart';
import './configs.dart';

class _RectClipper extends CustomClipper<Rect> {

  Offset center;
  double value;

  _RectClipper(this.center, this.value);

  @override
  Rect getClip(Size size) {
    double length = (center - Offset(0, size.height)).distance;
    return Rect.fromCircle(
      center: center,
      radius: length * value
    );
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return !(oldClipper is _RectClipper) || (oldClipper as _RectClipper).value != value;
  }
}

class CollectionsPage extends HomeWidget {
  CollectionsPage() : super(key: GlobalKey(), title: "app_title");

  @override
  State<StatefulWidget> createState() {
    return _CollectionsPageState();
  }

  final GlobalKey searchKey = GlobalKey();

  @override
  List<Widget> buildActions(BuildContext context, void Function() changed) {
    Project project = ((key as GlobalKey).currentState as _CollectionsPageState)?.project;
    List<Widget> actions = [];

    String settings = project?.settingsPath;
    if (settings != null && settings.isNotEmpty) {
      actions.add(
        IconButton(
          icon: Icon(Icons.settings),
          onPressed: () async {
            Context ctx = project.createSettingsContext().control();
            await Navigator.of(context).push(MaterialPageRoute(builder: (_)=>SettingsPage(ctx)));
            ctx.release();
          }
        )
      );
    }

    String search = project?.search;
    if (search != null && search.isNotEmpty) {
      actions.add(
          IconButton(
              key: searchKey,
              icon: Icon(Icons.search),
              onPressed: () async {
                RenderObject object = searchKey.currentContext?.findRenderObject();
                var translation = object?.getTransformTo(null)?.getTranslation();
                var size = object?.semanticBounds?.size;
                Offset center;
                if (translation != null) {
                  double x = translation.x, y = translation.y;
                  if (size != null) {
                    x += size.width / 2;
                    y += size.height / 2;
                  }
                  center = Offset(x, y);
                } else {
                  center = Offset(0, 0);
                }

                Project project = ((key as GlobalKey)?.currentState as _CollectionsPageState)?.project;
                project?.control();
                Context ctx = project?.createSearchContext()?.control();
                await Navigator.of(context).push(PageRouteBuilder(
                    pageBuilder: (context, animation, secAnimation) {
                      return SearchPage(project, ctx);
                    },
                    transitionDuration: Duration(milliseconds: 300),
                    transitionsBuilder: (context, animation, secAnimation, child) {
                      return ClipOval(
                        clipper: _RectClipper(center, animation.value),
                        child: child,
                      );
                    }
                ));
                ctx?.release();
                project?.release();
              }
          )
      );
    }
    return actions;
  }
}

class _CollectionData {
  Context context;
  String title;

  _CollectionData(this.context, this.title);
}

class _CollectionsPageState extends State<CollectionsPage> {

  Project project;
  List<_CollectionData> contexts;

  Widget missBuild(BuildContext context) {
    return Container(
      child: Text("No Project"),
      alignment: Alignment.center,
    );
  }

  freeContexts() {
    for (int i = 0, t = contexts.length; i < t; ++i) {
      contexts[i].context.release();
    }
    contexts.clear();
  }

  Widget defaultBuild(BuildContext context) {
    List<Widget> tabs = [];
    List<Widget> bodies = [];
    for (int i = 0, t = contexts.length; i < t; ++i) {
      _CollectionData data = contexts[i];
      tabs.add(Container(
        child: Tab( text: data.title, ),
        height: 36,
      ));
      bodies.add(ItemListPage(project, data.context));
    }
    return DefaultTabController(
      length: contexts.length,
      child: Scaffold(
        appBar: tabs.length > 1 ? AppBar(
          toolbarHeight: 36,
          elevation: 0,
          centerTitle: true,
          title: TabBar(
            tabs: tabs,
            isScrollable: true,
            indicatorColor: Colors.white,
          ),
          backgroundColor: Theme.of(context).primaryColorDark,
          automaticallyImplyLeading: false,
        ) : null,
        body: TabBarView(
          children: bodies
        ),
      ),
    );
  }

  @override
  void initState() {
    project = Project.getMainProject();
    contexts = [];
    if (project != null) {
      project.control();
      Array arr = project.categories.control();
      for (int i = 0, t = arr.length; i < t; ++i) {
        GMap category = arr[i];
        String title = category["title"];
        if (title == null) title = "";
        var ctx = project.createIndexContext(category).control();
        contexts.add(_CollectionData(ctx, title));
      }
    }
    super.initState();
  }

  @override
  void dispose() {
    freeContexts();
    r(project);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return (project != null && project.isValidated) ? defaultBuild(context) : missBuild(context);
  }
}