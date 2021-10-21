
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kumav/utils/assets_filesystem.dart';

import 'localizations/localizations.dart';
// import 'favorites_page.dart';
// import 'download_page.dart';
import 'package:xml_layout/types/colors.dart' as colors;
import 'package:xml_layout/types/icons.dart' as icons;
import 'layout/all.xml_layout.dart' as all;
import 'package:xml_layout/xml_layout.dart';

import 'pages/index.dart';
import 'utils/configs.dart';
import 'utils/plugin.dart';

bool _isTest = true;

void main() {
  runApp(MainApp());
}

class MainApp extends StatefulWidget {

  MainApp({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => MainAppState();
}

class MainAppState extends State<MainApp> {
  Locale? locale;

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
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.black54,
            type: BottomNavigationBarType.fixed,
          ),
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

  @override
  void initState() {
    super.initState();

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

    // var repo = await fetchEnv(context);
    // await Configs.instance.setup(context, repo);
    // await ProxyServer.instance.ready();

    // await Glib.setup(Configs.instance.root.path);
    // Locale? locale = KumaLocalizationsDelegate.supports[KeyValue.get(language_key)];
    // if (locale != null) {
    //   LocaleChangedNotification(locale).dispatch(context);
    // }
    await showDisclaimer(context);
    await Plugin.setup();
    await Configs.instance.setup(context);

    if (_isTest) {
      Plugin plugin = Plugin.test(context);
      await plugin.ready;
      Configs.instance.currentPlugin = plugin;
    }
  }

  // Future<GitRepository> fetchEnv(BuildContext context) async {
  //   var repo = GitRepository.allocate("env", env_git_branch);
  //   if (!repo.isOpen()) {
  //     GitItem item = GitItem.clone(repo, env_git_url);
  //     item.cancelable = false;
  //     ProgressResult? result = await showDialog<ProgressResult>(
  //         barrierDismissible: false,
  //         context: context,
  //         builder: (context) {
  //           return ProgressDialog(
  //             title: kt(""),
  //             item: item,
  //           );
  //         }
  //     );
  //     if (result != ProgressResult.Success) {
  //       throw Exception("WTF?!");
  //     }
  //   }
  //   return repo;
  // }

  Future<void> showDisclaimer(BuildContext context) async {
    // String key = KeyValue.get(disclaimer_key);
    // if (key != "true") {
    //   bool? result = await showCreditsDialog(context);
    //   print("result is $result");
    //   if (result == true) {
    //     KeyValue.set(disclaimer_key, "true");
    //   } else {
    //     SystemNavigator.pop();
    //   }
    // }
  }

  @override
  void initState() {
    super.initState();
    Future<void> future = setup(context);
    future.then((value) {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(
          builder: (BuildContext context) {
            GlobalKey key = GlobalKey();
            // Browser.globalKey = key;
            return Index(key: key);
          }
      ), (route) => route.isCurrent);
    });
  }
}

