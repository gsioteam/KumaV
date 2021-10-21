

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:yaml/yaml.dart';

class LocaleChangedNotification extends Notification {
  Locale locale;
  LocaleChangedNotification(this.locale);
}

class KumaLocalizations {
  Map words;
  Map total_words;
  KumaLocalizations(this.words, this.total_words);

  String get(String key) {
    if (words.containsKey(key)) return words[key];
    var txt = total_words[key];
    if (txt == null) txt = key;
    return txt;
  }
}

class KumaLocalizationsDelegate extends LocalizationsDelegate<KumaLocalizations> {
  static const Map<String, Locale> supports = const <String, Locale>{
    "en": const Locale.fromSubtags(languageCode: 'en'),
    "zh-hant": const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    "zh-hans": const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans')
  };

  const KumaLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return true;
  }

  @override
  Future<KumaLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'zh': {
        if (locale.scriptCode == 'Hans') {
          return get(loadYaml(await rootBundle.loadString('res/languages/zh_hans.yaml')));
        } else if (locale.scriptCode == 'Hant') {
          return get(loadYaml(await rootBundle.loadString('res/languages/zh_hant.yaml')));
        } else {
          return get(loadYaml(await rootBundle.loadString('res/languages/zh_hant.yaml')));
        }
        break;
      }
      default: {
        return get(loadYaml(await rootBundle.loadString('res/languages/en.yaml')));
      }
    }
  }

  Future<KumaLocalizations> get(Map data) {
    return SynchronousFuture<KumaLocalizations>(KumaLocalizations(data, data));
  }

  @override
  bool shouldReload(LocalizationsDelegate old) => false;
}

String Function(String) lc(BuildContext ctx) {
  KumaLocalizations? loc = Localizations.of<KumaLocalizations>(ctx, KumaLocalizations);
  return (String key)=>loc?.get(key) ?? key;
}

extension KinokoLocalizationsWidget on Widget {
  String kt(BuildContext context, String key) {
    return Localizations.of<KumaLocalizations>(context, KumaLocalizations)?.get(key) ?? key;
  }
}

extension KinokoLocalizationsState on State {
  String kt(String key) {
    return Localizations.of<KumaLocalizations>(this.context, KumaLocalizations)?.get(key) ?? key;
  }
}