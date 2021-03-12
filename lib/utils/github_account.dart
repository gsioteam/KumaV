

import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gitissues/gitissues.dart';
import 'package:glib/main/models.dart';
import 'package:aes_crypt/aes_crypt.dart';
import 'dart:convert';
import 'package:gitissues/loginview.dart';
import '../localizations/localizations.dart';

const String gitissues_key = "gitIssues";
const List<int> _secret = [
  0xf9, 0x1d, 0x35, 0x19, 0x52, 0x6d,
  0x3b, 0xd0, 0x02, 0x7d, 0x9c, 0x62,
  0xb7, 0x08, 0xb9, 0xb9, 0x93, 0x0d,
  0xb1, 0x70, 0xb2, 0x09, 0xbb, 0xc8,
  0xdb, 0xce, 0xd2, 0xe1, 0xa5, 0xed,
  0x5c, 0x80, 0x39, 0x63, 0xc2, 0x92,
  0x48, 0x3a, 0x31, 0x85, 0xb8, 0xb1,
  0x7d, 0x6e, 0x04, 0xbf, 0x37, 0x39
];

class AccountStorage extends DataStorage {
  @override
  String operator [](String key) {
    String value = KeyValue.get("$gitissues_key:$key");
    return value.isNotEmpty ? value : null;
  }

  @override
  void operator []=(String key, String value) {
    KeyValue.set("$gitissues_key:$key", value);
  }
}

class CryptClientData extends GitClientData {

  String id;
  List<int> _secret;

  CryptClientData(this.id, this._secret);

  @override
  String get secret {
    var crypt = AesCrypt();
    var key = Uint8List(32);
    key.setAll(0, utf8.encode("eroman"));
    var iv = Uint8List(16);
    iv.setAll(0, utf8.encode("eroaes"));
    crypt.aesSetKeys(key, iv);
    crypt.aesSetMode(AesMode.cbc);
    return utf8.decode(crypt.aesDecrypt(Uint8List.fromList(_secret))).substring(0, 40);
  }

}

class GithubAccount {
  static GithubAccount _instance;
  GitIssues _gitIssues;
  AccountStorage storage = AccountStorage();

  factory GithubAccount() {
    if (_instance == null) {
      _instance = GithubAccount._();
    }
    return _instance;
  }

  GitIssues get issues => _gitIssues;

  GithubAccount._() {
    _gitIssues = GitIssues(
      owner: 'gsioteam',
      repo: 'kumav_comments',
      client: CryptClientData("a7d8b9061314c1d4bfb3", _secret),
      storage: storage,
      redirect: Uri.parse("https://kumav.com/")
    );

    String value = storage["user_info"];
    if (value != null && value.isNotEmpty) {
      _userInfo = UserInfo(jsonDecode(value));
    }
  }

  GitIssue get(String url) => _gitIssues.get(url);

  UserInfo _userInfo;
  UserInfo get userInfo => _userInfo;

  Future<bool> login(BuildContext context) async {
    var kt = lc(context);
    bool result = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (context) {
      return Scaffold(
        appBar: AppBar(
          title: Text(kt("github_account")),
          backgroundColor: Theme.of(context).primaryColorDark,
        ),
        body: LoginView(_gitIssues, onComplete: () {
          Navigator.of(context).pop(true);
        },),
      );
    }));
    if (result == true) {
      _userInfo = await _gitIssues.fetchUser();
      if (_userInfo != null) {
        storage["user_info"] = _userInfo.toString();
        return true;
      }
    }
    return false;
  }

  void logout() {
    storage["user_info"] = "";
    _userInfo = null;
  }
}