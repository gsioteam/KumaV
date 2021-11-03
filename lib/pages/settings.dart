
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kumav/utils/manager.dart';
import 'package:kumav/utils/video_downloader/cache_manager.dart';
import 'package:kumav/utils/video_downloader/proxy_server.dart';
import 'package:kumav/widgets/credits_dialog.dart';
import 'package:get_version/get_version.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:kumav/widgets/progress_dialog.dart';
import 'package:sembast/sembast.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localizations/localizations.dart';

class ListHeader extends StatelessWidget {

  final Widget? child;

  ListHeader({
    Key? key,
    this.child
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: 18,
      ),
      child: child,
    );
  }
}

class SettingCell extends StatelessWidget {

  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  SettingCell({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return LayoutBuilder(
        builder: (context, constraints) {
          Widget? widget;
          if (subtitle != null || trailing != null) {
            List<Widget> children = [];
            if (subtitle != null) {
              children.add(Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: DefaultTextStyle(
                    style: TextStyle(
                        color: theme.disabledColor
                    ),
                    child: subtitle!,
                  ),
                ),
              ));
            }
            if (trailing != null) {
              children.add(Padding(
                padding: EdgeInsets.only(left: 10),
                child: trailing,
              ));
            }
            widget = Container(
              width: constraints.maxWidth / 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: children,
              ),
            );
          }

          return ListTile(
            tileColor: theme.colorScheme.surface,
            title: title,
            trailing: widget,
            onTap: onTap,
          );
        }
    );
  }
}

class MainSettingsList extends StatelessWidget {

  final Widget? title;
  final List<Widget> children;

  MainSettingsList({
    Key? key,
    this.title,
    this.children = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: title,
      ),
      body: ListView(
        children: [
          ListHeader(),
          ...children,
          ListHeader(),
        ],
      ),
    );
  }
}

StoreRef _settingsStore = StoreRef("settings");
const String _languageKey = "language";
const String _projectLink = 'https://github.com/gsioteam/KumaV';

class Settings extends StatefulWidget {

  Settings({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SettingsState();
}

const Map<String, String> _languageMap = {
  'en': 'English',
  'zh-hant': '中文(繁體)',
  'zh-hans': '中文(简体)',
};

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    Locale locale = Localizations.localeOf(context);
    String localeValue = "en";
    NeoLocalizationsDelegate.supports.forEach((key, value) {
      if (locale == value) {
        localeValue = key;
      }
    });

    return MainSettingsList(
      title: Text(loc('settings')),
      children: [
        SettingCell(
          title: Text(loc('language')),
          subtitle: Text(_languageMap[localeValue]!),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () async {
            List<PickerItem<String>> items = [];
            NeoLocalizationsDelegate.supports.forEach((key, value) {
              items.add(PickerItem<String>(
                text: Text(_languageMap[key]!),
                value: key,
              ));
            });
            items.sort((item1, item2) {
              return item1.value!.compareTo(item2.value!);
            });
            int index = 0;
            for (int i = 0, t = items.length; i < t; ++i) {
              if (localeValue == items[i].value) {
                index = i;
                break;
              }
            }

            String? result;
            await Picker(
                adapter: PickerDataAdapter<String>(
                  data: items,
                ),
                selecteds: [index],
                onConfirm: (picker, list) {
                  result = items[list[0]].value;
                }
            ).showModal(context);
            if (result != null) {
              await _settingsStore.record(_languageKey).put(Manager.instance.database, result);
              LocaleChangedNotification(NeoLocalizationsDelegate.supports[result]!).dispatch(context);
            }
          },
        ),
        SettingCell(
          title: Text(loc('cache_manager')),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) =>
                CacheManager()));
          },
        ),
        ListHeader(),
        SettingCell(
          title: Text(loc('disclaimer')),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () {
            showCreditsDialog(context);
          },
        ),
        SettingCell(
          title: Text(loc('about')),
          trailing: Icon(Icons.keyboard_arrow_right),
          onTap: () async {
            var theme = Theme.of(context);
            showAboutDialog(
                context: context,
                applicationName: await GetVersion.appName,
                applicationVersion: await GetVersion.projectVersion,
                applicationIcon: Image.asset(
                  'res/logo.png',
                  width: 32,
                  height: 32,
                ),
                applicationLegalese: "© gsioteam 2021",
                children: [
                  Padding(padding: EdgeInsets.only(top: 10)),
                  Text.rich(
                    TextSpan(
                        children: [
                          TextSpan(
                            text: loc('about_description'),
                          ),
                          TextSpan(
                              text: _projectLink,
                              recognizer: TapGestureRecognizer()
                                ..onTap = () async {
                                  await launch(_projectLink);
                                },
                              style: TextStyle(
                                color: theme.primaryColor,
                                decoration: TextDecoration.underline,
                              )
                          ),
                          TextSpan(
                            text: loc('about_description_end'),
                          )
                        ]
                    ),
                    textAlign: TextAlign.center,
                  ),
                ]
            );
          },
        ),
      ],
    );
  }
}

class ClearProgressItem extends ProgressItem {

  Future<void> Function() action;


  ClearProgressItem({
    required String text,
    required this.action
  }) {
    cancelable = false;
    this.defaultText = text;
    run();
  }

  void run() async {
    await action();
    complete();
  }

  @override
  void cancel() {
  }

}

class CacheManager extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => CacheManagerState();

}

class CacheManagerState extends State<CacheManager> {

  SizeResult? size;
  bool _disposed = false;

  String _sizeString(int size) {
    String unit = "KB";
    double num = size / 1024;
    if (num > 1024) {
      unit = "MB";
      num /= 1024;
    }
    return "${num.toStringAsFixed(2)} $unit";
  }

  @override
  Widget build(BuildContext context) {
    return MainSettingsList(
      title: Text(loc('cache_manager')),
      children: [
        SettingCell(
          title: Text(loc("cached_size")),
          subtitle: Text(size == null ? "..." : _sizeString(size!.other),),
          trailing: size == null ? null : Icon(Icons.clear),
          onTap: size == null ? null : () async {
            bool? result = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(loc("confirm")),
                    content: Text(loc("clear_cache")),
                    actions: [
                      TextButton(
                        child: Text(loc("no")),
                        onPressed: ()=> Navigator.of(context).pop(false),
                      ),
                      TextButton(
                        child: Text(loc("yes")),
                        onPressed:()=> Navigator.of(context).pop(true),
                      ),
                    ],
                  );
                }
            );
            if (result == true) {
              await showDialog(context: context, builder: (context) {
                return ProgressDialog(
                  title: loc('loading'),
                  item: ClearProgressItem(
                      text: '${loc('clear')}...',
                      action: () async {
                        Set<String> cached = Set();
                        for (var item in Manager.instance.downloads.items) {
                          String saveKey = ProxyServer.instance.keyFromURL(item.videoUrl);
                          cached.add(saveKey);
                        }
                        await ProxyServer.instance.cacheManager.clearWithout(cached);
                        await fetchSize();
                      }
                  ),
                );
              });
            }
          },
        ),
        SettingCell(
          title: Text(loc("download_size")),
          subtitle: Text(size == null ? "..." : _sizeString(size!.cached)),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    fetchSize();
  }

  @override
  void dispose() {
    super.dispose();

    _disposed = true;
  }

  Future<void> fetchSize() async {
    Set<String> cached = Set();
    for (var item in Manager.instance.downloads.items) {
      String saveKey = ProxyServer.instance.keyFromURL(item.videoUrl);
      cached.add(saveKey);
    }
    await ProxyServer.instance.ready();
    SizeResult size = await ProxyServer.instance.cacheManager.calculateSize(cached);
    if (!_disposed) {
      setState(() {
        this.size = size;
      });
    }
  }
}