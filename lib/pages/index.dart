
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kumav/pages/video.dart';
import 'package:kumav/utils/configs.dart';
import 'package:kumav/utils/manager.dart';
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
  GlobalKey<NavigatorState> _navigatorKey = GlobalKey();

  bool hasMainProject() {
    // return Project.getMainProject() != null;
    return false;
  }

  Widget _getBody(BuildContext context) {
    switch (selected) {
      case HomePages.Home: {
        return Collections(
          key: ValueKey(HomePages.Home),
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
        child: NotificationListener<OpenVideoNotification>(
          onNotification: (notification) {
            _videoKey.currentState?.play(VideoInfo(
              key: notification.key,
              data: notification.data,
              plugin: notification.plugin,
              resolution: notification.resolution,
            ));
            return true;
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: Navigator(
                  key: _navigatorKey,
                  initialRoute: _initPage,
                  onGenerateRoute: (settings) {
                    if (settings.name == _initPage) {
                      return MaterialPageRoute(builder: (context) {
                        return Scaffold(
                          body:_buildBody(),
                          bottomNavigationBar: BottomNavigationBar(
                            items: [
                              BottomNavigationBarItem(
                                icon: Icon(Icons.favorite),
                                label: loc("favorites"),
                              ),
                              BottomNavigationBarItem(
                                icon: Icon(Icons.file_download),
                                label: loc("download_list"),
                              ),
                              BottomNavigationBarItem(
                                icon: Icon(Icons.home),
                                label: loc("video_home"),
                              ),
                              BottomNavigationBarItem(
                                icon: Icon(Icons.history),
                                label: loc("history"),
                              ),
                              BottomNavigationBarItem(
                                icon: Icon(Icons.settings),
                                label: loc("settings"),
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
        ),
        onWillPop: () async {
          switch (_videoKey.currentState?.status) {
            case VideoSheetStatus.Fullscreen: {
              _videoKey.currentState?.minify();
              return false;
            }
            default: {
              if (_navigatorKey.currentState?.canPop() == true) {
                _navigatorKey.currentState?.pop();
                return false;
              }
            }
          }
          if (_videoKey.currentState?.status == VideoSheetStatus.Mini) {
            _videoKey.currentState?.close();
            return false;
          }
          return true;
        }
    );

  }

  @override
  void initState() {
    super.initState();
    if (Manager.instance.favorites.items.length == 0) {
      selected = HomePages.Home;
    } else {
      selected = HomePages.Favorites;
    }
    _oldIndex = selected;
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