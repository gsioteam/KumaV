
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glib/main/models.dart';
import 'configs.dart';
import 'utils/github_account.dart';
import 'widgets/home_widget.dart';
import 'localizations/localizations.dart';
import 'widgets/settings_list.dart';

class MainSettingsPage extends HomeWidget {
  MainSettingsPage() : super(title: "settings");

  @override
  State<StatefulWidget> createState() => _MainSettingsPageState();
}

class _MainSettingsPageState extends State<MainSettingsPage> {

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
        SettingItem(
            SettingItemType.Header,
            kt("account")
        ),
        SettingItem(
          SettingItemType.Customer,
          "",
          data: accountWidget(),
        ),
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
      ],
    );
  }

}