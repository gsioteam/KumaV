
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glib/main/models.dart';
import 'package:kuma_player/cache_manager.dart';
import 'package:kuma_player/proxy_server.dart';
import 'configs.dart';
import 'utils/credits_dialog.dart';
import 'utils/download_manager.dart';
import 'utils/github_account.dart';
import 'widgets/home_widget.dart';
import 'localizations/localizations.dart';
import 'widgets/progress_dialog.dart';
import 'widgets/settings_list.dart';
import 'utils/download_manager.dart';

class ClearProgressItem extends ProgressItem {

  Future<void> Function() action;

  ClearProgressItem({
    this.action
  }) {
    cancelable = false;
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

class Settings {

  static int get downloadLimit {
    String count = KeyValue.get(download_limit_key);
    return count == null ? 3 : (int.tryParse(count) ?? 3);
  }

  static set downloadLimit(int count) {
    KeyValue.set(download_limit_key, count.toString());
  }

  static bool get floatingPlayer {
    String str = KeyValue.get(floating_player_key) ?? '';
    return str.isEmpty ? true : (str == "true");
  }

  static set floatingPlayer(bool enable) {
    KeyValue.set(floating_player_key, enable.toString());
  }
}

class MainSettingsPage extends HomeWidget {
  MainSettingsPage() : super(title: "settings");

  @override
  State<StatefulWidget> createState() => _MainSettingsPageState();
}

class _MainSettingsPageState extends State<MainSettingsPage> {

  SizeResult size;

  String _sizeString(int size) {
    String unit = "KB";
    double num = size / 1024;
    if (num > 1024) {
      unit = "MB";
      num /= 1024;
    }
    return "${num.toStringAsFixed(2)} $unit";
  }

  Widget accountWidget() {
    var userInfo = GithubAccount().userInfo;
    if (userInfo == null) {
      return ListTile(
        leading: CircleAvatar(
          child: Icon(
            Icons.account_circle_outlined,
            size: 36,
          ),
        ),
        title: Text(kt("no_login")),
        onTap: () async {
          if (await GithubAccount().login(context)) {
            setState(() { });
          }
        },
      );
    } else {
      return ListTile(
        leading: CircleAvatar(
          child: Image(
            image: CachedNetworkImageProvider(
              userInfo.avatar ?? ""
            ),
          ),
        ),
        title: Text(userInfo.login ?? ""),
        onTap: () {
          setState(() {
            GithubAccount().logout();
          });
        },
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    Locale locale = Localizations.localeOf(context);
    String localeValue = "en";
    KumaLocalizationsDelegate.supports.forEach((key, value) {
      if (locale == value) {
        localeValue = key;
      }
    });
    return SettingsList(
      items: [
        // SettingItem(
        //     SettingItemType.Header,
        //     kt("account")
        // ),
        // SettingItem(
        //   SettingItemType.Customer,
        //   "",
        //   data: accountWidget(),
        // ),
        SettingItem(
            SettingItemType.Header, 
            kt("general")
        ),
        SettingItem(
          SettingItemType.Options,
          kt("language"),
          value: localeValue,
          data: [
            OptionItem("English", "en"),
            OptionItem("中文(繁體)", "zh-hant"),
            OptionItem("中文(简体)", "zh-hans"),
          ],
          onChange: (value) {
            KeyValue.set(language_key, value);
            LocaleChangedNotification(KumaLocalizationsDelegate.supports[value]).dispatch(context);
          }
        ),
        SettingItem(
            SettingItemType.Button,
            kt("cached_size"),
            value: size == null ? "..." : _sizeString(size.other),
            data: () async {
              bool result = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(kt("confirm")),
                      content: Text(kt("clear_cache")),
                      actions: [
                        TextButton(
                          child: Text(kt("no")),
                          onPressed: ()=> Navigator.of(context).pop(false),
                        ),
                        TextButton(
                          child: Text(kt("yes")),
                          onPressed:()=> Navigator.of(context).pop(true),
                        ),
                      ],
                    );
                  }
              );
              if (result == true) {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProgressDialog(title: kt('clear'), item: ClearProgressItem(
                    action: () async {
                      Set<String> cached = Set();
                      for (var item in DownloadManager().items) {
                        cached.add(item.downloader.proxyItem.key);
                      }
                      await ProxyServer.instance.cacheManager.clearWithout(cached);
                      await fetchSize();
                    }
                ),)));
              }
            }
        ),
        SettingItem(
            SettingItemType.Label,
            kt("download_size"),
            value: size == null ? "..." : _sizeString(size.cached)
        ),
        SettingItem(
          SettingItemType.Header,
          kt("video"),
        ),
        SettingItem(
          SettingItemType.Options,
          kt("max_download_limit"),
          value: Settings.downloadLimit,
          data: [
            OptionItem("1", 1),
            OptionItem("2", 2),
            OptionItem("3", 3),
            OptionItem("4", 4),
            OptionItem("5", 5),
          ],
          onChange: (value) {
            setState(() {
              DownloadManager().queueLimit = value;
              Settings.downloadLimit = value;
            });
          }
        ),
        SettingItem(
          SettingItemType.Switch,
          kt("floating_player"),
          value: Settings.floatingPlayer,
          onChange: (value) {
            setState(() {
              Settings.floatingPlayer = value;
            });
          }
        ),
        SettingItem(
          SettingItemType.Header,
          kt("others"),
        ),
        SettingItem(
          SettingItemType.Button,
          kt("disclaimer"),
          value: "",
          data: () {
            showCreditsDialog(context);
          }
        )
      ],
    );
  }
  
  @override
  void initState() {
    super.initState();

    fetchSize();
  }

  Future<void> fetchSize() async {
    Set<String> cached = Set();
    for (var item in DownloadManager().items) {
      cached.add(item.downloader.proxyItem.key);
    }
    await ProxyServer.instance.ready();
    SizeResult size = await ProxyServer.instance.cacheManager.calculateSize(cached);
    setState(() {
      this.size = size;
    });
  }
}