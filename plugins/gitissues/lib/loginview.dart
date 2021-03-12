
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'gitissues.dart';

class LoginView extends StatefulWidget {

  final GitIssues gitIssues;
  final void Function() onComplete;

  LoginView(this.gitIssues, {
    this.onComplete
  });

  @override
  State<StatefulWidget> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {

  GitIssues get gitIssues => widget.gitIssues;
  bool showLoading = false;
  WebViewController controller;

  @override
  Widget build(BuildContext context) {
    print("Url : ${gitIssues.loginUrl}");
    return Stack(
      children: [
        WebView(
          initialUrl: gitIssues.loginUrl,
          javascriptMode: JavascriptMode.unrestricted,
          navigationDelegate: (req) async {
            if (gitIssues.redirect != null && !req.url.startsWith(gitIssues.redirect.toString())) {
              return NavigationDecision.navigate;
            }
            Uri uri = Uri.parse(req.url);
            String code = uri.queryParameters["code"];
            if (code != null) {
              try {
                setState(() {
                  showLoading = true;
                });
                await exchangeCode(code);

                widget.onComplete?.call();
              } catch (e) {
                print("Failed on exchange code $e");
              }
              setState(() {
                showLoading = false;
              });
            }
            return NavigationDecision.prevent;
          },
          onWebResourceError: (error) {
          },
          onWebViewCreated: (controller) {
            this.controller = controller;
          },
          onPageStarted: (url) {
          },
          onPageFinished: (url) {
          },
        ),

        Visibility(
          visible: showLoading,
          child: Container(
            color: Color.fromRGBO(0, 0, 0, 0.5),
            child: Center(
              child: SpinKitRing(
                color: Colors.white,
                size: 36.0,
              ),
            ),
          )
        )

      ],
    );
  }

  Future<void> exchangeCode(String code) async {
    await gitIssues.oauth(code);
  }

}
