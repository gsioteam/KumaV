
import 'package:dio/dio.dart';

class Comment {

  Comment.from(Map data);
}

class Comments {
  String appId;
  late Dio dio;

  Comments({
    required this.appId,
    String host = "https://cusdis.com"
  }) {
    dio = Dio(BaseOptions(
      baseUrl: host,
    ));
  }

  Future<List<Comment>> get({
    required String pageId,
    int page = 0,
  }) async {
    var response = await dio.get(
      "api/open/comments",
      queryParameters: {
        "appId": appId,
        "page": page + 1,
        "pageId": pageId
      },
      options: Options(
        responseType: ResponseType.json
      ),
    );

    print(response.data);
    return [];
  }

  Future<Comment> post({
    String? parentId,
    required String pageId,
    required String content,
    required String email,
    required String nickname,
    String? pageUrl,
    String? pageTitle,
  }) async {
    Map<String, dynamic> query = {
      "appId": appId,
      "pageId": pageId,
      "content": content,
      "email": email,
      "nickname": nickname,
    };
    if (parentId != null) query['parentId'] = parentId;
    if (pageUrl != null) query['pageUrl'] = pageUrl;
    if (pageTitle != null) query['pageTitle'] = pageTitle;

    var response = await dio.post(
      "api/open/comments",
      queryParameters: query,
      options: Options(
        responseType: ResponseType.json
      ),
    );

    return Comment.from(response.data['data']);
  }

  void stop() {
    dio.close();
  }
}