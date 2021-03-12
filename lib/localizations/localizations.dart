

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'zh_hans.dart' as zhHans;
import 'zh_hant.dart' as zhHant;
import 'en.dart' as en;

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
  Future<KumaLocalizations> load(Locale locale) {
    switch (locale.languageCode) {
      case 'zh': {
        if (locale.scriptCode == 'Hans') {
          return get(zhHans.words);
        } else if (locale.scriptCode == 'Hant') {
          return get(zhHant.words);
        } else {
          return get(zhHant.words);
        }
        break;
      }
      default: {
        return get(en.words);
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
  KumaLocalizations loc = Localizations.of<KumaLocalizations>(ctx, KumaLocalizations);
  return (String key)=>loc.get(key);
}

extension KinokoLocalizationsWidget on Widget {
  String kt(BuildContext context, String key) {
    return Localizations.of<KumaLocalizations>(context, KumaLocalizations).get(key);
  }
}

extension KinokoLocalizationsState on State {
  String kt(String key) {
    return Localizations.of<KumaLocalizations>(this.context, KumaLocalizations).get(key);
  }
}