import 'dart:io';
import 'package:flutter/foundation.dart' show kDebugMode;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glib/main/models.dart';
import 'package:glib/main/project.dart';
import 'package:kuma_player/proxy_server.dart';
import 'package:kumav/download_page.dart';
import 'package:kumav/favorites_page.dart';
import 'package:kumav/history_page.dart';
import 'package:kumav/utils/credits_dialog.dart';
import 'package:kumav/utils/video_notification.dart';
import 'main_settings_page.dart';
import 'utils/image_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'configs.dart';
import 'libraries_page.dart';

import 'package:path_provider/path_provider.dart' as platform;
import 'package:glib/glib.dart';
import 'package:glib/utils/git_repository.dart';
import 'utils/main_item_controller.dart';
import 'widgets/progress_dialog.dart';
import 'utils/progress_items.dart';
import 'localizations/localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'widgets/better_refresh_indicator.dart';
import 'widgets/home_widget.dart';
import 'collections_page.dart';
// import 'favorites_page.dart';
// import 'download_page.dart';
import 'package:xml_layout/types/colors.dart' as colors;
import 'package:xml_layout/types/icons.dart' as icons;
import 'layout/all.xml_layout.dart' as all;
import 'package:xml_layout/xml_layout.dart';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';
import 'package:glib/utils/browser.dart';

void main() {
  runApp(MainApp());
}

enum HomePages {
  Home,
  History,
  Favorites,
  DownloadList,
  ManageProjects,
  Settings
}

class MainApp extends StatefulWidget {

  MainApp({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => MainAppState();
}

class MainAppState extends State<MainApp> {
  Locale locale;

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return NotificationListener<LocaleChangedNotification>(
      child: MaterialApp(
        localizationsDelegates: [
          const KumaLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        locale: locale,
        supportedLocales: KumaLocalizationsDelegate.supports.values,
        title: 'KumaV',
        theme: themeData.copyWith(
          primaryColorDark: Colors.blueGrey,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: SplashScreen(),
      ),
      onNotification: (n) {
        setState(() {
          locale = n.locale;
        });
        return true;
      },
    );
  }
}

class _LifecycleEventHandler extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      Glib.destroy();
    }
  }
}

class SplashScreen extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return SplashScreenState();
  }
}

class SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Image(
          image: AssetImage("res/logo.png"),
          width: 128.0,
          height: 128.0,
        ),
      ),
    );
  }

  Future<void> setup(BuildContext context) async {
//    await Firebase.initializeApp();
//    if (kDebugMode) {
//      // Force disable Crashlytics collection while doing every day development.
//      // Temporarily toggle this to true if you want to test crash reporting in your app.
//      await FirebaseCrashlytics.instance
//          .setCrashlyticsCollectionEnabled(false);
//    } else {
//      // Handle Crashlytics enabled status when not in Debug,
//      // e.g. allow your users to opt-in to crash reporting.
//    }
    Directory dir = await platform.getApplicationSupportDirectory();
    share_cache["root_path"] = dir.path;

    await ProxyServer.instance.ready();

    await Glib.setup(dir.path);
    Locale locale = KumaLocalizationsDelegate.supports[KeyValue.get(language_key)];
    if (locale != null) {
      LocaleChangedNotification(locale).dispatch(context);
    }
    await showDisclaimer(context);
    await fetchEnv(context);
    WidgetsBinding.instance.addObserver(_LifecycleEventHandler());
    colors.register();
    icons.register();
    all.register();
    XmlLayout.register("CachedNetworkImageProvider", (node, key) {
      return CachedNetworkImageProvider(
          node.text,
          scale: node.s<double>("scale", 1)
      );
    });
    XmlLayout.register("FlatButton", (node, key) {
      return TextButton(
        key: key,
        onPressed: node.s<VoidCallback>("onPressed"),
        child: node.child<Widget>(),
      );
    });
    XmlLayout.register("BetterRefreshIndicator", (node, key) {
      return BetterRefreshIndicator(
        child: node.child<Widget>(),
        displacement: node.s<double>("displacement", 40),
        color: node.s<Color>("color"),
        backgroundColor: node.s<Color>("backgroundColor"),
        notificationPredicate: node.s<ScrollNotificationPredicate>("notificationPredicate", defaultScrollNotificationPredicate),
        semanticsLabel: node.s<String>("semanticsLabel"),
        semanticsValue: node.s<String>("semanticsValue"),
        strokeWidth: node.s<double>("strokeWidth", 2),
        controller: node.s<BetterRefreshIndicatorController>("controller"),
      );
    });
    XmlLayout.register("Padding", (node, key) {
      return Padding(
        key: key,
        padding: node.s<EdgeInsets>("padding"),
        child: node.child<Widget>(),
      );
    });
    XmlLayout.registerInline(EdgeInsets, "only", false, (node, method) {
      return EdgeInsets.only(
        left: double.tryParse(method[0]) ?? 0,
        top: double.tryParse(method[1]) ?? 0,
        right: double.tryParse(method[2]) ?? 0,
        bottom: double.tryParse(method[3]) ?? 0,
      );
    });
    XmlLayout.registerInline(EdgeInsets, "all", false, (node, method) {
      return EdgeInsets.all(double.tryParse(method[0]) ?? 0);
    });
    XmlLayout.registerInline(Color, "rgb", false, (node, method) {
      return Color.fromRGBO(int.tryParse(method[0]), int.tryParse(method[1]),
          int.tryParse(method[2]), 1);
    });
    XmlLayout.registerInline(BorderRadius, "horizontal", false, (node, method) {
      return BorderRadius.horizontal(
        left: node.v<Radius>(method[0], Radius.zero),
        right: node.v<Radius>(method[1], Radius.zero),
      );
    });
  }

  Future<void> fetchEnv(BuildContext context) async {
    env_repo = GitRepository.allocate("env", env_git_branch);
    if (!env_repo.isOpen()) {
      GitItem item = GitItem.clone(env_repo, env_git_url);
      item.cancelable = false;
      ProgressResult result = await showDialog<ProgressResult>(
          barrierDismissible: false,
          context: context,
          builder: (context) {
            return ProgressDialog(
              title: kt(""),
              item: item,
            );
          }
      );
      if (result != ProgressResult.Success) {
        throw Exception("WTF?!");
      }
    } else {
    }
  }

  Future<void> showDisclaimer(BuildContext context) async {
    String key = KeyValue.get(disclaimer_key);
    if (key != "true") {
      bool result = await showCreditsDialog(context);
      print("result is $result");
      if (result == true) {
        KeyValue.set(disclaimer_key, "true");
      } else {
        SystemNavigator.pop();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    Future<void> future = setup(context);
    future.then((value) {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(
          settings: RouteSettings(name: home_page_name),
          builder: (BuildContext context) {
            GlobalKey key = GlobalKey();
            Browser.globalKey = key;
            return HomePage(key: key);
          }
      ), (route) => route.isCurrent);
    });
  }
}

class HomeDrawer extends StatefulWidget {
  final _HomePageState homeState;

  HomeDrawer(this.homeState);

  @override
  State<StatefulWidget> createState() {
    return _HomeDrawerState();
  }
}

class OvalClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width, size.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return false;
  }

}

class _HomeDrawerState extends State<HomeDrawer> with SingleTickerProviderStateMixin {

  AnimationController animationController;
  bool isFetch = false;
  bool isCheckout = false;
  bool isDispose = false;

  void startFetch() {
    if (isFetch) return;
    isFetch = true;
    animationController.repeat();
    GitRepository repo = env_repo;
    GitAction action = repo.fetch();
    action.control();
    action.setOnComplete(() {
      action.release();
      if (isDispose) return;
      this.setState(() {
        if (this.onRefresh != null) this.onRefresh();
        animationController.stop();
        animationController.reset();
        isFetch = false;
      });
      if (action.hasError()) {
        Fluttertoast.showToast(
          msg: action.getError(),
          toastLength: Toast.LENGTH_SHORT,
        );
      }
    });
  }

  void startCheckout() {
    if (isCheckout) return;
    isCheckout = true;
    GitRepository repo = env_repo;
    GitAction action = repo.checkout();
    action.control();
    action.setOnComplete(() {
      action.release();
      if (isDispose) return;
      this.setState(() {
        if (this.onRefresh != null) this.onRefresh();
        isCheckout = false;
      });
      if (action.hasError()) {
        String err = action.getError();
        Fluttertoast.showToast(
          msg: err,
          toastLength: Toast.LENGTH_SHORT,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    widget.homeState.onRefresh = onRefresh;
    widget.homeState.onFetch = startFetch;
    animationController = AnimationController(
        vsync: this,
        duration: Duration(seconds: 1),
    );
  }

  @override
  void didUpdateWidget(HomeDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.homeState.onRefresh = null;
    oldWidget.homeState.onFetch = null;
    widget.homeState.onRefresh = onRefresh;
    widget.homeState.onFetch = startFetch;
  }

  @override
  void dispose() {
    widget.homeState.onRefresh = null;
    widget.homeState.onFetch = null;
    animationController.dispose();
    isDispose = true;
    super.dispose();
  }

  ImageProvider getIcon(Project project) {
    String icon = project?.icon;
    if (icon != null && icon.isNotEmpty) {
      return makeImageProvider(icon);
    }
    if (project.isValidated) {
      String iconpath = project.fullpath + "/icon.png";
      File icon = new File(iconpath);
      if (icon.existsSync()) {
        return FileImage(icon);
      }
    }
    return CachedNetworkImageProvider("http://tinygraphs.com/squares/${generateMd5(project.url)}?theme=bythepool&numcolors=3&size=180&fmt=jpg");
  }

  List<Widget> buildList(Project project) {
    var lv = env_repo.localID(), hv = env_repo.highID();
//    GitLibrary library = GitLibrary.findLibrary(env_repo);

    return [
      Padding(
        padding: EdgeInsets.only(top: 5, bottom: 5),
        child: Row(
          children: [
            ClipOval(
              child: Container(
                color: Theme.of(context).primaryColorLight,
                child: Image(
                  image: getIcon(project),
                  fit: BoxFit.contain,
                  width: 36,
                  height: 36,
                ),
              ),
              clipper: OvalClipper(),
            ),
            Padding(padding: EdgeInsets.only(left: 8)),
            Text(project.name,
              style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.white)
            )
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.only(top: 10, bottom: 5),
        child: Text(
          hv == lv ? "${kt("framework")}.$hv" : "${kt("framework")}.$hv ($lv)",
          style: Theme.of(context).textTheme.caption.copyWith(color: Colors.white),
        ),
      ),
      Row(
        children: <Widget>[
          IconButton(
              icon: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColorLight,
                  child: AnimatedBuilder(
                      animation: animationController,
                      child: Icon(Icons.sync, color: Theme.of(context).primaryColorDark,),
                      builder: (BuildContext context, Widget _widget) {
                        return Transform.rotate(
                          angle: animationController.value * -6.3,
                          child: _widget,
                        );
                      }
                  )
              ),
              onPressed: startFetch
          ),
          (lv == hv ? Container(): IconButton(
              icon: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColorLight,
                child: Icon(Icons.get_app, color: Theme.of(context).primaryColorDark,),
              ),
              onPressed: isCheckout ? null:startCheckout
          ))
        ],
      )
    ];
  }

  List<Widget> getChildren() {
    var project = Project.getMainProject();
    if (env_repo == null || project == null) {
      return [
        Padding(
          padding: EdgeInsets.only(top: 5, bottom: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipOval(
                child: Container(
                  color: Theme.of(context).primaryColorLight,
                  child: Image(
                    image: CachedNetworkImageProvider("http://tinygraphs.com/squares/unkown?theme=bythepool&numcolors=3&size=180&fmt=jpg"),
                    fit: BoxFit.contain,
                    width: 36,
                    height: 36,
                  ),
                ),
                clipper: OvalClipper(),
              ),
              Padding(padding: EdgeInsets.only(left: 8)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(kt("no_main_project"),
                      style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.white)
                  ),
                  Padding(padding: EdgeInsets.only(top: 5)),
                  Text(kt("select_main_project_first"),
                    style: Theme.of(context).textTheme.caption.copyWith(color: Colors.white),
                  )
                ],
              )
            ],
          ),
        )
      ];
    } else {
      return buildList(project);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColorDark,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: getChildren(),
        ),
      ),
    );
  }

  void onRefresh() {
    print("onRefresh");
    this.setState(() { });
  }


}

class NavigationController {
  AppBarData appBarData;

  NavigationController(this.appBarData);

  String get title => appBarData == null ? "" : appBarData.title;

  List<Widget> buildActions(BuildContext context, void Function() reload) {
    return appBarData == null ? [] : appBarData.buildActions(context, reload);
  }
}

class NavigationBar extends StatefulWidget implements PreferredSizeWidget {

  final NavigationController controller;

  NavigationBar(AppBarData appBarData) : controller = NavigationController(appBarData);

  @override
  State<StatefulWidget> createState() => _NavigationBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class _NavigationBarState extends State<NavigationBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(kt(widget.controller.title)),
      elevation: 0,
      actions: widget.controller.buildActions(context, onReload),
      backgroundColor: Theme.of(context).primaryColorDark,
      brightness: Brightness.dark,
    );
  }

  void onReload() {
    setState(() {});
  }

}

class HomePage extends HomeWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class CollectionPage extends HomeWidget {
  @override
  State<StatefulWidget> createState() => CollectionPageState();
}

class CollectionPageState extends State<CollectionPage> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class _HomePageState extends State<HomePage> {
  HomePages selected = HomePages.Home;
  HomeDrawer drawer;
  void Function() onRefresh;
  void Function() onFetch;

  bool hasMainProject() {
    return Project.getMainProject() != null;
  }

  HomeWidget _getBody(BuildContext context) {
    switch (selected) {
      case HomePages.Home: {
        return CollectionsPage();
      }
      case HomePages.History: {
        return HistoryPage();
      }
      case HomePages.Favorites: {
        return FavoritesPage();
      }
      case HomePages.DownloadList: {
        return DownloadPage();
      }
      case HomePages.ManageProjects: {
        return LibrariesPage();
      }
      case HomePages.Settings: {
        return MainSettingsPage();
      }
    }
    return null;
  }

  void Function() _onTap(HomePages idx) {
    return (){
      if (idx == HomePages.Home && !hasMainProject()) {
        Fluttertoast.showToast(
          msg: kt("select_main_project_first"),
          toastLength: Toast.LENGTH_LONG
        );
        idx = HomePages.ManageProjects;
      }
      if (selected != idx) {
        setState(() {
          selected = idx;
        });

        Navigator.of(context).popUntil(ModalRoute.withName(home_page_name));
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    HomeWidget body = _getBody(context);

    return WillPopScope(
      child: NotificationListener<VideoNotification>(
        child: Scaffold(
          drawer: Drawer(
            child: ListView(
              physics: ClampingScrollPhysics(),
              children: <Widget>[
                HomeDrawer(this),
                ListTile(
                  selected: selected == HomePages.Home,
                  leading: Icon(Icons.collections_bookmark, color: hasMainProject() ? null : Colors.black45,),
                  title: Text(kt("video_home"), style: hasMainProject() ? null : TextStyle(color: Colors.black45),),
                  onTap: _onTap(HomePages.Home),
                ),
                ListTile(
                  selected: selected == HomePages.History,
                  leading: Icon(Icons.history),
                  title: Text(kt("history")),
                  onTap: _onTap(HomePages.History),
                ),
                ListTile(
                  selected: selected == HomePages.Favorites,
                  leading: Icon(Icons.favorite),
                  title: Text(kt("favorites")),
                  onTap: _onTap(HomePages.Favorites),
                ),
                ListTile(
                  selected: selected == HomePages.DownloadList,
                  leading: Icon(Icons.file_download),
                  title: Text(kt("download_list")),
                  onTap: _onTap(HomePages.DownloadList),
                ),
                Divider(),
                ListTile(
                  selected: selected == HomePages.ManageProjects,
                  leading: Icon(Icons.account_balance),
                  title: Text(kt("manage_projects")),
                  onTap: _onTap(HomePages.ManageProjects),
                ),
                Divider(),
                ListTile(
                  selected: selected == HomePages.Settings,
                  leading: Icon(Icons.settings),
                  title: Text(kt("settings")),
                  onTap: _onTap(HomePages.Settings),
                ),
              ],
            ),
          ),
          appBar: NavigationBar(body.appBarData),
          body: NotificationListener<LibraryNotification>(
            child: body,
            onNotification: (noti) {
              setState(() { });
              return true;
            },
          ),
        ),
        onNotification: (notification) {
          mainItemController.play(context, notification);
          return true;
        },
      ),
      onWillPop: () {
        if (mainItemController == null) return SynchronousFuture<bool>(true);
        else return mainItemController.willPop();
      }
    );
  }

  @override
  void initState() {
    super.initState();
    selected = hasMainProject() ? HomePages.Home : HomePages.ManageProjects;
  }
}
