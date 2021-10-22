
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kumav/pages/video.dart';
import 'package:kumav/utils/configs.dart';
import 'package:kumav/widgets/video_sheet.dart';

import 'collections.dart';
import 'downloads.dart';
import 'favorites.dart';
import 'history.dart';
import 'settings.dart';
import '../localizations/localizations.dart';

enum HomePages {
  Favorites,
  DownloadList,
  Home,
  History,
  Settings
}

class Index extends StatefulWidget {

  Index({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _IndexState();
}

const String _initPage = 'init';
const _layerSize = 48;

class _IndexState extends State<Index> {
  HomePages _oldIndex = HomePages.Home;
  HomePages selected = HomePages.Home;
  void Function()? onRefresh;
  void Function()? onFetch;
  GlobalKey<VideoSheetState> _videoKey = GlobalKey();

  bool hasMainProject() {
    // return Project.getMainProject() != null;
    return false;
  }

  Widget _getBody(BuildContext context) {
    switch (selected) {
      case HomePages.Home: {
        return Collections(
          key: ValueKey(HomePages.Home),
          plugin: Configs.instance.currentPlugin,
        );
      }
      case HomePages.History: {
        return History(key: ValueKey(HomePages.History),);
      }
      case HomePages.Favorites: {
        return Favorites(key: ValueKey(HomePages.Favorites));
      }
      case HomePages.DownloadList: {
        return Downloads(key: ValueKey(HomePages.DownloadList));
      }
      case HomePages.Settings: {
        return Settings(key: ValueKey(HomePages.Settings),);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return WillPopScope(
        child: Stack(
          children: [
            Positioned.fill(
              child: Navigator(
                initialRoute: _initPage,
                onGenerateRoute: (settings) {
                  if (settings.name == _initPage) {
                    return MaterialPageRoute(builder: (context) {
                      return Scaffold(
                        body: NotificationListener<OpenVideoNotification>(
                          child: _buildBody(),
                          onNotification: (notification) {
                            _videoKey.currentState?.open();
                            return true;
                          },
                        ),
                        bottomNavigationBar: BottomNavigationBar(
                          items: [
                            BottomNavigationBarItem(
                              icon: Icon(Icons.favorite),
                              label: kt("favorites"),
                            ),
                            BottomNavigationBarItem(
                              icon: Icon(Icons.file_download),
                              label: kt("download_list"),
                            ),
                            BottomNavigationBarItem(
                              icon: Icon(Icons.home),
                              label: kt("video_home"),
                            ),
                            BottomNavigationBarItem(
                              icon: Icon(Icons.history),
                              label: kt("history"),
                            ),
                            BottomNavigationBarItem(
                              icon: Icon(Icons.settings),
                              label: kt("settings"),
                            ),
                          ],
                          onTap: (index) {
                            setState(() {
                              _oldIndex = selected;
                              selected = HomePages.values[index];
                            });
                          },
                          currentIndex: selected.index,
                        ),
                      );
                    });
                  }
                },
              ),
            ),
            VideoSheet(
                key: _videoKey,
                maxHeight: size.height,
                builder: (context, physics, controller) {
                  return Video(
                    physics: physics,
                    controller: controller,
                  );
                }
            ),
          ],
        ),
        onWillPop: () async {
          return true;
        }
    );

  }

  @override
  void initState() {
    super.initState();
    _oldIndex = selected = HomePages.Home;
  }

  Widget _buildBody() {
    var body = _getBody(context);

    return LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child: body,
            transitionBuilder: (child, animation) {
              int nav = 1;
              if (child != body) nav = -1;
              if (selected.index < _oldIndex.index) nav *= -1;
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(constraints.maxWidth * (1-animation.value) * nav, 0),
                    child: child,
                  );
                },
                child: child,
              );
            },
          );
        }
    );
  }
}