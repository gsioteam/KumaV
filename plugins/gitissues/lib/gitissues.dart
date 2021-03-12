library gitissues;

import 'package:flutter/cupertino.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:http/http.dart' as http;

typedef HashMethod = String Function(String);

abstract class GitClientData {
  String get id;
  String get secret;
}

abstract class DataStorage {
  String operator [](String key);
  operator []=(String key, String value);
}

class _MemoryStorage extends DataStorage {
  final Map<String, String> _map = Map();

  @override
  operator [](String key) => _map[key];

  @override
  void operator []=(String key, String value) => _map[key] = value;

}

String _defaultHashMethod(String key) {
  return hex.encode(md5.convert(utf8.encode(key??"")).bytes);
}

class PlainClientData extends GitClientData {
  String id;
  String secret;

  PlainClientData(this.id, this.secret);
}

Future<String> _request(Uri uri, {
  String accept = "application/vnd.github.v3+json",
  String method = "GET",
  String body,
  GitIssues issues,
}) async {
  http.Request request = http.Request(method, uri);
  request.headers["Accept"] = accept;
  if (issues?.hasAccessToken == true) {
    request.headers["Authorization"] = "token ${issues.storage["access_token"]}";
  }
  if (body != null) {
    request.body = body;
  }
  http.StreamedResponse res = await request.send();

  return await res.stream.bytesToString();
}

class GitIssues {
  final String owner;
  final String repo;
  final Uri redirect;

  final GitClientData client;
  final HashMethod hash;

  DataStorage storage;

  Map<String, List<String>> _cache = new Map();

  GitIssues({
    @required this.owner,
    @required this.repo,
    this.redirect,
    this.client,
    this.storage,
    this.hash = _defaultHashMethod,
  }) : assert(owner != null && repo != null) {
    if (storage == null) storage = _MemoryStorage();
  }

  GitIssue get(String key) {
    return GitIssue._(
      identifier: hash(key),
      issues: this,
    );
  }

  String get loginUrl {
    String url = "https://github.com/login/oauth/authorize?client_id=${client.id}&scope=public_repo";
    return redirect == null ? url : "$url&redirect_uri=${Uri.encodeComponent(redirect.toString())}";
  }

  bool get hasAccessToken => storage["access_token"] != null;

  Future<void> oauth(String code) async {
    String result = await _request(Uri.https(
      "github.com",
      "/login/oauth/access_token",
      {
        "client_id": client.id,
        "client_secret": client.secret,
        "code": code
      }
    ));
    var obj = jsonDecode(result);
    print(obj);
    storage["access_token"] = obj["access_token"];
  }

  Future<UserInfo> fetchUser() async {
    String result = await _request(
        Uri.parse("https://api.github.com/user"),
        method: "GET",
        issues: this
    );
    UserInfo info = UserInfo(jsonDecode(result));
    if (info.login != null) {
      return info;
    }
    return null;
  }
}

class UserInfo {
  int id;
  String login;
  String avatar;

  UserInfo(var data) {
    id = parseNumber(data["id"]);
    login = data["login"];
    avatar = data["avatar_url"];
  }

  String toString() {
    return jsonEncode({
      "id": id,
      "login": login,
      "avatar_url": avatar
    });
  }
}

int parseNumber(var id) {
  if (id is int) return id;
  else if (id is String) return int.tryParse(id) ?? 0;
  else return 0;
}

class Comment {
  int id;
  String body;
  DateTime created;
  DateTime updated;

  UserInfo user;

  Comment(var data) {
    id = parseNumber(data["id"]);
    body = data["body"];
    created = DateTime.tryParse(data["created_at"]);
    updated = DateTime.tryParse(data["updated_at"]);

    user = UserInfo(data["user"]);
  }
}

class _Issue {
  String number;
  int count = -1;
}

class GitIssue {
  final String identifier;
  final GitIssues issues;
  List<_Issue> list;

  GitIssue._({
    this.identifier,
    this.issues
  }) {
    if (issues._cache.containsKey(identifier)) {
      var numbers = issues._cache[identifier];
      _updateStat(numbers);
    }
  }

  void _updateStat(List<String> numbers) {
    list = List.filled(numbers.length, null, growable: true);
    for (int i = 0, t = numbers.length; i < t; ++i) {
      list[i] = _Issue()..number = numbers[i];
    }
  }

  static const String fetchKey = "git_fetch";

  Future<void> _fetchNumbers() async {
    // String value = this.issues.storage["$fetchKey:$identifier"];
    //
    // if (value != null && value.isNotEmpty) {
    //   dynamic data = jsonDecode(value);
    //
    // }

    String url = "https://api.github.com/search/issues?q=repo:${issues.owner}/${issues.repo}%20in:title%20$identifier";

    dynamic json = jsonDecode(await _request(Uri.parse(url), issues: issues));
    var items = json["items"];
    List<String> numbers = [];
    if (items != null) {
      for (var item in items) {
        numbers.add(item["number"].toString());
      }
    }
    _updateStat(numbers);
  }

  Future<Comment> post(String content) async {
    if (list == null || list.length == 0) {
      await _fetchNumbers();
    }
    if (list.length == 0) {
      String url = "https://api.github.com/repos/${issues.owner}/${issues.repo}/issues";
      String result = await _request(
          Uri.parse(url),
          method: "POST",
          issues: issues,
          body: jsonEncode({
            "title": identifier
          })
      );
      var json = jsonDecode(result);
      list.add(_Issue()..number = json["number"].toString());
    }
    var issue = list.last;
    String url = "https://api.github.com/repos/${issues.owner}/${issues.repo}/issues/${issue.number}/comments";
    String result = await _request(
        Uri.parse(url),
        method: "POST",
        issues: issues,
        body: jsonEncode({
          "body": content
        })
    );
    var json = jsonDecode(result);
    return Comment(json);
  }

  Future<List<Comment>> fetch({
    int page,
    DateTime since,
    int size = 100,
  }) async {
    assert(page != null || since != null);
    if (list == null || list.length == 0) {
      await _fetchNumbers();
    }

    List<Comment> ret = [];
    for (int i = 0, t = list.length; i < t; ++i) {
      var issue = list[i];
      StringBuffer strBuf = StringBuffer("https://api.github.com/repos/${issues.owner}/${issues.repo}/issues/${issue.number}/comments?per_page=$size");
      if (since != null) {
        strBuf.write("&since=${Uri.encodeComponent(since.toIso8601String())}");
      }
      if (page != null) {
        strBuf.write("&page=${page + 1}");
      }
      String result = await _request(Uri.parse(strBuf.toString()), issues: issues);
      print("$result");
      var json = jsonDecode(result);

      if (json is List) {
        for (var data in json) {
          ret.add(Comment(data));
        }
        // if (json.length < size) {
        //   issue.count = json.length > 0 ? (page + 1) : page;
        // }
      }
    }
    return ret;
  }

  @override
  bool operator ==(Object other) {
    if (other is GitIssue) {
      return identifier == other.identifier;
    }
    return super == other;
  }

  @override
  int get hashCode => identifier.hashCode + 0xa2289;

}
