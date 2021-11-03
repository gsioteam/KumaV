
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:yaml/yaml.dart';

class LocaleChangedNotification extends Notification {
  Locale locale;
  LocaleChangedNotification(this.locale);
}

class NeoLocalizations {
  Map? words;
  Map? totalWords;

  NeoLocalizations(this.words, this.totalWords);

  String get(String key) {
    if (words?.containsKey(key) == true) return words![key];
    var txt = totalWords?[key];
    if (txt == null) txt = key;
    return txt;
  }

  static String load(BuildContext context, String key, {
    String? defaultResult,
    Map? arguments
  }) {
    var res = Localizations.of<NeoLocalizations>(context, NeoLocalizations)?.get(key) ?? defaultResult;
    if (res == null) {
      return key;
    }
    arguments?.forEach((key, value) {
      res = res!.replaceAll("{$key}", value.toString());
    });
    return res!;
  }
}

class NeoLocalizationsDelegate extends LocalizationsDelegate<NeoLocalizations> {
  static const Map<String, Locale> supports = const <String, Locale>{
    "en": const Locale.fromSubtags(languageCode: 'en'),
    "zh-hans": const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    "zh-hant": const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  };

  const NeoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return true;
  }

  @override
  Future<NeoLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'zh': {
        if (locale.scriptCode == 'Hans') {
          return _load('zh_hans');
        } else if (locale.scriptCode == 'Hant') {
          return _load('zh_hant');
        } else {
          return _load('zh_hant');
        }
      }
      default: {
        return _load('en');
      }
    }
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<NeoLocalizations> old) => false;

  Future<NeoLocalizations> _load(String name) async {
    var data = loadYaml(await rootBundle.loadString("localizations/$name.yaml"));
    return NeoLocalizations(data, data);
  }
}

typedef NewLocalizationsHandler = String Function(String, {String? defaultResult, Map? arguments});

NewLocalizationsHandler locFunc(BuildContext context) {
  return (String key, {String? defaultResult, Map? arguments}) =>
      NeoLocalizations.load(context, key, defaultResult: defaultResult, arguments: arguments);
}

extension NeoLocalizationsWidget on Widget {
  String loc(BuildContext context, String key, {
    String? defaultResult,
    Map? arguments
  }) {
    return NeoLocalizations.load(context, key,
        defaultResult: defaultResult,
        arguments: arguments);
  }
}

extension NeoLocalizationsState on State {
  String loc(String key, {
    String? defaultResult,
    Map? arguments
  }) {
    return NeoLocalizations.load(context, key,
        defaultResult: defaultResult,
        arguments: arguments);
  }
}